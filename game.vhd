-- Description: breakout game component
-- FSM-based design 

-- Engineer: Fearghal Morgan, National University of Ireland, Galway
-- Date: 26/10/2022
-- 
-- 15 x 32-bit game array, using reg32x32(15 downto 0)(31:0)

-- On completion 
--    write reg4x32_CSRA(0)(1:0)  = 0b10, i.e, (1) = 1 => FPGA done, (0) = 0 => return control to host. Other CSRA(0) bits unchanged
--
-- Signal dictionary
--  clk					system clock strobe, rising edge active
--  rst	        		assertion (h) asynchronously clears all registers
--  ce                  chip enable, asserted high                 		 
--  go			        Assertion (H) detected in idle state to active threshold function 
--  active (Output)     Default asserted (h), except in idle state

--  reg4x32_CSRA    	4 x 32-bit Control & Status registers, CSRA
--  reg4x32_CSRB      	32-bit Control register, CSRB
--  BRAM_dOut	        Current source memory 256-bit data (not used in this application)

--  wr  (Output)        Asserted to synchronously write to addressed memory
--  add (Output)  	    Addressed memory - 0b00100000 to read BRAM(255:0)
--  datToMem (Output)   32-bit data to addressed memory 

--  functBus            96-bit array of function signals, for use in debug and demonstration of function behaviour 
--  			        Not used in this example

-- Internal Signal dictionary
--  NS, CS                         finite state machine state signals 
--  NSBallXAdd, CSBallXAdd         next and current ball X address   
--  NSBallYAdd, CSBallYAdd         next and current ball Y address   
--  To be completed  

--    Using integer types for INTERNAL address signals where possible, to make VHDL model more readable

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.arrayPackage.all;

entity game is
    Port ( clk 		     : in STD_LOGIC;   
           rst 		     : in STD_LOGIC; 
           ce            : in  std_logic;                		 
           go            : in  std_logic;                		 
		   active        : out std_logic;

		   reg4x32_CSRA  : in array4x32; 
		   reg4x32_CSRB  : in array4x32;	
           BRAM_dOut     : in std_logic_vector(255 downto 0);	
           reg32x32_dOut : in std_logic_vector(31 downto 0);
					 
		   wr            : out std_logic;
		   add           : out std_logic_vector(  7 downto 0);					 
		   datToMem	     : out std_logic_vector( 31 downto 0);

		   functBus      : out std_logic_vector(95 downto 0)
           );
end game;

architecture RTL of game is
-- Internal signal declarations
-- <include new states>
type stateType is (idle, writeToCSR0, initGameArena, initBall, initPaddle, initLives, initScore, waitState, processPaddle, processBall, writeBallToMem, endGame); -- declare enumerated state type
signal NS, CS                                   : stateType; -- declare FSM state 

-- Wall								                
signal NSWallVec, CSWallVec                     : std_logic_vector(31 downto 0);

-- Paddle
signal NSPaddleVec, CSPaddleVec                 : std_logic_vector(31 downto 0);
					
-- Ball		
signal NSBallVec, CSBallVec                     : std_logic_vector(31 downto 0);			
signal NSBallXAdd, CSBallXAdd                   : integer range 0 to 31;
signal NSBallYAdd, CSBallYAdd                   : integer range 0 to 31;
signal NSBallDir, CSBallDir                     : std_logic_vector(2 downto 0);

-- Score & Lives						                
signal NSScore, CSScore                         : integer range 0 to 31;
signal NSLives, CSLives                         : integer range 0 to 31;

-- Clock frequency = 12.5MHz, count 0 - 12,499,999 to create 1 second delay 
-- 100ms delay => count ~ 0 - 1,250,000
signal dlyCountMax                              : integer range 0 to 1250000 := 2;
signal NSDlyCount, CSDlyCount                   : integer range 0 to 1250000;
								                
