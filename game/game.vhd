-- Description: breakout game component
-- FSM-based design 

-- Engineer: Fearghal Morgan, National University of Ireland, Galway
-- Date: 26/10/2022
-- 
-- 16 x 32-bit game array, using reg32x32(15 downto 0)(31:0)

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
--  NS*, CS* 				       next and current state signals 

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
-- Additional states include:
--      * checkBallZone
--      * respawn
type stateType is (idle, writeToCSR0, setupGameParameters, initGameArena, initBall, initPaddle, initLives, initScore, waitState, processPaddle, checkBallZone, assignBallDir, processBall, writeBallToMem, endGame, respawn, updateScore, updateLives, updateWall); -- declare enumerated state type
signal NS, CS                                   : stateType; -- declare FSM state 
								                
signal NSWallVec, CSWallVec                     : std_logic_vector(31 downto 0);
signal NSBallVec, CSBallVec                     : std_logic_vector(31 downto 0);
signal NSPaddleVec, CSPaddleVec                 : std_logic_vector(31 downto 0);
								                
signal NSBallXAdd, CSBallXAdd                   : integer range 0 to 31;
signal NSBallYAdd, CSBallYAdd                   : integer range 0 to 31;
signal NSBallDir, CSBallDir                     : std_logic_vector(2 downto 0);

signal NSScore, CSScore                         : integer range 0 to 31;
signal NSLives, CSLives                         : integer range 0 to 31;

-- Clock frequency = 12.5MHz, count 0 - 12,499,999 to create 1 second delay 
-- 100ms delay => count ~ 0 - 1,250,000
signal NSDlyCountMax, CSDlyCountMax             : integer range 0 to 1250000;
signal NSDlyCount, CSDlyCount                   : integer range 0 to 1250000;

signal NSPaddleNumDlyMax, CSPaddleNumDlyMax     : integer range 0 to 31;
signal NSPaddleNumDlyCount, CSPaddleNumDlyCount : integer range 0 to 31;

signal NSBallNumDlyMax, CSBallNumDlyMax         : integer range 0 to 31;
signal NSBallNumDlyCount, CSBallNumDlyCount     : integer range 0 to 31;

signal zone 									: integer; 
signal CSEndGameCounter, NSEndGameCounter       : integer;

----------------------------------------------------------------------
-- paddle MSB and LSB for ball rebound parameters
signal paddleMSBAdd, paddleLSBAdd                 : integer range 0 to 31;
----------------------------------------------------------------------

begin

asgnFunctBus2_i: functBus <= (others => '0'); -- not currently used 

-- FSM next state and o/p decode process
-- <include new signals in sensitivity list>
NSAndOPDec_i: process (CS, go, 
					   reg4x32_CSRA, reg4x32_CSRB, reg32x32_dOut, 
					   CSWallVec, CSPaddleVec, CSBallXAdd, CSBallYAdd, CSBallDir, CSScore, CSLives, 
					   CSDlyCountMax, CSPaddleNumDlyMax, CSBallNumDlyMax, CSDlyCount, CSPaddleNumDlyCount, CSBallNumDlyCount, CSEndGameCounter)
begin

   -- <<<< This code runs every loop >>>>>> -- 
   NS 	 		       <= CS;     -- default signal assignments
   NSWallVec           <= CSWallVec;
   NSBallVec           <= CSBallVec;
   NSPaddleVec         <= CSPaddleVec;
   NSBallXAdd          <= CSBallXAdd;
   NSBallYAdd          <= CSBallYAdd;
   NSBallDir           <= CSBallDir;
   NSScore             <= CSScore;
   NSLives             <= CSLives;
   NSDlyCount          <= CSDlyCount;           
   NSPaddleNumDlyCount <= CSPaddleNumDlyCount;
   NSBallNumDlyCount   <= CSBallNumDlyCount; 
   NSDlyCountMax       <= CSDlyCountMax;
   NSDlyCount          <= CSDlyCount;
   NSPaddleNumDlyMax   <= CSPaddleNumDlyMax;
   NSBallNumDlyMax     <= CSBallNumDlyMax;
   active    	       <= '1';             -- default asserted. Deasserted only in idle state. 
   wr   	           <= '0';
   add	               <= "010" & "00000"; -- reg32x32 base address
   datToMem            <= (others => '0');
