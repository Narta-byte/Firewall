library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity SRAM is
  port (
    clk : in std_logic;
    reset : in std_logic;
    WE : in std_logic; -- read/write
    address : in std_logic_vector(5 downto 0);
    occupied_flag_in : in std_logic;
    hash_in : in std_logic_vector(5 downto 0);
    key_in : in std_logic_vector(95 downto 0);
    data_out : out std_logic_vector(102 downto 0) 
  ) ;
end SRAM ;

architecture SRAM_arch of SRAM is
  
  type RW_type is array (0 to 32) of std_logic_vector(102 downto 0); --occupied, hash, key 
  signal RW : RW_type;

begin
  MEMORY : process (clk)
  begin
    if reset = '1' then
      
    elsif rising_edge(clk) then
      if WE = '1' then
        RW(to_integer(unsigned(address))) <= '1' & hash_in & key_in;
      else
      data_out <= RW(to_integer(unsigned(address)));
      end if ;
    end if ;
  end process;


end architecture ; -- SRAM_arch
