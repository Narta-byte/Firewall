library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_unsigned.ALL;

entity Cuckoo_Hashing is
  port (
    clk : in std_logic;
    reset : in std_logic;

    set_rule : in std_logic;
    cmd_in : in std_logic_vector(1 downto 0);
    key_in : in std_logic_vector(95 downto 0);

    header_in : in std_logic_vector(95 downto 0);
    
    address : out std_logic(15 downto 0);
    RW : out std_logic;
    hash_out : out std_logic(7 downto 0);
    acc_deny_in : in std_logic;

    acc_deny_out : out std_logic
  ) ;
end Cuckoo_Hashing ;

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is
   
    type State_type is (rule_searching, hash_matching );
    signal current_state, next_state : State_type;

    component SRAM is
        port (
            clk : in std_logic;
            reset : in std_logic;
            WE : in std_logic; -- read/write
            address : in std_logic_vector(7 downto 0);
            data_in : in std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0) 
        );
    end component;

    type SRAM_type is array (0 to 10) of std_logic;
    signal hashtable_1 : SRAM_type;
    signal hashtable_2 : SRAM_type;
begin

    --SRAM_inner : SRAM port map (clk,reset,RW,hash_out,acc_deny_in);


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
                
                    when rule_searching => if set_rule ='0' then
                        next_state <= hash_matching;
                    end if ;
                        
                    when hash_matching => if set_rule = '1' then
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
                    case( cmd_in ) is
                   
                       when "00" => --flush
                            FLUSH : for i in 0 to 10 loop
                                hashtable_1(i) <= '0';
                                hashtable_2(i) <= '0';
                            end loop ; -- FLUSH
                       when "01" => --insert
                                if hashtable_1(key_in mod 11) /= '1' then
                                    hashtable_1((key_in mod 11)) <= '1';

                                elsif hashtable_2((key_in/11 mod 11)) /= '1' then
                                    
                                    --mabye it should assign something to hashtable_1 here
                                    hashtable_2((key_in/11 mod 11)) <= '1';
                                else
                                    report "LOOP DETECTED" severity ERROR;
                                end if;
                               

                       when "10" => -- delete
                                --hashtable_1((key_in mod 11)) <= '0';           
                       when others => Report "CMD CANNOT BE 11" severity NOTE;
                   
                   end case ;
            

                    when hash_matching =>

                    when others => report "ERROR IN OUTPUT LOGIC" severity failure;
                
                end case ;
            end if ;
    end process;


    

end architecture ; -- Cuckoo_Hashing