--   zone                <= 6;
   NSEndGameCounter <= CSEndGameCounter;

  case CS is 
		when idle => 			     
			active  <= '0';  
            if go = '1' then 
				if    reg4x32_CSRA(0)(10 downto 8) = "000" then -- initialise game values and progress to init game arena states 
					NS 					<= setupGameParameters;							
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


		when setupGameParameters =>  
			NSWallVec           <= reg4x32_CSRA(3);
			NSBallXAdd 	        <= to_integer( unsigned(reg4x32_CSRA(2)(28 downto 24)) );
			NSBallYAdd 	        <= to_integer( unsigned(reg4x32_CSRA(2)(20 downto 16)) );
			-- NSLives             <= to_integer( unsigned(reg4x32_CSRA(2)( 3 downto  0)) );
			NSLives             <= 3;
			NSScore             <= to_integer( unsigned(reg4x32_CSRA(2)( 7 downto  4)) );
			NSBallVec           <= reg4x32_CSRA(1);

			NSPaddleVec         <= reg4x32_CSRB(3);
			NSBallDir           <= reg4x32_CSRB(2)(26 downto  24);
			NSDlyCountMax       <= to_integer( unsigned(reg4x32_CSRB(2)(19 downto  0)) );                 
			NSPaddleNumDlyMax   <= to_integer( unsigned(reg4x32_CSRB(1)(28 downto 24)) );
			NSBallNumDlyMax     <= to_integer( unsigned(reg4x32_CSRB(1)(20 downto 16)) );
			
			NSEndGameCounter <= 0;  -- Default consignment
			
			NS                  <= initGameArena;

		when initGameArena => -- follow an initialisation sequence
            -- write wallVec
			wr   	      <= '1';
			add           <= "010" & "01111";               -- reg32x32 row 15
			datToMem      <= CSWallVec;
           	NS            <= initBall;
		when initBall => 
			wr   	      <= '1';
			add	          <= "010" & std_logic_vector( to_unsigned(CSBallYAdd,5) );  
			datToMem      <= CSBallVec;
           	NS            <= initPaddle;
		when initPaddle =>
			wr   	      <= '1';
			add	          <= "010" & "00010";               -- reg32x32 row 2 
			datToMem      <= CSPaddleVec;
           	NS            <= initLives;
           	----------------------------------------------------------------------
			-- set paddle MSB and LSB Addresses to center
			paddleMSBAdd   <= 17;
			paddleLSBAdd   <= 13;
			----------------------------------------------------------------------
		when initLives =>                          
			wr   	      <= '1';
			add	          <= "010" & "00001";               -- reg32x32 row 1
			datToMem      <= X"000000" & "000" & std_logic_vector( to_unsigned(CSLives, 5) );  
           	NS            <= initScore;     
		when initScore =>                          
			wr   	      <= '1';
			add	          <= "010" & "00000";               -- reg32x32 row 0 
			datToMem      <= X"000000" & "000" & std_logic_vector( to_unsigned(CSScore, 5) );  
           	NS            <= writeToCSR0;                   -- finish. Return done state and return control to host


		when waitState =>                                   -- increment count and loop in state until value reaches delay value       
			if CSDlyCount = CSDlyCountMax then
	     	    NSDlyCount <= 0;                            -- clear delay counter and process paddle and/or ball	     	         	    
   	   	        NS  <= processPaddle;
            else
	   	        NSDlyCount    <= CSDlyCount + 1;                
			end if;
			
	     	    			
        -- read reg4x32_CSRA(0)(9:8) and move paddle left / right, between boundaries
		when processPaddle =>                               -- read CSRB(0)(9:8)
			if CSPaddleNumDlyCount = CSPaddleNumDlyMax then
	     	   NSPaddleNumDlyCount <= 0;                    -- clear counter
		       add	<= "010" & "00010";                     -- reg32x32 row 2 (paddle row) 
			     if reg4x32_CSRB(0)(9) = '1' then           -- shift paddle left, if not at bit 31 boundary
			        if reg32x32_dOut(31) = '0' then 
				        wr   	      <= '1';
					    add	          <= "010" & "00010";   -- reg32x32 row 2, paddle row address 
					    datToMem      <= reg32x32_dOut(30 downto 0) & '0'; 
					    paddleMSBAdd   <= paddleMSBAdd + 1;
					    paddleLSBAdd   <= paddleLSBAdd + 1;
				    end if;
			      elsif reg4x32_CSRB(0)(8) = '1' then       -- shift paddle right 
			        if reg32x32_dOut(0) = '0' then 
					    wr   	      <= '1';
					    add	          <= "010" & "00010";   -- reg32x32 row 2, paddle row address 
					    datToMem      <= '0' & reg32x32_dOut(31 downto 1); 
					    paddleMSBAdd   <= paddleMSBAdd - 1;
					    paddleLSBAdd   <= paddleLSBAdd - 1;
				    end if;
				  end if;   		  
           	else
	           NSPaddleNumDlyCount <= CSPaddleNumDlyCount + 1; -- increment counter
           	   NS  <= checkBallZone;
           	end if;		

        when checkBallZone => 
            if CSBallNumDlyCount = CSBallNumDlyMax then
				NSBallNumDlyCount   <= 0;
            
                            -- checking CS ball location to assign zones
                if CSBallYAdd = 3 then 
                    zone <= 5;
                elsif (CSBallXAdd = 31 or CSBallXAdd = 0) and (CSBallYAdd > 3 and CSBallYAdd < 14) then
                    zone <= 4;
                elsif (CSBallXAdd > 1 and CSBallXAdd < 30) and (CSBallYAdd = 14) then
                    zone <= 0;
                elsif CSBallXAdd > 29 and CSBallYAdd > 13 then
                    zone <= 2;
                elsif CSBallXAdd < 2 and CSBallYAdd > 13 then
                    zone <= 3;
                elsif (CSBallXAdd > 1 and CSBallXAdd < 30) and (CSBallYAdd = 15) then
                    zone <= 1;
                else
                    zone <= 6;
                end if;
                NS <= assignBallDir;   
            else -- CSBallNumDlyCount != CSBallNumDlyMax 
			   NSBallNumDlyCount <= CSBallNumDlyCount + 1; -- increment counter
			   NS  <= waitState;
			end if;	
		-- ========= Only partially completed =========
        when updateWall =>
            -- write wallVec
			wr   	      <= '1';
			add           <= "010" & "01111";               -- reg32x32 row 15
			datToMem      <= CSWallVec;
           	NS            <= processBall;
        
        
        when assignBallDir => 
             -- zone actions
             NS <= processBall;   -- apply new direction vectors to ball
            case zone is				   
                when 0 =>      -- below wall
                   if CSBallDir(2) = '1' then
                       if CSWallVec(to_integer(to_unsigned(CSBallXAdd, 5))) = '1' then
                           NSScore <= CSScore + 1;
                           NSBallDir(2) <= '0';
                           NSWallVec(to_integer(to_unsigned(CSBallXAdd, 5))) <= '0';
                       
                       elsif CSBallDir(1 downto 0) = "10" then
                           if CSWallVec(to_integer(to_unsigned(CSBallXAdd + 1, 5))) = '1' then 
                               NSScore <= CSScore + 1;
                               NSBallDir <= not(CSBallDir);
                               NSWallVec(to_integer(to_unsigned(CSBallXAdd + 1, 5))) <= '0';
                           end if;
                       elsif CSBallDir(1 downto 0) = "01" then
                           if CSWallVec(to_integer(to_unsigned(CSBallXAdd - 1, 5))) = '1' then 
                               NSScore <= CSScore + 1;
                               NSBallDir <= not(CSBallDir);
                               NSWallVec(to_integer(to_unsigned(CSBallXAdd - 1, 5))) <= '0';
                           end if;
                       end if;
                   end if;
                   
                when 1 =>      -- wall
                   NSBallDir(2) <= '0';
                   
                when 2 =>      -- top left corner
                   if CSBallDir(2) = '1' then
                        if CSBallXAdd = 30 then
                            if CSBallYAdd = 14 then
                                if CSWallVec(30) = '1' or CSWallVec(31) = '1' then
                                    NSWallVec(31 downto 30) <= "00";
                                    NSBallDir <= "001";                                
                                end if;
                            elsif CSBallYAdd = 15 then
                                NSBallDir(2) <= '0';
                            end if;
                        elsif CSBallXAdd = 31 then 
                            if CSBallYAdd = 14 then
                                if CSWallVec(31) = '1' then
                                    NSWallVec(31) <= '0';
                                 end if;  
                            end if;              
                            if CSBallDir = "100" then
                                NSBallDir(2) <= not(CSBallDir(2));
                            else 
                                NSBallDir <= not(CSBallDir);
                            end if;
                        end if;
                   end if;
                   
                   
                when 3 =>      -- top right corner
                    if CSBallDir(2) = '1' then
                        if CSBallXAdd = 1 then
                            if CSBallYAdd = 14 then
                                if CSWallVec(1) = '1' or CSWallVec(0) = '1' then
                                    NSWallVec(1 downto 0) <= "00";
                                    NSBallDir <= "010";                                
                                end if;
                            elsif CSBallYAdd = 15 then
                                NSBallDir(2) <= '0';
                            end if;
                        elsif CSBallXAdd = 0 then 
                            if CSBallYAdd = 14 then
                                if CSWallVec(0) = '1' then
                                    NSWallVec(0) <= '0';
                                 end if;  
                            end if;              
                            if CSBallDir = "100" then
                                NSBallDir(2) <= not(CSBallDir(2));
                            else 
                                NSBallDir <= not(CSBallDir);
                            end if;
                        end if;
                    end if;
                    
              
                when 4 =>      -- arena boundary
                    NSBallDir(1 downto 0) <= not(CSBallDir(1 downto 0));
                    
                when 5 =>      -- above paddle
                    if CSBallXAdd = paddleMSBAdd then 
                        if CSBallDir = "001" then
                            NSBallDir <= "100";
                        else 
                            NSBallDir <= "110";
                        end if;
                    elsif CSBallXAdd = paddleLSBAdd then 
                        if CSBallDir = "010" then 
                            NSBallDir <= "100";
                        else 
                            NSBallDir <= "101";
                        end if;
                    elsif CSBallXAdd > paddleLSBAdd and CSBallXAdd < paddleMSBAdd then
                        NSBallDir(2) <= '1';
                    else
                        NS <= respawn;
                    end if;  
                
                when 6 =>
                     NSBallDir <= CSBallDir; 
                when others =>
                    null;
            end case;
            
        when processBall => 	
               case CSBallDir(1 downto 0) is 
                   when "10" => NSBallXAdd <= CSBallXAdd + 1;
                   when "01" => NSBallXAdd <= CSBallXAdd - 1;
                   when others => null;
               end case;
                -- applying ball directions to addresses
				if CSBallDir(2) = '1' then 
                   NSBallYAdd <= CSBallYAdd + 1;
               elsif CSBallDir(2) = '0' then
                   NSBallYAdd <= CSBallYAdd - 1;
               end if;
               wr                  <= '1'; 					        			             -- clear current ball row
               add(7 downto 5)     <= "010";                                                 -- reg32x32 memory bank select 
               add(4 downto 0)     <= std_logic_vector( to_unsigned(CSBallYAdd, 5) );        -- current row address 
               datToMem            <= (others => '0');							             -- clear row
               NS                  <= writeBallToMem;

		when writeBallToMem =>                                                           -- write new ball row
             wr                       <= '1'; 					        			      
             add(7 downto 5)          <= "010";                                          -- reg32x32 memory bank select 
             add(4 downto 0)          <= std_logic_vector( to_unsigned(CSBallYAdd, 5) ); -- row address
	   		 datToMem                 <= (others => '0');							     -- clear vector  
   	         datToMem( to_integer(to_unsigned(CSBallXAdd, 5)) ) <= '1';                  -- ball bit asserted
			 NS <= waitState;
		

		when endGame =>                          
			-- <perform pattern write to arena to indicate game over>
			wr <= '1';
			add(4 downto 0) <= std_logic_vector( to_unsigned(CSEndGameCounter,5) );
			add(7 downto 5) <= "010";
			case CSEndGameCounter is
			 when 15 => datToMem <= x"00000000";
			 when 14 => datToMem <= x"1C451C00";
			 when 13 => datToMem <= x"20AAA000";
			 when 12 => datToMem <= x"20AAA000";
			 when 11 => datToMem <= x"2EEAB800";
			 when 10 => datToMem <= x"22AAA000";
			 when 9 => datToMem <= x"1CAA9C00";
			 when 8 => datToMem <= x"00000000";
			 when 7 => datToMem <= x"00000000";
			 when 6 => datToMem <= x"1C89DC00";
			 when 5 => datToMem <= x"228A1200";
			 when 4 => datToMem <= x"228A1200";
			 when 3 => datToMem <= x"228B9C00";
			 when 2 => datToMem <= x"22521200";
			 when 1 => datToMem <= x"1C21D200";
			 when 0 => wr <= '0';
			 when others => null;
			end case;
			if CSEndGameCounter > 15 then
		      NS <= writeToCSR0;
			else
			  NS <= endGame;
			end if;
			NSEndGameCounter <= CSEndGameCounter + 1;
            
		when respawn =>
		  if CSLives > 1 then
            wr                  <= '1'; 					        			            -- clear current ball row
            add(7 downto 5)     <= "010";                                                   -- reg32x32 memory bank select 
            add(4 downto 0)     <= std_logic_vector( to_unsigned(CSBallYAdd, 5) );          -- current row address 
            datToMem            <= (others => '0');							                -- clear row
            -- ================================================================
            -- NSWallVec           <= reg4x32_CSRA(3);
			NSBallXAdd 	        <= to_integer( unsigned(reg4x32_CSRA(2)(28 downto 24)) );
			NSBallYAdd 	        <= to_integer( unsigned(reg4x32_CSRA(2)(20 downto 16)) );
			NSLives             <= CSLives - 1;
			NSBallVec           <= reg4x32_CSRA(1);
			NSPaddleVec         <= reg4x32_CSRB(3);
			NSBallDir           <= reg4x32_CSRB(2)(26 downto  24);
