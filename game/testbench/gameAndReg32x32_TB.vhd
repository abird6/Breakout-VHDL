-- Description: gameAndReg32x32_TB testbench 
-- Engineer: Fearghal Morgan
-- Edited by: Anthony Bird, Luke Canny
-- University of Galway / viciLogic 
-- Date: 21/11/2022

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.arrayPackage.all;

entity gameAndReg32x32_TB is end gameAndReg32x32_TB; -- testbench has no inputs or outputs

architecture Behavioral of gameAndReg32x32_TB is
-- component declaration is in package

-- Declare internal testbench signals, typically the same as the component entity signals
-- initialise signal clk to logic '1' since the default std_logic type signal state is 'U' 
-- and process clkStim uses clk <= not clk  
signal clk            : STD_LOGIC := '1'; 
signal rst            : STD_LOGIC;
signal ce             : std_logic;
signal go             : STD_LOGIC;
signal active         : std_logic;

signal reg4x32_CSRA   : array4x32;
signal reg4x32_CSRB   : array4x32;
signal wr             : std_logic;
signal add            : std_logic_vector(  7 downto 0);		   
signal datToMem	      : STD_LOGIC_VECTOR( 31 downto 0);

signal functBus       : std_logic_vector(95 downto 0);

constant period       : time := 20 ns;    -- 50MHz clk
signal   endOfSim     : boolean := false; -- Default FALSE. Assigned TRUE at end of process stim
signal   testNo       : integer;          -- facilitates test numbers. Aids locating each simulation waveform test 
signal   subTestNo    : integer;          -- facilitates sub-test numbers, this is to aid understanding in waveform as each test requires asserting reset, set up and go.

begin

uut: gameAndReg32x32
port map ( clk 		      => clk, 		 
           rst 		      => rst,
           ce             => ce, 		 
           go             => go,
		   active         => active,

		   reg4x32_CSRA   => reg4x32_CSRA,       
		   reg4x32_CSRB   => reg4x32_CSRB,       
						 
		   wr             => wr,
		   add            => add,    
		   datToMem	      => datToMem,
		   
		   functBus       => functBus	 
           );

-- clk stimulus continuing until all simulation stimulus have been applied (endOfSim TRUE)
clkStim : process (clk)
begin
  if endOfSim = false then
     clk <= not clk after period/2;
  end if;
end process;




