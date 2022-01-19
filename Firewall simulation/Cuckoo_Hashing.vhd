

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

    header_data : in std_logic_vector(95 downto 0);
    vld_hdr : in std_logic;
    rdy_hash : out std_logic;

    vld_firewall_hash : in std_logic;
    rdy_firewall_hash : out std_logic;

    acc_deny_hash : out std_logic:= '0';
    vld_ad_hash : out std_logic;
    rdy_ad_hash : in std_logic
  ) ;
end Cuckoo_Hashing ;

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is

    type State_type is (
    command_state, 
    flush_memory,

    rdy_hash_matching, 
    lookup_hash1,
    lookup_hash2,
    insert_key,
    remember_and_replace,
    ERROR,is_occupied,
    rdy_key,

    rdy_for_match,
    search_hash1,
    search_hash2,
    matching,
    AD_communication,
    
    rdy_delete,
    find_hashfun1,
    find_hashfun2,
    match_for_delete,
    delete_from_memory
    );

    signal current_state, next_state : State_type;
    
    signal exits_cuckoo,insert_flag,hashfun,flip,flush_flag,eq_key,delete_flag,delete_the_key : std_logic := '0';
    signal MAX : integer:= 0;
    
    --CONSTANTS
    constant MAX_ITER : integer:= 31;

    --hash matching signals
    signal exits_matching,previous_search : std_logic := '0';   
    signal deletion_key, insertion_key, matching_key : std_logic_vector(95 downto 0):= (others => '0');

        component SRAM
        port (
        clk : in std_logic;
        reset : in std_logic;
        flush_sram : in std_logic;
        occupied : in std_logic;
        RW : in std_logic;
        address : in std_logic_vector(8 downto 0);
        data_in : in std_logic_vector(95 downto 0);
        data_out : out std_logic_vector(96 downto 0)
      );
      end component;
      
      signal occupied_flag_out :  std_logic :='1';
      signal flush_sram : std_logic := '0';
      signal occupied : std_logic := '0';
      signal RW : std_logic:='0';
      signal address :  std_logic_vector(8 downto 0):=(others => '0');
      signal data_in :  std_logic_vector(95 downto 0):=(others => '0');
      signal data_out :  std_logic_vector(96 downto 0):=(others => '0');
      
      
      --debug
      signal DEBUG_OK_CNT, DEBUG_KO_CNT : integer:=0;
    
      --crc fun
      signal g1 : std_logic_vector(8 downto 0) := "100101111";
      signal g2 : std_logic_vector(8 downto 0) := "101001001";

    function src_hash (M : std_logic_vector; g : std_logic_vector)
        return std_logic_vector is
            variable crc : std_logic_vector(7 downto 0) := (others => '0');
            type R_array is array (0 to 7) of std_logic;
            variable R : R_array := (others=>'0');
            variable connect : std_logic;

        begin              
                REST : for i in 0 to 95 loop 
                    if (i > 95)  then
                        connect := R(7);
                    else
                        connect := M(i) xor R(7);
                    end if ;
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

    end function src_hash; 

      begin

    SRAM_inst : SRAM
    port map (
      clk => clk,
      reset => reset,
      flush_sram => flush_sram,
      occupied => occupied,
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

    NEXT_STATE_LOGIC : process (current_state, insert_flag, set_rule, vld_firewall_hash, exits_cuckoo, MAX, flip,flush_flag, 
                                previous_search, exits_matching, vld_hdr,rdy_ad_hash,delete_flag)
    begin
        next_state <= current_state;
                case(current_state) is

                    when command_state => 
                        if flush_flag = '1' then
                            next_state <= flush_memory;
                        elsif delete_flag = '1' then
                            next_state <= rdy_delete;
                        elsif insert_flag ='1' then
                            next_state <= rdy_key;
                        elsif set_rule = '0' then
                            next_state <= rdy_hash_matching;
                        end if ;

                    when rdy_key =>     
                        if insert_flag ='0' then
                            next_state <= command_state;
                        elsif vld_firewall_hash ='1' then
                            next_state <= lookup_hash1;
                        end if ;

                    when flush_memory => next_state <=command_state;
                        
                    when rdy_hash_matching => 
                        if set_rule = '1' then
                            next_state <= command_state;
                        elsif vld_hdr = '1' then
                            next_state <= search_hash1;
                        end if ;

                    when lookup_hash1 => next_state <= is_occupied;

                    when is_occupied => 
                        if eq_key = '1' then
                            next_state <= rdy_key;
                        elsif exits_cuckoo = '1' then
                            next_state <= remember_and_replace;
                        else
                            next_state <= insert_key;
                        end if;

                    when lookup_hash2 => next_state <= is_occupied;
                    when remember_and_replace => if MAX = MAX_ITER then
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
                        elsif (exits_matching = '1') or (previous_search = '1') then
                            next_state <= AD_communication;
                        end if ;

                    when AD_communication => 
                        if rdy_ad_hash = '1' then
                            next_state <= rdy_hash_matching;
                        end if ;
                       
                    when rdy_delete =>
                        if delete_flag ='0' then
                            next_state <= command_state;
                         elsif vld_firewall_hash ='1' then
                            next_state <= find_hashfun1;
                        end if ;

                    when find_hashfun1 => next_state <= match_for_delete;

                    when find_hashfun2 => next_state <= match_for_delete;
                    
                    when match_for_delete => 
                    if previous_search = '0' and exits_matching = '0'  then
                        next_state <= find_hashfun2;
                    elsif (exits_matching = '1') or (previous_search = '1') then
                        next_state <= delete_from_memory;
                    end if ;

                    when delete_from_memory => next_state <= rdy_delete;


                    when others => next_state <= rdy_hash_matching;

                end case ;

    end process;

    OUTPUT_LOGIC : process (current_state, cmd_in) 
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
           delete_flag <= '1';
       when "11" =>  --hash match
            delete_flag <= '0';
            insert_flag <= '0';
            flush_flag <= '0';
       when others => --stay in command_state

   end case ;
   when flush_memory => flush_sram <= '1'; flush_flag <= '0';
   
   when insert_key =>
            RW <= '1';
            data_in <= insertion_key;
            flip <= '1';
            
    when rdy_key => 
            if not (cmd_in = "01")  then
                insert_flag <= '0';
            end if ;
        rdy_firewall_hash <= '1'; 
        insertion_key<=key_in;
        MAX <= 0;
        eq_key <= '0';
        occupied <= '1';
            
    when lookup_hash1 =>
        rdy_firewall_hash <= '0';
        hashfun <= '0';
        RW <= '0';
        --address <=std_logic_vector(to_unsigned(to_integer(unsigned(insertion_key)) mod 227,96)(8 downto 0));
        address <= '0' & src_hash(insertion_key,g1);
    when lookup_hash2 =>
        hashfun <= '1';
        RW <= '0';
        --address <= std_logic_vector(to_unsigned((to_integer(unsigned(insertion_key)) mod 211)+256,96)(8 downto 0)); 
        address <= src_hash(insertion_key,g2)+"100000000";
    when is_occupied =>
        if data_out(95 downto 0) = insertion_key then
            eq_key <= '1';
        elsif data_out(96) = '1' then
            exits_cuckoo <= '1';
        else
            exits_cuckoo <= '0';
        end if;
        
    when remember_and_replace =>
        RW <= '1';
        data_in <= insertion_key;
        insertion_key <= data_out(95 downto 0);
        MAX <= MAX + 1;
        if flip = '1' then
            flip <= '0';
        else
            flip <= '1';
        end if;

    when ERROR =>
            
    when rdy_hash_matching =>
        rdy_hash <= '1';
        --matching_key <= header_data;
        previous_search <= '0';
        vld_ad_hash <= '0';
    when search_hash1 => 
        rdy_hash <= '0';
        RW <= '0';
        --address <=std_logic_vector(to_unsigned(to_integer(unsigned(matching_key)) mod 227,96)(8 downto 0));
        address <= '0' & src_hash(header_data,g1);
    when search_hash2 => 
        RW <= '0';
        --address <= std_logic_vector(to_unsigned((to_integer(unsigned(matching_key))/227 mod 227)+256,96)(8 downto 0)); 
        address <= src_hash(header_data,g2)+"100000000";
        previous_search <= '1';

    when matching => 
    if data_out(95 downto 0) = header_data then
        exits_matching <= '1';
        acc_deny_hash <= '0';
        DEBUG_KO_CNT <= DEBUG_KO_CNT +1; 
    else
        if previous_search = '1' then
            DEBUG_OK_CNT <= DEBUG_OK_CNT+1;
            acc_deny_hash <= '1';
        end if ;
        exits_matching <= '0';
    end if;
            
    when AD_communication => 
        vld_ad_hash <= '1';                             
                    
                    
                    when rdy_delete =>
                        if not (cmd_in = "10")  then
                            delete_flag <= '0';
                        end if ;
                        rdy_firewall_hash <= '1'; 
                        deletion_key <= key_in;
                        previous_search <= '0';
                        RW <= '0';
                        occupied <= '0';

                    when find_hashfun1 =>
                        rdy_firewall_hash <= '0';
                        rdy_hash <= '0';
                        RW <= '0';
                        address <= '0' & src_hash(deletion_key,g1);
                    when find_hashfun2 =>
                        RW <= '0';
                        address <= src_hash(deletion_key,g2)+"100000000";
                        previous_search <= '1';
                    when match_for_delete =>
                        if data_out(95 downto 0) = deletion_key then
                            exits_matching <= '1';
                            delete_the_key <= '1';
                        else
                            if previous_search = '1' then
                                delete_the_key <= '0';
                            end if ;
                        exits_matching <= '0';
                    end if;

                    when delete_from_memory =>
                        RW <='1';
                        data_in <= (others => '0');
                    
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure;
                    
                    end case ;
                    
                    end process;


end architecture ; -- Cuckoo_Hashing
