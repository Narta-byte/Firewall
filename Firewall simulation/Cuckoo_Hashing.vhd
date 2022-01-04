library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity Cuckoo_Hashing is
  port (
    clk : in std_logic;
    reset : in std_logic;
    header_in : in std_logic_vector(95 downto 0);
    hash_out : out std_logic_vector(95 downto 0)  
  ) ;
end Cuckoo_Hashing ;

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is

    type State_type is (rule_searching, hash_matching );
    signal current_state, next_state : State_type;

begin

    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= hash_matching;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if ;
    end process;
    
    NEXT_STATE_LOGIC : process (current_state)
    begin
        next_state <= current_state;
        
            if rising_edge(clk) then
                case(current_state) is
                
                    when rule_searching =>
                        
                    when hash_matching =>

                    when others =>
                
                end case ;
            end if ;
    end process;

    OUTPUT_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
        
            elsif rising_edge(clk) then
                case(current_state) is
                
                    when rule_searching =>
                        
                    when hash_matching =>

                    when others =>
                
                end case ;
            end if ;
    end process;


    

end architecture ; -- Cuckoo_Hashing