signal paddleNumDlyMax                          : integer range 0 to 31 := 2;
signal NSPaddleNumDlyCount, CSPaddleNumDlyCount : integer range 0 to 31;

signal ballNumDlyMax                            : integer range 0 to 31 := 2;
signal NSBallNumDlyCount, CSBallNumDlyCount     : integer range 0 to 31;

signal zone 									: integer; 

begin

asgnFunctBus2_i: functBus <= (others => '0'); -- not currently used 

-- FSM next state and o/p decode process
-- <include new signals in sensitivity list>
NSAndOPDec_i: process (CS, go, 
					   reg4x32_CSRA, reg4x32_CSRB, reg32x32_dOut, 
					   CSWallVec, CSPaddleVec, CSBallVec, CSBallXAdd, CSBallYAdd, CSBallDir, CSScore, CSLives, 
					   CSDlyCount, CSPaddleNumDlyCount, CSBallNumDlyCount)
begin
   NS 	 		       <= CS;     -- default signal assignments
   NSWallVec           <= CSWallVec;
   NSBallVec           <= CSBallVec;
   NSPaddleVec         <= CSPaddleVec;
   NSBallXAdd          <= CSBallXAdd;
   NSBallYAdd          <= CSBallYAdd;
   NSBallDir           <= CSBallDir;
   NSScore             <= CSScore;
   NSLives             <= CSLives;
   NSPaddleNumDlyCount <= CSPaddleNumDlyCount;
   NSBallNumDlyCount   <= CSBallNumDlyCount;
   active    	       <= '1';             -- default asserted. Deasserted only in idle state. 
   wr   	           <= '0';
   add	               <= "010" & "00000"; -- reg32x32 base address
   datToMem            <= (others => '0');
   zone                <= 0;

  case CS is 
		when idle => 			     
			active  <= '0';  
            if go = '1' then 
				if    reg4x32_CSRA(0)(10 downto 8) = "000" then -- initialise game values and progress to init game arena states 
					NSWallVec           <= reg4x32_CSRA(3);
					NSBallVec           <= reg4x32_CSRA(1);
					NSPaddleVec         <= reg4x32_CSRB(3);
					                    
					NSBallXAdd 	        <= to_integer( unsigned(reg4x32_CSRA(2)(28 downto 24)) );
					NSBallYAdd 	        <= to_integer( unsigned(reg4x32_CSRA(2)(20 downto 16)) );
					NSBallDir           <= reg4x32_CSRA(2)(10 downto  8);
					NSScore             <= to_integer( unsigned(reg4x32_CSRA(2)( 7 downto  4)) );
					NSLives             <= to_integer( unsigned(reg4x32_CSRA(2)( 3 downto  0)) );
					                    
					NSDlyCount          <= to_integer( unsigned(reg4x32_CSRB(2)(19 downto  0)) );
					paddleNumDlyMax     <= to_integer( unsigned(reg4x32_CSRB(1)(28 downto 24)) );
					ballNumDlyMax       <= to_integer( unsigned(reg4x32_CSRB(1)(20 downto 16)) );
					NS                  <= initGameArena;
							
				elsif reg4x32_CSRA(0)(10 downto 8) = "001" then -- play game
					NSDlyCount          <= 0;                   -- clear delay counters  
					NSPaddleNumDlyCount <= 0;  
					NSBallNumDlyCount   <= 0;
					NS                  <= waitState;
					
				end if;
			end if;

		when writeToCSR0 =>                                        -- finish. Return done state and return control to host
			wr       <= '1';
            add      <= "000" & "00000"; 						   -- reg4x32_CSRA address = 0 
		    datToMem <=   reg4x32_CSRA(0)(31 downto  8)            -- bits unchanged 
                        & reg4x32_CSRA(0)( 7 downto  2) & "10";    -- byte 0, bit(1) = 1 => FPGA done, bit(0) = 0 => return control to host. Bits 7:2 unchanged
			NS       <= idle;


		when initGameArena => -- follow an initialisation sequence
            -- write wallVec
			wr   	      <= '1';
			add           <= "010" & "01111";    -- reg32x32 row 15
			datToMem      <= CSWallVec;
           	NS            <= initBall;
		when initBall => 
			wr   	      <= '1';
			add	          <= "010" & std_logic_vector( to_unsigned(CSBallYAdd,5) );  
			datToMem      <= CSBallVec;
           	NS            <= initPaddle;
		when initPaddle =>
			wr   	      <= '1';
			add	          <= "010" & "00010";        -- reg32x32 row 2 
			datToMem      <= CSPaddleVec;
           	NS            <= initLives;
		when initLives =>                          
			wr   	      <= '1';
			add	          <= "010" & "00001";        -- reg32x32 row 1
			datToMem      <= X"000000" & "000" & std_logic_vector( to_unsigned(CSLives, 5) );  -- ??? why are CSLives 5 bits but NSLives is defined in 'idle' state as 4 bits?
           	NS            <= initScore;     
		when initScore =>                          
			wr   	      <= '1';
			add	          <= "010" & "00000";        -- reg32x32 row 0 
			datToMem      <= X"000000" & "000" & std_logic_vector( to_unsigned(CSScore, 5) );  
           	NS            <= writeToCSR0;            -- finish. Return done state and return control to host


		when waitState =>                                       -- increment count and loop in state until value reaches delay value       
			if CSPaddleNumDlyCount = paddleNumDlyMax then
				NSPaddleNumDlyCount <= 0;                       -- clear counter
		   	    NS  <= processPaddle;
			elsif CSBallNumDlyCount = ballNumDlyMax then
				NSBallNumDlyCount <= 0;                         -- clear counter
		   	    NS  <= processBall;
			end if;
		    NSDlyCount    <= CSDlyCount + 1;                
			if CSDlyCount = dlyCountMax then
	     	    NSDlyCount <= 0;                                -- clear paddle delay counter 
				NSPaddleNumDlyCount <= CSPaddleNumDlyCount + 1; -- increment counters
				NSBallNumDlyCount   <= CSBallNumDlyCount + 1;
			end if;
			
			
        -- read reg4x32_CSRA(0)(9:8) and move paddle left / right, between boundaries
		when processPaddle =>                        -- read CSRB(0)(9:8)
	     	NSPaddleNumDlyCount <= 0;                -- clear counter
			add	<= "010" & "00010";                  -- reg32x32 row 2 (paddle row) 
			if reg4x32_CSRB(0)(9) = '1' then         -- shift paddle left, if not at bit 31 boundary
			    if reg32x32_dOut(31) = '0' then 
					wr   	      <= '1';
					add	          <= "010" & "00010";-- reg32x32 row 2, paddle row address 
					datToMem      <= reg32x32_dOut(30 downto 0) & '0'; 
				end if;
			elsif reg4x32_CSRB(0)(9) = '0' then         -- shift paddle right, if not at bit 0 boundary
			    if reg32x32_dOut(0) = '0' then 
					wr   	      <= '1';
					add	          <= "010" & "00010";-- reg32x32 row 2, paddle row address 
					datToMem      <= '0' & reg32x32_dOut(31 downto 1); 
				end if;
			end if;		
           	NS  <= waitState;





        when processBall => -- <to be completed> <significant element in game vhdl model>
