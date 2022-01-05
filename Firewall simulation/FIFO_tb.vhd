library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity FIFO_tb is
end entity;

architecture behavioral_tb of FIFO_tb is
    
   -- signal data_in, data_out        : std_logic_vector(7 downto 0) := (others => '0');
   -- signal clk, reset, wren, rden   : std_logic := '0';
   -- signal i                        : integer := 0;
   -- constant clk_period             : time := 10 ns;
   -- constant depth                  : integer := 16;  

   signal clk_tb, reset_tb : std_logic := '0';
   
   component FIFO is
       port (
       );
   end component;

begin

 
    

end architecture;