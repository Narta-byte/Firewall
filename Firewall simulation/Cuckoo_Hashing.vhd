library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_unsigned.ALL;

entity Cuckoo_Hashing is
  port (
    clk : in std_logic;
    reset : in std_logic;
    rule_flag : in std_logic;
    header_in : in std_logic_vector(95 downto 0);
    hash_out : out std_logic_vector(95 downto 0)
  ) ;
end Cuckoo_Hashing ;grfasdydgidfsigluiafsgugfguaguugeirudsgugufghdyfasdgdygrdgfudfsfugudshiæyluikjwqhiydufjaklrkpiaufdygkjwrhetgiuf8syd7rhkt4jl5yhtub8f7dtfygithyjipth7g89tfyig4h56uyr7g86ftiu4h6i5puy98rg7f67iuoiup59y8rg779tu4o6iu59y8e7g6tutiup

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is

    type hash_table0 is array (0 to 10) of std_logic_vector(95 downto 0);
    type hash_table1 is array (0 to 10) of std_logic_vector(95 downto 0);
    
    
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
                
                    when rule_searching => if rule_flag = '0' then
                        next_state <= hash_matching;
                    end if ;
                        
                    when hash_matching => if rule_flag = '1' then
                        next_state <= rule_searching;
                    end if ;

                    when others => next_state <= hash_matching;
                
                end case ;
            end if ;
    end process;

    OUTPUT_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            
            elsif rising_edge(clk) then
                case(current_state) is
                
                    when rule_searching => 
                    --hash_table0(1) <=  x"000000000000000000000000" ;

                    when hash_matching =>

                    when others => report "ERROR IN OUTPUT LOGIC" severity failure;
                
                end case ;
            end if ;
    end process;


    

end architecture ; -- Cuckoo_Hashing