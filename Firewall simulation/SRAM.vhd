library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity SRAM is
  port (
    clk : in std_logic;
    reset : in std_logic;
    WE : in std_logic; -- read/write
    address : in std_logic_vector(7 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0) 
  ) ;
end SRAM ;

architecture SRAM_arch of SRAM is
  
  type RW_type is array (0 to 10) of std_logic_vector(7 downto 0);
  signal RW : RW_type;

begin
  MEMORY : process (clk)
  begin
    if rising_edge(clk) then
      if WE = '1' then
        RW(to_integer(unsigned(address))) <= data_in;
      else
      data_out <= RW(to_integer(unsigned(address)));
      end if ;
    end if ;
  end process;


end architecture ; -- SRAM_arch
