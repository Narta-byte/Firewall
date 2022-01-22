library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity SRAM is
  port (
    clk : in std_logic;
    reset : in std_logic;
    flush_sram : in std_logic;
    occupied : in std_logic;
    RW : in std_logic;
    address : in std_logic_vector(8 downto 0);
    data_in : in std_logic_vector(95 downto 0);
    data_out : out std_logic_vector(96 downto 0)
  );
end SRAM;

architecture SRAM_arch of SRAM is

  type WE_type is array (0 to 511) of std_logic_vector(96 downto 0); --occupied and key  
  signal WE : WE_type := (others => (others => '0'));

begin
 
  MEMORY : process (clk, reset, flush_sram)

  begin
    if reset = '1' or flush_sram = '1' then
      WE <= (others => (others => '0')); --flush
    elsif rising_edge(clk) then
      if RW = '1' then
        WE(to_integer(unsigned(address))) <= occupied & data_in;
      else
        data_out <= WE(to_integer(unsigned(address)));
      end if;
    end if;
  end process;
  
end architecture; -- SRAM_arch