-- <TODO>: 
--			* Implement NE, NW, SE, SW ball movement
--			* Change ball direction based on paddle point-of-contact
--			* Ball bounce from arena boundaries


			-- Ball direction = N
			if CSBallDir = '001' then
				-- ball is in row 14 (below wall)
				if CSBallYAdd = 14 then	
					-- ball will contact wall
					if CSWallVec(to_integer(to_unsigned(NSBallXAdd, 5))) = '1' then
						NSScore <= CSScore + 1;										-- increment score
						NSWallVec(to_integer(to_unsigned(NSBallXAdd, 5))) <= '0';	-- update wall
						NSBallDir <= '000';											-- change ball direction
					-- ball will not contact wall
					else 
						NSBallYAdd <= CSBallYAdd + 1;	-- move up to wall row
						NSBallDir <= '000';				-- change ball direction
					end if;
				-- no wall immediately above ball -> normal up movement
				else
					NSBallYAdd <= CSBallYAdd + 1;	-- move up 1 row on clk edge
				end if;
			-- Ball direction = S
			elsif CSBallDir = '000' then
				-- ball is in row 3 (above paddle)
				if CSBallYAdd = 3 then
					-- paddle in-line with ball
					if CSPaddleVec(to_integer(to_unsigned(NSBallXAdd, 5))) = '1' then
						NSBallDir <= '001';				-- change ball direction
					-- paddle not in-line with ball
					else 
						NSBallYAdd <= CSBallYAdd - 1;	-- move ball 1 row down 
					end if;
						-- check no. of lives
						if CSLives = 0 then 
							NS <= endGame;		-- move to endGame state
						else
							NSLives <= CSLives - 1;			-- decrement lives
							-- respawn ball
							NSBallDir <= '001';
							NSBallXAdd <= 16;
							NSBallYAdd <= 3;	
						end if;
				-- no paddle immediately below ball -> normal down movement
				else
					NSBallYAdd <= CSBallYAdd - 1;		-- move ball 1 row down 
				end if;
			end if;
			NSBallNumDlyCount   <= 0;		-- clear counter
           	NS  <= writeBallToMem;			-- write ball changes to memory

			
		when writeBallToMem =>                                                           -- write to ball memory using CSBallXAdd and CSBallYAdd (the updated row address, since NS registers as CS 
             add(7 downto 5)          <= "010";                                          -- mem32x32 memory bank select 
             add(4 downto 0)          <= std_logic_vector( to_unsigned(CSBallYAdd, 5) ); -- update row address (registered)
	   		 datToMem                 <= (others => '0');							     -- clear vector  
   	         datToMem( to_integer(to_unsigned(CSBallXAdd, 5)) ) <= '1';                  -- ball bit asserted
			 NS <= waitState;

		when endGame =>                          
			-- perform patter write to arena to indicate game over
           	NS            <= writeToCSR0;            -- finish. Return done state and return control to host
 
		when others => 
			null;
	end case;
end process; 


-- Synchronous process registering current FSM state value, and other registered signals
-- registers include chip enable control
stateReg_i: process (clk, rst)
begin
  if rst = '1' then 		
    CS 	                <= idle;		
	CSWallVec           <= (others => '0');
	CSBallVec           <= (others => '0');
	CSPaddleVec         <= (others => '0');
    CSBallXAdd          <= 0;
    CSBallYAdd          <= 0;
    CSBallDir           <= (others => '0');
    CSScore             <= 0;
    CSLives             <= 0;
    CSDlyCount          <= 0;
    CSPaddleNumDlyCount <= 0;
    CSBallNumDlyCount   <= 0;
  elsif clk'event and clk = '1' then 
    if ce = '1' then
		CS 	                <= NS;		
		CSWallVec           <= NSWallVec;      
		CSBallVec           <= NSBallVec;      
		CSPaddleVec         <= NSPaddleVec;    
		CSBallXAdd          <= NSBallXAdd;     
		CSBallYAdd          <= NSBallYAdd;     
		CSBallDir           <= NSBallDir;      
		CSScore             <= NSScore;        
		CSLives             <= NSLives;        
		CSDlyCount          <= NSDlyCount;           
		CSPaddleNumDlyCount <= NSPaddleNumDlyCount;
		CSBallNumDlyCount   <= NSBallNumDlyCount; 
     end if;
  end if;
end process; 


end RTL;


