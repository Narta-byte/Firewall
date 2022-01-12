library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity Cuckoo_Hashing_tb is
end;

architecture bench of Cuckoo_Hashing_tb is

  component Cuckoo_Hashing
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
    );
  end component;



  -- Ports
  signal clk : std_logic;
  signal reset : std_logic;
  signal set_rule : std_logic;
  signal cmd_in : std_logic_vector(1 downto 0);
  signal key_in : std_logic_vector(95 downto 0);
  signal header_in : std_logic_vector(95 downto 0);
  signal val_hdr : std_logic;
  signal rdy_hdr : std_logic;
  signal val_in : std_logic;
  signal rdy_out : std_logic;
  signal acc_deny_out : std_logic;
  signal val_ad : std_logic;
  signal rdy_ad : std_logic;


  -- fsm logic
  type State_type is (setup_rulesearch,set_key,wait_for_ready_insert,send_key,terminate_insertion, wipe_memory,wait_for_last_calc_to_finish,
                      goto_cmd_state, start_hash_matching, send_match_key, wait_for_ready_match,terminate_match,test_a_wrong_header,
                      wait_for_match_to_fin, wait_for_wrong_calc_to_fin);
  signal current_state, next_state : State_type;

  signal data_end,done_looping,last_rdy,calc_is_done : std_logic :='0';

  --maybe make theese varibles in output logic  
  signal cnt : integer;
  type data_array is array (0 to 9) of std_logic_vector(7 downto 0);
  signal data_array_sig : data_array;

  --signals in hashmatching
  signal match_done : std_logic := '0'; 
  signal cnt_calc_fin : integer := 0;

  --signals for ac
  signal ok_cnt,ko_cnt : integer := 0;
  
begin

    Cuckoo_Hashing_inst : Cuckoo_Hashing
      port map (
        clk => clk,
        reset => reset,
        set_rule => set_rule,
        cmd_in => cmd_in,
        key_in => key_in,
        header_in => header_in,
        val_hdr => val_hdr,
        rdy_hdr => rdy_hdr,
        val_in => val_in,
        rdy_out => rdy_out,
        acc_deny_out => acc_deny_out,
        val_ad => val_ad,
        rdy_ad => rdy_ad
      );
  
 

CLK_PROCESS : process 
begin
  clk <= '1';
  wait for 10 ns;
  clk <= '0';
    wait for 10 ns;
    end process;


    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= setup_rulesearch;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if ;
    end process;  


  NEXT_STATE_LOGIC : process (current_state, done_looping, rdy_out, val_in, data_end,calc_is_done,
                              rdy_hdr, val_hdr, cnt_calc_fin, rdy_ad)
  begin
    next_state <= current_state; -- måske sus
      case current_state is
        when setup_rulesearch =>
          next_state <= wipe_memory;

        when wipe_memory => next_state <= set_key;

        when set_key => if done_looping = '1' then
          next_state <= wait_for_ready_insert;
        end if ;

        next_state <= send_key;
        when wait_for_ready_insert => if data_end = '1' then
          next_state <= wait_for_last_calc_to_finish;
        elsif  rdy_out = '1' and val_in = '1'then
          next_state <= send_key;
        end if ;
        
        when send_key =>
          next_state <= wait_for_ready_insert;
        
        when terminate_insertion => 
          if not (cnt_calc_fin = 2) and rdy_out = '1' then
            cnt_calc_fin <= cnt_calc_fin +1;
          elsif (cnt_calc_fin = 2)  then
            next_state <= goto_cmd_state;
          end if;
          
         when wait_for_last_calc_to_finish => 
          if rdy_out = '1' then
            next_state <= terminate_insertion;
          end if;

        when goto_cmd_state => next_state <= start_hash_matching;

        when start_hash_matching => --next_state <= wait_for_ready_match;
          next_state <= send_match_key;


        when send_match_key => 
          next_state <= wait_for_ready_match;
        
        when wait_for_ready_match => 
          if match_done = '1' then
            next_state <= wait_for_match_to_fin;
          elsif  (rdy_hdr = '1') and (val_hdr = '1')  then
            next_state <= send_match_key;
          end if ;
        when terminate_match => next_state <= terminate_match;

        when test_a_wrong_header => next_state <= wait_for_wrong_calc_to_fin;
            
        when wait_for_match_to_fin => 
          if rdy_hdr = '1' then
            next_state <= test_a_wrong_header;
          end if;
        
        when wait_for_wrong_calc_to_fin =>
          if rdy_hdr = '1' then
            next_state <= terminate_match;
          end if;
        when others =>
          next_state <= setup_rulesearch;
      end case;
  end process;

  OUTPUT_LOGIC : process (current_state)
  file input : TEXT open READ_MODE is "cuckoo_hash testdata.txt";
  variable current_read_line : line;
  variable hex_reader : std_logic_vector(7 downto 0);
  
  begin     
      case current_state is
      when setup_rulesearch => 
        set_rule <= '1';
	      cnt <= 0;
      
      when wipe_memory => cmd_in <= "00";
      when set_key =>
       
          READ_ARRAY : for i in 0 to 9 loop
            if not ENDFILE(input) then
              
              readline(input, current_read_line);
              HREAD(current_read_line, hex_reader);
              
              data_array_sig(i) <= hex_reader;
              end if ;
          
          end loop ; -- READ_ARRAY


        done_looping <= '1';
        cmd_in <= "01";
        val_in <= '1';
      when wait_for_ready_insert => 
            
      when send_key =>
          key_in <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & data_array_sig(cnt);
          cnt <= cnt+1;
          if cnt = 9 then
            data_end <= '1';
            
          end if ;
      when terminate_insertion => 
              val_in <= '0';
              cmd_in <= "11";

      when wait_for_last_calc_to_finish => --val_in <= '0';
      
      when goto_cmd_state => 

      when start_hash_matching => 
          cmd_in <= "11";
          cnt <= 0;
          val_hdr <= '1';
          rdy_ad <= '1'; --this simulates that the accept deny block is always ready
          --header_in <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & data_array_sig(cnt); 
          
         
          
      when send_match_key => 
          header_in <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & data_array_sig(cnt); 
          cnt <= cnt +1;            
          if cnt = 9 then
            match_done <= '1';
          end if ;

      when wait_for_ready_match => 
            --val_hdr<= '1';
            set_rule <= '0';
          if acc_deny_out = '1' then
              ok_cnt <= ok_cnt +1;
          elsif acc_deny_out = '0' then
              ko_cnt <= ko_cnt +1;
          end if;
            

      when terminate_match => val_hdr <= '0';

      when test_a_wrong_header => 
        header_in <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & "00011111";

      when wait_for_match_to_fin => 
      
      
      when wait_for_wrong_calc_to_fin =>
      

      when others => report "FAILURE" severity failure;
          
      end case;
   
  end process;

 end;
