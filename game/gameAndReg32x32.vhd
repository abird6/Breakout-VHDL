-- Description: gameAndReg32x32
-- Engineer: Fearghal Morgan
-- National University of Ireland, Galway / vicilogic 
-- Date: 8/10/2022

-- includes reg32x32 game arena memory, along with game model
-- reg32x32 generates reg32x32_dOut and maitains the 16x32-bit breakout game array

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.arrayPackage.all;

entity gameAndReg32x32 is
    Port ( clk 		     : in STD_LOGIC;   
           rst 		     : in STD_LOGIC; 
           ce            : in  std_logic;                		 
           go            : in  std_logic;                		 
		   active        : out std_logic;

		   reg4x32_CSRA  : in array4x32; 
		   reg4x32_CSRB  : in array4x32;	
					 
		   wr            : out std_logic;
		   add           : out std_logic_vector(  7 downto 0);					 
		   datToMem	     : out std_logic_vector( 31 downto 0);

		   functBus      : out std_logic_vector(95 downto 0)
           );
end gameAndReg32x32;

architecture struct of gameAndReg32x32 is
signal reg32x32_dOut : std_logic_vector( 31 downto 0);
signal reg32x32      : array32x32;

signal intWr       : std_logic;
signal intAdd      : std_logic_vector(  7 downto 0);					 
signal intDatToMem : std_logic_vector( 31 downto 0);

begin

wr       <= intWr;    -- internal reg32x32 write interface signals
add      <= intAdd; 					 
datToMem <= intDatToMem; 

game_i: game
port map ( clk 		      => clk, 		 
           rst 		      => rst,
           ce             => ce, 		 
           go             => go,
		   active         => active,

		   reg4x32_CSRA   => reg4x32_CSRA,       
		   reg4x32_CSRB   => reg4x32_CSRB,       
           BRAM_dOut      => (others => '0'), 
           reg32x32_dOut  => reg32x32_dOut, 
						 
		   wr             => intWr,
		   add            => intAdd,    
		   datToMem	      => intDatToMem,
		   
		   functBus       => functBus	 
           );

reg32x32_i: process (clk, rst)
begin
    if rst = '1' then
        reg32x32 <= ( others => X"00000000" );
    elsif rising_edge (clk) then 
        if intWr = '1' then 
            if unsigned(intAdd(7 downto 5)) = "010" then   
                reg32x32(  to_integer(unsigned(intAdd(4 downto 0)))  ) <= intDatToMem;
            end if;
        end if;
    end if;
end process;
asgn_reg32x32_dOut_i: reg32x32_dOut <= reg32x32(  to_integer(unsigned(intAdd(4 downto 0)))  );


end struct;