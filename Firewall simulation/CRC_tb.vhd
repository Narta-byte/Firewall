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

    
    function calc_hash1 (M : std_logic_vector)
        return std_logic_vector is

            variable crc : std_logic_vector(7 downto 0) := (others => '0');

            signal g : std_logic_vector(8 downto 0) := "111101001";

            type R_array is array (0 to 7) of std_logic;
            variable R : R_array;
            
            variable x : integer := 0; 

        begin
            Initialize_R : for i in 0 to 7 loop
                R(i) := '0';
            end loop; --Create Array 

            while x < 1 loop
                R(0) := R(7) xor M(x);
                for i in 0 to 7 loop
                    if g(i) <= '1' then
                        R(i+1) := '0' xor R(0); 
                    else
                        R(i+1) := '0';
                    end if;
                end loop; 
                x := x + 1;    
            end loop; 
                
            REST : for i in 1 to 102 loop 
                report "Heyhey hey";
            end loop;        


        return std_logic_vector(crc);

    end function calc; 


           
begin

    process (all)
    begin
        
    end process;
 

end architecture;