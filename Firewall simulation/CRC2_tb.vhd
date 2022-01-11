library ieee;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
use ieee.math_real.all;

entity CRC2_tb is
end entity;

architecture behavioral of CRC2_tb is

    signal CRC_out1 : std_logic_vector(7 downto 0);
    signal CRC_out2 : std_logic_vector(7 downto 0);

    function calc_hash1 (M : std_logic_vector)
        return std_logic_vector is

            variable crc : std_logic_vector(7 downto 0) := (others => '0');
	    
            type g_array is array (0 to 8) of std_logic;
            variable g : g_array := "111101001";

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

    end function calc_hash1; 



    function calc_hash2 (M : std_logic_vector)
        return std_logic_vector is

        variable crc : std_logic_vector(7 downto 0) := (others => '0');
    
        type g_array is array (0 to 8) of std_logic;
        variable g : g_array := "100100101";

        type R_array is array (0 to 7, 0 to 1) of std_logic;
        variable R : R_array := (others =>(others=>'0'));


    begin               
            REST : for i in 0 to 7 loop 
                R(0,1) := M(i) xor R(7,0);

                if g(1) = '1' then
                    R(1,1) := R(0,0) xor R(0,1);
                else
                    R(1,1) := R(0,0); 
                end if; 
                
                if g(2) = '1' then 
                    R(2,1) := R(1,0) xor R(0,1);
                else
                    R(2,1) := R(1,0); 
                end if; 

                if g(3) = '1' then 
                    R(3,1) := R(2,0) xor R(0,1);
                else
                    R(3,1) := R(2,0);
                end if;

                if g(4) = '1' then 
                    R(4,1) := R(3,0) xor R(0,1);
                else
                    R(4,1) := R(3,0);
                end if;

                if g(5) = '1' then 
                    R(5,1) := R(4,0) xor R(0,1);
                else
                    R(5,1) := R(4,0);
                end if;

                if g(6) = '1' then 
                    R(6,1) := R(5,0) xor R(0,1);
                else
                    R(6,1) := R(5,0);
                end if;

                if g(7) = '1' then 
                    R(7,1) := R(6,0) xor R(0,1);
                else
                    R(7,1) := R(6,0);
                end if;

                R(0,0) := R(0,1);
                R(1,0) := R(1,1);
                R(2,0) := R(2,1);
                R(3,0) := R(3,1);
                R(4,0) := R(4,1);
                R(5,0) := R(5,1);
                R(6,0) := R(6,1);
                R(7,0) := R(7,1);
              
            end loop;     
             
        
        crc := R(7,0) & R(6,0) & R(5,0) & R(4,0) & R(3,0) & R(2,0) & R(1,0) & R(0,0); 

    return std_logic_vector(crc);

end function calc_hash2; 
           
begin

    CHECK : process
        
    begin

        CRC_out1 <= calc_hash1(M => "11101101");
        CRC_out2 <= calc_hash2(M => "11101101");
        wait;

    end process;
 

end architecture;