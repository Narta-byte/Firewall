library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

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
      val : in std_logic;
      rdy : out std_logic;
      acc_deny_out : out std_logic
    );
  end component;

  -- Ports
  signal clk : std_logic;
  signal reset : std_logic;
  signal set_rule : std_logic;
  signal cmd_in : std_logic_vector(1 downto 0);
  signal key_in : std_logic_vector(95 downto 0);
  signal header_in : std_logic_vector(95 downto 0);
  signal val : std_logic;
  signal rdy : std_logic;
  signal acc_deny_out : std_logic;

  -- fsm logic
  type State_type is (setup_rulesearch,set_key,wait_for_ready,send_key,TERMINATE, wipe_memory,wait_for_calc_to_finish);
  signal current_state, next_state : State_type;

  signal data_end,done_looping,last_rdy,calc_is_done : std_logic :='0';

  --maybe make theese varibles in output logic  
  signal cnt : integer;
  type data_array is array (0 to 9) of std_logic_vector(7 downto 0);
  signal data_array_sig : data_array;

begin

  Cuckoo_Hashing_inst : Cuckoo_Hashing
    port map (
      clk => clk,
      reset => reset,
      set_rule => set_rule,
      cmd_in => cmd_in,
      key_in => key_in,
      header_in => header_in,
      val => val,
      rdy => rdy,
      acc_deny_out => acc_deny_out
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

    --(setup_rulesearch,set_key,wait_for_ready,send_key,TERMINATE);

  NEXT_STATE_LOGIC : process (current_state, done_looping, rdy, val, data_end,calc_is_done)
  begin    
      case current_state is
        when setup_rulesearch =>
          next_state <= wipe_memory;

        when wipe_memory => next_state <= set_key;

        when set_key => if done_looping = '1' then
          next_state <= wait_for_ready;
        end if ;

        next_state <= send_key;
        when wait_for_ready => if data_end = '1' then
          next_state <= wait_for_calc_to_finish;
        elsif  rdy = '1' and val = '1'then
          next_state <= send_key;
        end if ;
        
        when send_key =>
          next_state <= wait_for_ready;
        
        when TERMINATE => 
          next_state <= TERMINATE;
          
          when wait_for_calc_to_finish => if rdy = '1' then
            next_state <= TERMINATE;
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
        val <= '1';
      when wait_for_ready => 
            
      when send_key =>
          key_in <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & data_array_sig(cnt);
          cnt <= cnt+1;
          if cnt = 9 then
            data_end <= '1';
            
          end if ;
      when TERMINATE => 
              val <= '0';
              cmd_in <= "11";
      when wait_for_calc_to_finish =>
        
      when others => report "FAILURE" severity failure;
          
      end case;
   
  end process;


 end;
