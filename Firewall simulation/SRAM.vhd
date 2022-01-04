library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity SRAM is
  port (
    clk : in std_logic;
    reset : in std_logic;
    RW : in std_logic;
    address : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(9 downto 0);
    data_out : out std_logic_vector(9 downto 0) 
  ) ;
end SRAM ;

architecture SRAM_arch of SRAM is
  
  

begin



end architecture ; -- SRAM_arch
