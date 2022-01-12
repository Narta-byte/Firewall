library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;



entity Cuckoo_Hashing is
  port (
    clk : in std_logic;
    reset : in std_logic;

    set_rule : in std_logic;
    cmd_in : in std_logic_vector(1 downto 0);
    key_in : in std_logic_vector(95 downto 0);

    header_in : in std_logic_vector(95 downto 0);
    val_hdr : in std_logic;
    rdy_hdr : out std_logic;

    val_in : in std_logic;
    rdy_out : out std_logic;

    acc_deny_out : out std_logic;
    val_ad : out std_logic;
    rdy_ad : in std_logic
  ) ;
end Cuckoo_Hashing ;

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is

    type State_type is (command_state, hash_matching, lookup_hash1,lookup_hash2,insert_key,remember_and_replace
,ERROR,is_occupied,rdy_key,flush_memory,rdy_for_match,search_hash1,search_hash2,matching,AD_communication);
    signal current_state, next_state : State_type;
    
    signal exits_cuckoo,insert_flag,hashfun,flip,flush_flag : std_logic := '0';
    signal MAX : integer:= 0;
    
    --hash matching signals
    signal exits_matching,previous_search : std_logic := '0';   
    signal matching_key : std_logic_vector(95 downto 0);

        component SRAM
        port (
            clk : in std_logic;
        reset : in std_logic;
        flush_sram : in std_logic;
        RW : in std_logic;
        address : in std_logic_vector(5 downto 0);
        data_in : in std_logic_vector(95 downto 0);
        data_out : out std_logic_vector(96 downto 0)
      );
      end component;
      
      signal occupied_flag_out :  std_logic;
      signal flush_sram : std_logic := '0';
      signal RW : std_logic:='0';
      signal address :  std_logic_vector(5 downto 0);
      signal data_in :  std_logic_vector(95 downto 0);
      signal data_out :  std_logic_vector(96 downto 0);
      
      signal insertion_key : std_logic_vector(95 downto 0);
      
      --debug
      signal DEBUG_OK_CNT, DEBUG_KO_CNT : integer:=0;
      
      begin

        SRAM_inst : SRAM
        port map (
      clk => clk,
      reset => reset,
      flush_sram => flush_sram,
      RW => RW,
      address => address,
      data_in => data_in,
      data_out => data_out
    );
  

    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= command_state;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if ;
    end process;

    NEXT_STATE_LOGIC : process (current_state, insert_flag, set_rule, val_in, exits_cuckoo, max, flip,flush_flag, 
                                previous_search, exits_matching, val_hdr)
    begin
        next_state <= current_state;
                case(current_state) is

                    when command_state => 
                        if flush_flag = '1' then
                            next_state <= flush_memory;
                        elsif insert_flag ='1' then
                            next_state <= rdy_key;
                        elsif set_rule = '0' then
                            next_state <= hash_matching;
                        end if ;

                    when rdy_key =>     
                        if insert_flag ='0' then
                            next_state <= command_state;
                        elsif val_in ='1' then
                            next_state <= lookup_hash1;
                        end if ;

                    when flush_memory => next_state <=command_state;
                        
                    when hash_matching => 
                        if set_rule = '1' then
                            next_state <= command_state;
                        elsif val_hdr = '1' then
                            next_state <= search_hash1;
                        end if ;

                    when lookup_hash1 => next_state <= is_occupied;

                    when is_occupied => if exits_cuckoo = '1' then
                        next_state <= remember_and_replace;
                    else
                        next_state <= insert_key;
                    end if;

                    when lookup_hash2 => next_state <= is_occupied;
                    when remember_and_replace => if max = 15 then
                        next_state <= ERROR;
                    elsif flip = '1' then
                        next_state <= lookup_hash1;
                    else
                        next_state <= lookup_hash2;
                    end if;
                    
                    when insert_key => next_state <= rdy_key;
                    
                    when ERROR => next_state <= ERROR;

                    when search_hash1 => next_state <= matching;
                    
                    when search_hash2 => next_state <= matching;

                    when matching => 
                        if previous_search = '0' and exits_matching = '0'  then
                            next_state <= search_hash2;
                        else
                            next_state <= AD_communication;
                        end if ;

                    when AD_communication => 
                        if rdy_ad = '1' then
                            next_state <= hash_matching;
                        end if ;


                    when others => next_state <= hash_matching;

                end case ;

    end process;

    OUTPUT_LOGIC : process (current_state, cmd_in) --har fjernet reset
    begin
                case(current_state) is
                    when command_state =>
                        --reset all nextstate signals
                        flush_sram <= '0';
                        insert_flag <= '0';

                    case( cmd_in ) is
                       when "00" => --flush
                           flush_flag <= '1';
                       when "01" => --insert
                           insert_flag <= '1';
                       when "10" => -- delete
                           --TODO
                       when "11" =>  --hash match
                            insert_flag <= '0';
                            flush_flag <= '0';
                       when others => --stay in command_state

                   end case ;
                   when flush_memory => flush_sram <= '1'; flush_flag <= '0';
                   
                   when insert_key =>
                        if hashfun = '0' then
                            RW <= '1';
                            data_in <= insertion_key;
                            flip <= '1';
                        elsif hashfun = '1' then
                            RW <= '1';
                            data_in <= insertion_key;
                            flip <= '1'; 
                            
                            end if;
                    when rdy_key => 
                            if not (cmd_in = "01")  then
                                insert_flag <= '0';
                            end if ;
                        rdy_out <= '1'; 
                        insertion_key<=key_in;
                        max <= 0;
                            
                    when lookup_hash1 =>
                        rdy_out <= '0';
                        hashfun <= '0';
                        RW <= '0';
                        address <= std_logic_vector(to_unsigned(to_integer(unsigned(insertion_key)) mod 11,96)(5 downto 0));
                            
                    when lookup_hash2 =>
                        hashfun <= '1';
                        RW <= '0';
                        address <= std_logic_vector(to_unsigned((to_integer(unsigned(insertion_key))/11 mod 11)+15,96)(5 downto 0)); 

                    when is_occupied =>
                        if data_out(96) = '1' then
                            exits_cuckoo <= '1';
                        else
                            exits_cuckoo <= '0';
                        end if;
                        
                    when remember_and_replace =>
                        RW <= '1';
                        data_in <= insertion_key;
                        insertion_key <= data_out(95 downto 0);
                        max <= max + 1;
                        if flip = '1' then
                            flip <= '0';
                        else
                            flip <= '1';
                        end if;

                    when ERROR =>
                            
                    when hash_matching =>
                        rdy_hdr <= '1';
                        matching_key <= header_in;
                        previous_search <= '0';
                        val_ad <= '0';
                    when search_hash1 => 
                        rdy_hdr <= '0';
                        RW <= '0';
                        address <= std_logic_vector(to_unsigned(to_integer(unsigned(matching_key)) mod 11,96)(5 downto 0));

                    when search_hash2 => 
                        RW <= '0';
                        address <= std_logic_vector(to_unsigned((to_integer(unsigned(matching_key))/11 mod 11)+15,96)(5 downto 0)); 
                        previous_search <= '1';

                    when matching => 
                    if data_out(95 downto 0) = matching_key then
                        exits_matching <= '1';
                        acc_deny_out <= '1';
                        DEBUG_KO_CNT <= DEBUG_KO_CNT +1; 
                    else
                        if previous_search = '1' then
                            DEBUG_OK_CNT <= DEBUG_OK_CNT+1;
                            acc_deny_out <= '0';
                        end if ;
                        exits_matching <= '0';
                    end if;
                            
                    when AD_communication => 
                        val_ad <= '1';                     
                    
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure;
                    
                    end case ;
                    
                    end process;


end architecture ; -- Cuckoo_Hashing


