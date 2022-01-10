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


    val : in std_logic;
    rdy : out std_logic;

    acc_deny_out : out std_logic
  ) ;
end Cuckoo_Hashing ;

architecture Cuckoo_Hashing_tb of Cuckoo_Hashing is

    type State_type is (idle, hash_matching, lookup_hash1,lookup_hash2,insert_key,remember_and_replace
,ERROR,is_occupied,rdy_key,flush_memory);
    signal current_state, next_state : State_type;

    signal RW : std_logic:='0';


    signal exits,insert_flag,hashfun,flip,flush_flag,flush_sram : std_logic := '0';
    signal MAX : integer:= 0;
    signal old_key : std_logic_vector(95 downto 0);
    --signal rdy_interal : std_logic;
    
    signal test_int : integer;
    signal test_old_key : std_logic_vector(95 downto 0);
    signal test_sram_msb : std_logic := '0';
    
    

    component SRAM is
        port (
            clk : in std_logic;
            reset : in std_logic;
	    flush_sram : in std_logic;
            WE : in std_logic; -- read/write
            address : in std_logic_vector(5 downto 0);
            occupied_flag_in : in std_logic;
            hash_in : in std_logic_vector(5 downto 0);
            key_in : in std_logic_vector(95 downto 0);
            data_out : out std_logic_vector(102 downto 0)
        );
    end component;
   signal hash_out : std_logic_vector(5 downto 0);
   signal key_out :  std_logic_vector(95 downto 0);
   signal address :  std_logic_vector(5 downto 0);
   signal occupied_flag_out :  std_logic;
   signal SRAM_data :  std_logic_vector(102 downto 0);

   signal insertion_key : std_logic_vector(95 downto 0);
   
   
begin

    SRAM_in : SRAM port map (clk,reset,flush_sram,RW,address,occupied_flag_out,hash_out,key_out,SRAM_data);
    --rdy <= rdy_interal;

    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= hash_matching;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if ;
    end process;

    NEXT_STATE_LOGIC : process (current_state, insert_flag, set_rule, val, exits, max, flip,flush_flag)
    begin
        next_state <= current_state;


                case(current_state) is

                    when idle => if flush_flag = '1' then
                        next_state <= flush_memory;
                    elsif insert_flag ='1' then
                        next_state <= rdy_key;
                    elsif set_rule = '0' then
                        next_state <= hash_matching;
                    end if ;
                    when rdy_key => if insert_flag ='0' then
                        next_state <= idle;
                    elsif val ='1' then
                        next_state <= lookup_hash1;
                    end if ;
                    when flush_memory => next_state <=idle;
                        
                    when hash_matching => if set_rule = '1' then
                        next_state <= idle;
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
                    when insert_key => next_state <= rdy_key;
                    when others => next_state <= hash_matching;

                end case ;

    end process;

    OUTPUT_LOGIC : process (current_state, cmd_in) --har fjernet reset
    begin

                case(current_state) is
                    when idle =>
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
                       when others => Report "CMD CANNOT BE 11" severity NOTE;

                   end case ;
                       when hash_matching => --TODO
                       when flush_memory => flush_sram <= '1'; flush_flag <= '0';

                    when insert_key =>
                        if hashfun = '0' then
                            RW <= '1';
                            key_out <= insertion_key;
                            flip <= '1';
                        elsif hashfun = '1' then
                            RW <= '1';
                            key_out <= insertion_key;
                            flip <= '1'; 

                        end if;
                    when rdy_key => 
                        rdy <= '1'; 
                        insertion_key<=key_in;

                    when lookup_hash1 =>
                        rdy <= '0';
                        hashfun <= '0';
                        RW <= '0';
                        address <= std_logic_vector(to_unsigned(to_integer(unsigned(insertion_key)) mod 11,96)(5 downto 0));

                    when lookup_hash2 =>
                        hashfun <= '1';
                        RW <= '0';
                        address <= std_logic_vector(to_unsigned((to_integer(unsigned(insertion_key))/11 mod 11)+15,96)(5 downto 0)); -- plus 15 er lidt sus
                    when is_occupied =>

                        
                        -- if hashfun = '1' then
                        --     insertion_key <= old_key;
                        -- elsif hashfun = '0' then
                        --     insertion_key <= key_in;
                        -- end if ;


                        if SRAM_data(102) = '1' then
                            exits <= '1';
                        else
                            exits <= '0';
                        end if;

                    when remember_and_replace =>
                        
                        old_key <= SRAM_data(95 downto 0);
                        RW <= '1';
                        --key_out <= key_in;
                        key_out <= insertion_key;
                        insertion_key <= SRAM_data(95 downto 0);
                        --hash_out <= std_logic_vector(to_unsigned(to_integer(unsigned(key_in)) mod 11,96)(5 downto 0));
                        hash_out <= "000000";
                        occupied_flag_out <= '1'; --skal måske være her
                        if flip = '1' then
                            flip <= '0';
                        else
                            flip <= '1';
                        end if;
                    when ERROR =>

                    when others => report "ERROR IN OUTPUT LOGIC" severity failure;

                end case ;

    end process;


end architecture ; -- Cuckoo_Hashing


