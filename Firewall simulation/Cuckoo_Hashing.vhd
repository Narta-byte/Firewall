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
    
    address : out std_logic(5 downto 0);
    RW : out std_logic;
    hash_out : out std_logic(7 downto 0);
    key_out : out std_logic_vector(8 downto 0);
    occupied_flag_out : out std_logic;
    SRAM_data : in std_logic_vector(13 downto 0);

    acc_deny_out : out std_logic
  ) ;
end Cuckoo_Hashing ;

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is
   
    type State_type is (rule_searching, hash_matching, lookup_hash1,lookup_hash2,insert_key,remember_and_replace
,ERROR,is_occupied);
    signal current_state, next_state : State_type;

    signal exits,insert_flag,hashfun,flip : std_logic := '0';
    signal MAX : integer:= 0;

    component SRAM is
        port (
            clk : in std_logic;
            reset : in std_logic;
            WE : in std_logic; -- read/write
            address : in std_logic_vector(5 downto 0);
            occupied_flag_in : in std_logic;
            hash_in : in std_logic_vector(5 downto 0);
            key_in : in std_logic_vector(95 downto 0);
            data_out : out std_logic_vector(20 downto 0) 
        );
    end component;
   
begin

    SRAM_in : SRAM port map (clk,reset,RW,hash_out,key_out,SRAM_data);


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
                
                    when rule_searching => if insert_flag ='1' then
                        next_state <= lookup_hash1;
                    elsif set_rule = '0' then
                        next_state <= hash_matching;
                    end if ;
                        
                    when hash_matching => if set_rule = '1' then
                        next_state <= rule_searching;
                    end if ;

                    when lookup_hash1 => next_state <= is_occupied;

                    when is_occupied => if exits = '1' then
                        next_state <= remember_and_replace;
                    else
                        next_state <= insert_key;
                    end if;
                    
                    when lookup_hash2 => next_state <= is_occupied;
                    when remember_and_replace => if max = 16 then
                        next_state <= ERROR;
                    elsif flip = '1' then
                        next_state <= lookup_hash1;
                    else
                        next_state <= lookup_hash2;
                    end if;
                    when insert_key => next_state <= rule_searching;
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
                           --TODO
                       when "01" => --insert 
                            insert_flag <= '1';
                       when "10" => -- delete
                           --TODO
                       when others => Report "CMD CANNOT BE 11" severity NOTE;
                   
                   end case ;
                       when hash_matching =>
            
                    when insert_key =>
                        if hashfun = '0' then
                            address <= key_in mod 11;
                            RW <= '1';
                            occupied_flag_out <= '1';
                            hash_out <= key_in mod 11;
                            key_out  <= key_in;
                        else
                            address <= key_in/11 mod 11+15; -- an abritary number
                            RW <= '1';
                            occupied_flag_out <= '1';
                            hash_out <= key_in/11 mod 11;
                            key_out  <= key_in;

                        end if;
                       
                    when lookup_hash1 =>
                        hashfun <= '0';
                        RW <= '0';
                        address <= key_in mod 11;
                        

                    when lookup_hash2 =>
                        hashfun <= '1';
                        RW <= '0';
                        address <= key_in/11 mod 11;
                        
                    when is_occupied =>
                        if SRAM_data(13) = '1' then
                            exits <= '1';
                        else
                            exits <= '0';
                        end if;
                        
                    when remember_and_replace =>
                        RW <= '1';
                        address <= key_in mod 11;

                    when ERROR =>

                    when others => report "ERROR IN OUTPUT LOGIC" severity failure;
                
                end case ;
            end if ;
    end process;


    

end architecture ; -- Cuckoo_Hashing


