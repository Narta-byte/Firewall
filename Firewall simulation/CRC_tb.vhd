library ieee;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use ieee.math_real.all;

entity CRC_tb is
end entity;

architecture behavior of CRC_tb is

    signal CRC_out1 : std_logic_vector(8 downto 0);
    signal CRC_out2 : std_logic_vector(8 downto 0);
    signal g1       : std_logic_vector(8 downto 0) := "100101111";
    signal g2	    : std_logic_vector(8 downto 0) := "101001001";
    signal clk : std_logic;
    function calc_hash (M : std_logic_vector; g : std_logic_vector)
        return std_logic_vector is

            variable crc : std_logic_vector(7 downto 0) := (others => '0');

            type R_array is array (0 to 7) of std_logic;
            variable R : R_array := (others=>'0');

            variable connect : std_logic;


        begin  
            
                REST : for i in 0 to 7 loop 
                    connect := M(i) xor R(7);
                    for j in 7 downto 1 loop
                        if g(j) = '1' then
                            R(j):= connect xor R(j-1);
                        else
                            R(j):= R(j-1);
                        end if; 
                    end loop; 
                    R(0) := connect;
                end loop;
            
            crc := R(7) & R(6) & R(5) & R(4) & R(3) & R(2) & R(1) & R(0);  

        return std_logic_vector(crc);

    end function calc_hash; 
                 
 
begin
    CLOCK : process 
	 begin
    clk <= '1';
    wait for 10 ns;
    clk <= '0';
    wait for 10 ns;
    end process;
    CHECK : process (clk)
        
    begin
	if rising_edge(clk) then
        CRC_out1 <= '0' & calc_hash(x"0AD1ECAA0D21981DE9E201BB",g1);
        CRC_out2 <= calc_hash(M => x"0AD1ECAA23BAE019F3DD01BB", g => g2) + "100000000";
        end if;

    end process;
 

end architecture;