stim: process -- no process sensitivity list to enable automatic process execution in the simulator
begin 
  report "%N : Simulation Start."; -- generate messages as the simulation executes 
  
  testNo <= 0;
  -- =================================== Test 0 Description ============================= --
  -- Test Number:				0
  -- Number of Sub Tests:		3
  -- Description:				This test will ensure that the ball bounces off the paddle
  --							to the left as designed. (If ball hits paddle on the left
  -- 							hand side, it will bounce into the NW direction)
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation
  -- Subtest 2:					Paddle shifted to right by 1 pixel
  -- 							Ball bounces on LHS of paddle
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1.2 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --          
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00111"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "000"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


  -- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array         
  reg4x32_CSRB(0)(9 downto 8) <= "10"; -- assert left control bit        
  wait for 25*period;  
  reg4x32_CSRB(0)(9 downto 8) <= "00"; -- assert right control bit        
  wait for 300*period;
  -- =================================== End of Game =================================== --




  testNo <= 1;
  -- =================================== Test 1 Description ============================= --
  -- Test Number:				1
  -- Number of Sub Tests:		3
  -- Description:				This test will ensure that the ball bounces off the paddle
  --							to the right as designed. (If ball hits paddle on the right
  -- 							hand side, it will bounce into the NE direction)
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation
  -- Subtest 2:					Paddle shifted to left by 1 pixel
  -- 							Ball bounces on RHS of paddle
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --          
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00111"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "000"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array         
  reg4x32_CSRB(0)(9 downto 8) <= "01"; -- assert left control bit        
  wait for 25*period;  
  reg4x32_CSRB(0)(9 downto 8) <= "00"; -- assert right control bit        
  wait for 300*period;
  -- =================================== End of Game =================================== --



  testNo <= 2;
  -- =================================== Test 2 Description ============================= --
  -- Test Number:				2
  -- Number of Sub Tests:		3
  -- Description:				This test will ensure that the ball bounces off the paddle
  --							and reflect in a purely north direction if the ball hits the
  -- 							centre of the paddle.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation
  -- Subtest 2:					Paddle is not shifted, wait for ball bounce
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --            
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00111"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "000"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --


  testNo <= 3;
    -- =================================== Test 3 Description ============================= --
  -- Test Number:				3
  -- Number of Sub Tests:		3
  -- Description:				In this test, the paddle is moved to the left completely.
  --							The objective of this test is to:
  --								<> Show that the paddle will stop shifting left once in 
  --										contact with the wall
  --								<> Show that ball respawns when it misses the paddle
  --								<> Show that Game Over screen will appear once all lives are used
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation
  -- Subtest 2:					Move left control is asserted for duration of test
  --							Paddle moves to the left and never contacts the ball.
  --							Ball will repeatedly bounce off the wall and miss paddle
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --            
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00100"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00001"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  
  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "000"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


  -- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "10";       
  wait for 600*period;
  -- =================================== End of Game =================================== --


  testNo <= 4;
  -- =================================== Test 4 Description ============================= --
  -- Test Number:				4
  -- Number of Sub Tests:		3
  -- Description:				Test 4, 5, 6, 7, 8 and 9 all relate to Zone 3 of the Arena.
  --							(Please see zone map in the report)
  --
  --							Test 4 will test Zone 3 in the NW of the arena.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Game is initalised such that ball will be moving into 
  --									the NW Zone 3 block immediately.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will bounce in NW section of Zone 3.
  -- =================================== End of Description ============================= --

  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --        
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "11100"; -- "000" & ballXAdd(4:0)      -- X address = 28
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "01011"; -- "000" & ballYAdd(4:0)      -- Y address = 11
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "110"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --

 testNo <= 5;
  -- =================================== Test 5 Description ============================= --
  -- Test Number:				5
  -- Number of Sub Tests:		3
  -- Description:				Test 4, 5, 6, 7, 8 and 9 all relate to Zone 3 of the Arena.
  --							(Please see zone map in the report)
  --
  --							Test 5 will test Zone 3 in the NE of the arena.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Game is initalised such that ball will be moving into 
  --									the NE Zone 3 block immediately.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will bounce in NE section of Zone 3.
  -- =================================== End of Description ============================= --

  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --
           
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "00011"; -- "000" & ballXAdd(4:0)      -- X address = 3
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "01011"; -- "000" & ballYAdd(4:0)      -- Y address = 11
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "101"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --



 testNo <= 6;
  -- =================================== Test 6 Description ============================= --
  -- Test Number:				6
  -- Number of Sub Tests:		3
  -- Description:				Test 4, 5, 6, 7, 8 and 9 all relate to Zone 3 of the Arena.
  --							(Please see zone map in the report)
  --
  --							Test 6 will test Zone 3 in the SW of the arena.
  --							The paddle will be present.
  --							Ball should deflect in a NE direction.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Game is initalised such that ball will be moving into 
  --									the SW Zone 3 block immediately and the paddle will be moved.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will bounce in SW section of Zone 3 (deflecting off the paddle).
  -- =================================== End of Description ============================= --

  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --
          
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "11100"; -- "000" & ballXAdd(4:0)      -- X address = 28
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00110"; -- "000" & ballYAdd(4:0)      -- Y address = 6
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  
  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"f8000000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "010"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --




 testNo <= 7;
  -- =================================== Test 7 Description ============================= --
  -- Test Number:				7
  -- Number of Sub Tests:		3
  -- Description:				Test 4, 5, 6, 7, 8 and 9 all relate to Zone 3 of the Arena.
  --							(Please see zone map in the report)
  --
  --							Test 7 will test Zone 3 in the SW of the arena.
  --							The paddle will NOT be present.
  --							Ball should respawn and a live should be lost.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Game is initalised such that ball will be moving into 
  --									the SW Zone 3 block immediately.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will respawn, a live will be lost.
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --

  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "11100"; -- "000" & ballXAdd(4:0)      -- X address = 28
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00110"; -- "000" & ballYAdd(4:0)      -- Y address = 6
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "010"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --




 testNo <= 8;
  -- =================================== Test 8 Description ============================= --
  -- Test Number:				8
  -- Number of Sub Tests:		3
  -- Description:				Test 4, 5, 6, 7, 8 and 9 all relate to Zone 3 of the Arena.
  --							(Please see zone map in the report)
  --
  --							Test 8 will test Zone 3 in the SE of the arena.
  --							The paddle will be present.
  --							Ball should deflect in a NW direction.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Game is initalised such that ball will be moving into 
  --									the SW Zone 3 block immediately, paddle will be located
  --									in the right-most position.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will deflect into the NW direction, no respawn or lives lost.
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --
         
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "00011"; -- "000" & ballXAdd(4:0)      -- X address = 3
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00110"; -- "000" & ballYAdd(4:0)      -- Y address = 6
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0000001f";     -- paddleVec  
  
  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "001"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --

 testNo <= 9;
  -- =================================== Test 9 Description ============================= --
  -- Test Number:				9
  -- Number of Sub Tests:		3
  -- Description:				Test 4, 5, 6, 7, 8 and 9 all relate to Zone 3 of the Arena.
  --							(Please see zone map in the report)
  --
  --							Test 9 will test Zone 3 in the SE of the arena.
  --							The paddle will NOT be present.
  --							Ball should respawn and a live should be lost.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Game is initalised such that ball will be moving into 
  --									the SE Zone 3 block immediately.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will respawn, a live will be lost.
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --
           
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"ffffffff";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "00011"; -- "000" & ballXAdd(4:0)      -- X address = 3
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00110"; -- "000" & ballYAdd(4:0)      -- Y address = 6
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "00000"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  
  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  
  
  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "001"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --

  testNo <= 10;
  -- =================================== Test 10 Description ============================ --
  -- Test Number:				10
  -- Number of Sub Tests:		3
  -- Description:				Test 10 will show behaviour when the maximum score of 32 is reached.
  --							Game should end, and the player presented with a winner screen.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Wall is depleted except for one remaining wall piece.
  --								<> Score is set to 31.
  -- 								<> Ball's inital trajectory is set to contact final wall piece.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will contact wall and winner procedure is followed.
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 				  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"00010000";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00111"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "11110"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  
  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "100"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --

  testNo <= 11;
  -- =================================== Test 11 Description ============================ --
  -- Test Number:				11
  -- Number of Sub Tests:		3
  -- Description:				Test 11 will show how the game becomes more challenging once
  -- 							the player has reached 10 points.
  --								<> The ball will double in velocity.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Wall has 9 pieces removed.
  --								<> Score is set to 9.
  -- 								<> Ball's inital trajectory is set to contact a wall piece.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will contact wall, ball speed will double, difference in 
  -- 							velocity should be observable.
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"07ffffe1";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00111"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "01001"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 
  
  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "100"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00100"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --

  testNo <= 12;
  -- =================================== Test 12 Description ============================ --
  -- Test Number:				12
  -- Number of Sub Tests:		3
  -- Description:				Test 11 will show how the game becomes more challenging once
  -- 							the player has reached 20 points.
  --								<> The ball will double in velocity.
  --
  -- Subtest 0:					Asserts Reset Signal
  -- Subtest 1:					Game initialisation is modified from the default configuration
  -- 								<> Wall has 19 pieces removed.
  --								<> Score is set to 19.
  -- 								<> Ball's inital trajectory is set to contact a wall piece.
  -- Subtest 2:					Game is started. No input required.
  --							Ball will contact wall, ball speed will double, difference in 
  -- 							velocity should be observable.
  -- =================================== End of Description ============================= --
  
  -- =================================== Reset Assert =================================== --
  subTestNo <= 0; 					  -- include a unique test number to help browsing of the simulation waveform     
							      -- apply rst signal pattern, to deassert 0.2*period after the active clk edge
  go            		<= '0';   -- default assignments
  ce            		<= '1';
  reg4x32_CSRA          <= ( others => (others => '0') );        
  reg4x32_CSRB          <= ( others => (others => '0') );        
  rst    				<= '1';
  wait for 1 * period;
  rst    				<= '0';
  wait for 3*period;

  -- =================================== Game(or Test) Set Up =================================== --            
  subTestNo 				<= 1; 
  reg4x32_CSRA                 <= ( others => (others => '0') ); -- clear all CSRA array         
  
  reg4x32_CSRA(3)              <= X"000fff01";     -- wallVec 
  
  reg4x32_CSRA(2)(31 downto 24)<= "000" & "10000"; -- "000" & ballXAdd(4:0)      
  reg4x32_CSRA(2)(23 downto 16)<= "000" & "00111"; -- "000" & ballYAdd(4:0)      
  reg4x32_CSRA(2)(15 downto  8)<= "000" & "00011"; -- "000" & lives(4:0)      
  reg4x32_CSRA(2)( 7 downto  0)<= "000" & "10011"; -- "000" & score(4:0)      
  
  reg4x32_CSRA(1)              <= X"00010000";     -- ballVec 
  
  reg4x32_CSRA(0)(15 downto 8) <= "00010" & "000"; -- Initialise game. At top DPSProc level, (0) would also be asserted 

  reg4x32_CSRB                 <= ( others => (others => '0') ); -- clear all CSRA array         

  reg4x32_CSRB(3)              <= X"0007c000";     -- paddleVec  

  reg4x32_CSRB(2)(31 downto 24)<= "00000" & "100"; -- ball direction (2:0)   
  reg4x32_CSRB(2)(19 downto  0)<= X"00002";        -- dlyCount(19:0) 

  reg4x32_CSRB(1)(31 downto 24)<= "000" & "00010"; -- "000" & paddleNumDlyMax(4:0)      
  reg4x32_CSRB(1)(23 downto 16)<= "000" & "00010"; -- "000" & ballNumDlyMax(4:0)      
  
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 20*period;  


-- =================================== Play Game =================================== --
  subTestNo 				<= 2;      
  reg4x32_CSRA(0)       <= X"00001101"; -- DSPProc command (15:8) = 0b00010 001, (0) = 1. Play game 
  go     				<= '1'; 
  wait for period;  
  go     				<= '0';   
  wait for 5*period;  
  reg4x32_CSRB       <= ( others => (others => '0') ); -- clear all CSRB array          
  reg4x32_CSRB(0)(9 downto 8) <= "00";       
  wait for 300*period;
-- =================================== End of Game =================================== --




  wait for 2000*period;  
  
  endOfSim 				<= true;  -- assert flag. Stops clk signal generation in process clkStim
  report "simulation done";   
  wait;                           -- include to prevent the stim process from repeating execution, since it does not include a sensitivity list
  
end process;

end Behavioral;