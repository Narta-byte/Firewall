library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Cuckoo_Hashing_tb is
end Cuckoo_Hashing_tb ;

architecture Cuckoo_Hashing_arch of Cuckoo_Hashing_tb is
    signal clk_tb, reset_tb : std_logic := '0';
    signal rule_flag : std_logic := '0';
    

    component Cuckoo_Hashing is
        port (
        );
    end component;

begin



end architecture ; -- Cuckoo_Hashing_arch