--            NS                  <= writeBallToMem;
            NS                  <= updateScore;
		  else
		      NS <= endGame;
		  end if;
		when updateScore => 
            -- Write changes to mem. move to updateLives
			wr   	      <= '1';
			add	          <= "010" & "00000";               -- reg32x32 row 0 
			datToMem      <= X"000000" & "000" & std_logic_vector( to_unsigned(CSScore, 5) );  
		    NS                  <= updateLives;
		
		when updateLives =>
		    -- Move to writeBallToMem
			wr   	      <= '1';
			add	          <= "010" & "00001";               -- reg32x32 row 1
			datToMem      <= X"000000" & "000" & std_logic_vector( to_unsigned(CSLives, 5) );      
		    NS                  <= writeBallToMem;
		

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
    CSDlyCountMax       <= 0;
    CSDlyCount          <= 0;
    CSPaddleNumDlyMax   <= 0;
	CSBallNumDlyMax     <= 0;
	CSEndGameCounter <= 0;
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
        CSDlyCountMax       <= NSDlyCountMax;
        CSDlyCount          <= NSDlyCount;
		CSPaddleNumDlyMax   <= NSPaddleNumDlyMax;
		CSBallNumDlyMax     <= NSBallNumDlyMax;
		CSEndGameCounter <= NSEndGameCounter;
     end if;
  end if;
end process; 

end RTL;