library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity test is
    port (
        clk   : in std_logic;
        reset : in std_logic
        
    );
end entity test;
                
architecture rtl of test is
    signal clk_test : std_logic;
    
begin
 process 
 begin
 clk_test <= '1';
 wait for 10 ns;
 clk_test <= '0';
 wait for 10 ns;    
 end process;
    
                
end architecture;        






