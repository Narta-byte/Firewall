library IEEE;
library std; 
--LIBRARY altera_mf;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;
--USE altera_mf.all;

entity firewall is
end entity;

architecture firewall_arch of firewall is

  component Collect_Header
      port (
      clk : in std_logic;
      reset : in std_logic;
      packet_in : in std_logic_vector (9 downto 0);
      SoP : in std_logic;
      EoP : in std_logic;
      vld_firewall : in std_logic;
      rdy_FIFO : in std_logic;
      rdy_hash : in std_logic;
      
      rdy_collecthdr : out std_logic;
      header_data : out std_logic_vector (95 downto 0);
      packet_forward : out std_logic_vector (9 downto 0);
      vld_hdr : out std_logic;
      vld_hdr_FIFO : out std_logic;
      hdr_SoP : out std_logic;
      hdr_EoP : out std_logic
      
    );
  end component;

  component Cuckoo_Hashing
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
  acc_deny_hash : out std_logic;
  vld_ad_hash : out std_logic;
  rdy_ad_hash : in std_logic
);
end component;

component minfifo
      port (
      clock : in STD_LOGIC;
      data : in STD_LOGIC_VECTOR (9 DOWNTO 0);
      rdreq : in STD_LOGIC;
      wrreq : in STD_LOGIC;
      empty : out STD_LOGIC;
      full : out STD_LOGIC;
      q : out STD_LOGIC_VECTOR (9 DOWNTO 0);
      usedw : out STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  end component;

  component Accept_Deny
          port (
          clk : in std_logic; 
          reset : in std_logic; 

          data_firewall : out std_logic_vector(9 downto 0);
          ok_cnt : out std_logic_vector(8 downto 0);
          ko_cnt : out std_logic_vector(8 downto 0);

          packet_forward_FIFO : in std_logic_vector(9 downto 0); 
          rdy_ad_FIFO : out std_logic; 
          vld_fifo : in std_logic;  
          
          acc_deny_hash : in std_logic; 
          vld_ad_hash : in std_logic; 
          rdy_ad_hash : out std_logic    
        );
      end component;
  
  constant clk_period : time := 5 ns;

  -- Ports for Collect_header
  signal clk : std_logic := '0';
  signal reset : std_logic := '0';
  signal packet_in : std_logic_vector (9 downto 0) := "0000000000";
  signal SoP : std_logic := '0';
  signal EoP : std_logic := '0';
  signal vld_firewall : std_logic := '0';
  signal rdy_FIFO : std_logic := '0';
  signal rdy_hash : std_logic := '0';
  signal rdy_collecthdr : std_logic:='0';
  signal header_data : std_logic_vector (95 downto 0);
  signal packet_forward : std_logic_vector (9 downto 0) := "0000000000";
  signal vld_hdr : std_logic := '0';
  signal vld_hdr_FIFO : std_logic;
  signal hdr_SoP : std_logic := '0';
  signal hdr_EoP : std_logic := '0';
  signal entire_packet : std_logic_vector (9 downto 0);
  

  --cuckoo
  
  signal set_rule : std_logic := '0';
  signal cmd_in : std_logic_vector(1 downto 0) := "00";
  signal key_in : std_logic_vector(95 downto 0) := x"000000000000000000000000";
  signal header_in : std_logic_vector(95 downto 0) := x"000000000000000000000000";
  --signal vld_hdr : std_logic;
  --signal rdy_hash : std_logic;
  signal vld_firewall_hash : std_logic := '0';
  signal rdy_firewall_hash : std_logic := '0';
  signal acc_deny_hash : std_logic := '0';
  signal vld_ad_hash : std_logic := '0';
  signal rdy_ad_hash : std_logic := '0';

  --fifo
  --signal clk : STD_LOGIC;
  signal data : STD_LOGIC_VECTOR (9 DOWNTO 0) := "0000000000";
  signal rdreq : STD_LOGIC := '0';
  signal wrreq : STD_LOGIC := '0';
  signal empty : STD_LOGIC := '0';
  signal full : STD_LOGIC := '0';
  signal q : STD_LOGIC_VECTOR (9 DOWNTO 0) := "0000000000";
  signal usedw : STD_LOGIC_VECTOR (7 DOWNTO 0); -- 8?


  -- Accept deny
  signal packet_forward_FIFO : std_logic_vector(9 downto 0) := "0000000000";
  signal FIFO_sop : std_logic; --
  signal FIFO_eop : std_logic; --
  signal vld_fifo : std_logic;
  --signal acc_deny_hash : std_logic; 
  --signal vld_ad_hash : std_logic; 
  --signal rdy_ad_hash : std_logic;
  signal rdy_ad_FIFO : std_logic;
  signal data_firewall : std_logic_vector(9 downto 0) := "0000000000";
  signal ok_cnt : std_logic_vector(8 downto 0) := "000000000";
  signal ko_cnt : std_logic_vector(8 downto 0) := "000000000";

  --test signals
  signal test1_fin,test2_fin,test3_fin : std_logic := '0';
  


    -- cuckoo hash tb copy paste
  type State_type is (  
                        --test 1
                      setup_rulesearch,
                      set_keys_and_read_input_packets,
                      wait_for_ready_insert,
                      send_key,
                      terminate_insertion,
                      wait_for_last_calc_to_finish,
                      goto_cmd_state,
                      start_byte_stream,
                      pause_byte_stream,
                      comince_byte_stream_to_accept,
                      pause_byte_stream_to_accept,
                      comince_byte_stream,
                      terminate_match,
                      test_a_wrong_header,
                      wait_for_bytestream_to_fin,

                      --test 2
                      reset_all,

                      -- test 3
                      setup_delete_key,
                      delete_key,
                      wait_delete_key,
                      terminate_delete
                        );
  signal current_state, next_state : State_type;

  signal data_end,done_looping,last_rdy,calc_is_done : std_logic :='0';

  -- file management
  --constant data_length_keys : integer := 160;
  --constant data_length_packet : integer := 38689;
  constant data_length_keys : integer := 85;
  constant data_length_packet : integer := 5598;
  constant data_length_delete : integer := 4;

  --output logic signals 
  signal cnt : integer;
  type key_array is array (0 to data_length_keys) of std_logic_vector(95 downto 0);
  signal key_array_sig : key_array;

  type packet_array is array (0 to data_length_packet) of std_logic_vector(9 downto 0);
  signal packet_array_sig : packet_array;
    
  type delete_array is array (0 to data_length_delete) of std_logic_vector(95 downto 0);
  signal delete_array_sig : delete_array;

  --signals in hashmatching
  signal byte_stream_done : std_logic := '0'; 
  signal cnt_calc_fin : integer := 0;

  --signals in byte stream
  signal doneloop : std_logic;
  signal bytenm : integer := 0;
  signal packet_start : std_logic := '0';
  signal hex12 : std_logic_vector (7 downto 0);

  --signal h2 : std_logic_vector (3 downto 0);
  signal bits1 : std_logic_vector (0 downto 0);
  signal bits2 : std_logic_vector (0 downto 0);
  signal packet_data : std_logic_vector(7 downto 0);

  signal bytenumber : integer := 0;
  signal nextbytenum : integer := 0;
  
  --test 3
  signal deletion_done : std_logic := '0';
  
begin
  
  CLOCK : process 
  begin
      clk <= '1';
      wait for 10 ns;
      clk <= '0';
      wait for 10 ns;
  end process;


  Collect_Header_inst : Collect_Header
  port map (
    clk => clk,
    reset => reset, 
    packet_in => packet_in, 
    SoP => SoP, 
    EoP => EoP, 
    vld_firewall => vld_firewall,
    rdy_FIFO => rdy_FIFO, -- skal vare sit eget signal
    rdy_hash => rdy_hash, -- vi har signal
    rdy_collecthdr => rdy_collecthdr, 
    header_data => header_data, --yes burde virke
    packet_forward => packet_forward, -- kan ikke implementeres pt
    vld_hdr => vld_hdr, 
    vld_hdr_FIFO => vld_hdr_FIFO,
    hdr_SoP => hdr_SoP, -- kan ikke implementeres pt
    hdr_EoP => hdr_EoP -- kan ikke implementeres pt
  );
  SoP <= packet_in(1);
  EoP <= packet_in(0);


    Cuckoo_Hashing_inst : Cuckoo_Hashing
    port map (
      clk => clk, --yes
      reset => reset, --yes
      set_rule => set_rule, --yes
      cmd_in => cmd_in, --yes
      key_in => key_in, --yes
      header_data => header_data, --yes
      vld_hdr => vld_hdr, --yes
      rdy_hash => rdy_hash, --yes
      vld_firewall_hash => vld_firewall_hash, --yes
      rdy_firewall_hash => rdy_firewall_hash, --yes
      acc_deny_hash => acc_deny_hash, --kan ikke implementeres pt
      vld_ad_hash => vld_ad_hash, 
      rdy_ad_hash => rdy_ad_hash
    );
  
    minfifo_inst : minfifo
    port map (
      clock => clk,
      data => data, --packet_forward?
      rdreq => rdreq, -- rdy
      wrreq => wrreq, --= val
      empty => empty,
      full => full, -- rdy = not(full)
      q => packet_forward_FIFO,
      usedw => usedw
    );
    vld_fifo <= not full;
    rdreq <= rdy_ad_FIFO and (not empty);
    wrreq <= vld_hdr_FIFO and (not full);
    rdy_collecthdr <= not full;
    --FIFO_sop <= q(8);
    --FIFO_eop <= q(9);
    data <=  packet_forward;

    Accept_Deny_inst : Accept_Deny
        port map (
          clk => clk,
          reset => reset,
          
          data_firewall => data_firewall,
          ok_cnt => ok_cnt,
          ko_cnt => ko_cnt,
          
          packet_forward_FIFO => packet_forward_FIFO,
          vld_fifo => vld_fifo,
          rdy_ad_FIFO => rdy_ad_FIFO,

          acc_deny_hash => acc_deny_hash,
          vld_ad_hash => vld_ad_hash,
          rdy_ad_hash => rdy_ad_hash
        );
    

    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= setup_rulesearch;
            
        elsif rising_edge(clk) then
            current_state <= next_state;
            --bytenumber <= nextbytenum;
            if bytenumber = data_length_packet then
              bytenumber <= 0;
              --nextbytenum <= 0;
            else
              bytenumber <= nextbytenum;
              
            end if ;
        end if ;
    end process;  
    
    NEXT_STATE_LOGIC : process (current_state, done_looping, 
                              rdy_firewall_hash, vld_firewall_hash,
                              data_end,calc_is_done,
                              rdy_hash,
                              vld_hdr, cnt_calc_fin,
                              rdy_ad_hash,
                              byte_stream_done,
                              test1_fin,
                              test2_fin,  
                              test3_fin,
                              deletion_done)
  begin
    next_state <= current_state; -- måske sus
      case current_state is
        when setup_rulesearch =>
          next_state <= set_keys_and_read_input_packets;
          cnt_calc_fin <= 0;
        when set_keys_and_read_input_packets => if done_looping = '1' then
          next_state <= wait_for_ready_insert;
        end if ;

        next_state <= send_key;
        when wait_for_ready_insert => if data_end = '1' then
          next_state <= wait_for_last_calc_to_finish;
        elsif  rdy_firewall_hash = '1' and vld_firewall_hash = '1'then
          next_state <= send_key;
        end if ;
        
        when send_key =>
          next_state <= wait_for_ready_insert;
        
        when terminate_insertion => 
          if not (cnt_calc_fin = 2) and rdy_firewall_hash = '1' then
            cnt_calc_fin <= cnt_calc_fin +1;
          elsif (cnt_calc_fin = 2)  then
            next_state <= goto_cmd_state;
          end if;
          
         when wait_for_last_calc_to_finish => 
          if rdy_firewall_hash = '1' then
            next_state <= terminate_insertion;
            --next_state <= setup_delete_key;
          end if;

        when goto_cmd_state => 
        if test2_fin = '1' and deletion_done = '1' then
          next_state <= start_byte_stream;
        
        elsif test2_fin = '1' then
          next_state <= setup_delete_key;

        else
          next_state <= start_byte_stream;  
        end if ;

        when start_byte_stream => --next_state <= pause_byte_stream;
          next_state <= comince_byte_stream;


        when comince_byte_stream => 
          if byte_stream_done = '1' then
            next_state <= terminate_match;
          elsif rdy_FIFO = '0'  or vld_firewall = '0' then
            next_state <= pause_byte_stream;          
          elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
            next_state <= comince_byte_stream;
          end if;
        
        when pause_byte_stream => 
        if rdy_FIFO = '0' or vld_firewall = '0' then
            next_state <= terminate_match;
          elsif rdy_FIFO = '1'  and vld_firewall = '1' then
            next_state <= comince_byte_stream;
        end if;
        
        when terminate_match =>
            if test3_fin = '1' then
              next_state <= terminate_match;
            elsif test1_fin = '1' and test2_fin = '1' and test3_fin = '0' then
              next_state <= setup_rulesearch;
            else
              next_state <= reset_all;
            end if ;

        --test 2
        when reset_all => next_state <= setup_rulesearch;

        --test 3
        when setup_delete_key => next_state <= delete_key;

        when delete_key => next_state <= wait_delete_key;

        when wait_delete_key => 
        if data_end = '1' then
          next_state <= terminate_delete;  
        elsif  rdy_firewall_hash = '1' and vld_firewall_hash = '1'then
          next_state <= delete_key;
        end if ;

        when terminate_delete => next_state <= goto_cmd_state;

        when others => next_state <= setup_rulesearch;
          
      end case;
  end process;

  OUTPUT_LOGIC : process (current_state, bytenumber)
  file input : TEXT open READ_MODE is "keys_to_be_programmed 2.txt";
  variable current_read_line_keys : line;
  variable std_logic_vector_reader : std_logic_vector(95 downto 0);
  
  --file input_packet : TEXT open READ_MODE is "Input_packet.txt"; 
  file input_packet : TEXT open READ_MODE is "packet input tcp syn ack.txt";  
  variable current_read_line	: line;
  variable current_read_field	: std_logic_vector (7 downto 0);
  variable current_bit_read_SoP : std_logic_vector (0 downto 0);
  variable current_bit_read_EoP : std_logic_vector (0 downto 0);
  variable start_of_data_Reader : std_logic;

  file input_delete_keys : TEXT open READ_MODE is "delete_keys.txt";
  variable current_read_line_delete_keys : line;
  variable delete_reader : std_logic_vector(95 downto 0);
  
  
  file output : text open WRITE_MODE is "DEBUG_OUTPUT.txt";
  variable write_line : line;
  begin
    nextbytenum <= bytenumber;
      case current_state is
      when setup_rulesearch => 
        set_rule <= '1';
	      cnt <= 0;
        reset <= '0';
        byte_stream_done <= '0';
        data_end <= '0';
        cnt <= 0;
        --cnt_calc_fin <= 0; --fix senere
      
      when set_keys_and_read_input_packets =>
       
          READ_ARRAY : for i in 0 to data_length_keys loop
            if not ENDFILE(input) then
              readline(input, current_read_line_keys);
              READ(current_read_line_keys, std_logic_vector_reader);
              key_array_sig(i) <= std_logic_vector_reader;
              end if ; 
           
          end loop ; -- READ_ARRAY 

          READ_INPUT_PACKET : for i in 0 to data_length_packet loop
            if not ENDFILE(input_packet) then
              readline(input_packet, current_read_line);
              hread(current_read_line, current_read_field);
              read(current_read_line, current_bit_read_SoP);
              read(current_read_line, current_bit_read_EoP);
              packet_array_sig(i) <= current_read_field & current_bit_read_SoP & current_bit_read_EoP;
              packet_data <= hex12;
                    
            else
              doneloop <= '1'; --TODO SLET
            end if;

            
          end loop ; -- READ_INPUT_PACKET
          READ_DELETE_KEYS : for i in 0 to data_length_delete loop
            if not ENDFILE(input_delete_keys) then
              readline(input_delete_keys, current_read_line_delete_keys);
              READ(current_read_line_delete_keys, delete_reader);
              delete_array_sig(i) <= delete_reader;
            end if;
          end loop ; -- READ_DELETE_KEYS



        done_looping <= '1';
        cmd_in <= "01";
        vld_firewall_hash <= '1';

      when wait_for_ready_insert => 
            
      when send_key =>
          key_in <= key_array_sig(cnt);
          cnt <= cnt+1;

          if cnt = data_length_keys then
            data_end <= '1';
            
          end if ;
         
      when terminate_insertion => 
              vld_firewall_hash <= '0';
              cmd_in <= "11";

      when wait_for_last_calc_to_finish => --vld_firewall_hash <= '0';
      
      when goto_cmd_state => 

      when start_byte_stream => 
          cmd_in <= "11";
          cnt <= 0;
          --vld_hdr <= '1';
          --rdy_ad_hash <= '1'; --this simulates that the accept deny block is always ready
          --header_data <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & key_array_sig(cnt);
          vld_firewall <= '1';

      when comince_byte_stream => --packet_input 
      set_rule <= '0';
      nextbytenum <= bytenumber +1;
      packet_in <= packet_array_sig(nextbytenum);
        if bytenumber = data_length_packet-1 then
          byte_stream_done <= '1';
        end if ;
      
      when pause_byte_stream =>              

      when terminate_match => 
      test1_fin <= '1';
      if test1_fin = '1' and test2_fin = '0' then
        test2_fin <= '1';
      end if;

      if test2_fin = '1' and test3_fin = '0'then
        test3_fin <= '1';
      end if;
      
      if ok_cnt = "00000011" and ko_cnt = "1010110" and test1_fin = '0'  then
        report "TEST 1 PASSED" severity NOTE;
      elsif test1_fin = '0' then
        report "TEST 1 FAILED ok = " & integer'image(to_integer(unsigned(ok_cnt))) & " ko = " & integer'image(to_integer(unsigned(ko_cnt))) severity ERROR;
        
       end if ;

      if ok_cnt = "00000011" and ko_cnt = "1010110" and test2_fin = '0' and test3_fin = '0' and test1_fin = '1'  then
        report "TEST 2 PASSED" severity NOTE;
      elsif  test2_fin = '1' and test1_fin = '1' then
        report "TEST 2 FAILED ok = " & integer'image(to_integer(unsigned(ok_cnt))) & " ko = " & integer'image(to_integer(unsigned(ko_cnt))) severity ERROR;
      end if ;

      if ok_cnt = "00001011" and ko_cnt = "10100111" and test3_fin = '0' and test2_fin = '1' and test1_fin = '1'  then
        report "TEST 3 PASSED" severity NOTE;
      elsif  test2_fin = '1' and test1_fin = '1' then
        report "TEST 3 FAILED ok = " & integer'image(to_integer(unsigned(ok_cnt))) & " ko = " & integer'image(to_integer(unsigned(ko_cnt))) severity ERROR;
      end if ;


      when test_a_wrong_header => 

      when wait_for_bytestream_to_fin => 
      
      when reset_all =>
      reset <= '1'; 
      
      when setup_delete_key => 
        cmd_in <= "10";
        cnt <= 0;
        vld_firewall <= '1';
        data_end <= '0';
        vld_firewall_hash <= '1';

      when delete_key => 
        key_in <= delete_array_sig(cnt);
        cnt <= cnt +1;
        if cnt = data_length_delete then
          data_end <= '1';
          
        end if ;

      when wait_delete_key =>
        
      when terminate_delete => 
        vld_firewall_hash <= '0';
        deletion_done <= '1';

      when others => report "FAILURE" severity failure;
          
      end case;
      --report "TEST 1 FAILED" & integer'image(86) severity ERROR;
        
  end process;

  TestInputs : process 
  begin
    rdy_FIFO <= '1'; wait for 1390 ns;
--    ready_FIFO <= '1'; wait for 10000 ns;
    rdy_FIFO <= '0'; wait for 10 ns;  
    rdy_FIFO <= '1'; wait;

  end process;

  TEST_OUTPUT : process (test1_fin)
  begin
    if full = '1' then
      report "THE FIFO SHOULD NEVER BE FULL" severity ERROR;
    end if ;


    if test1_fin = '1' then
        


    end if ;

  end process;
  -- testvld : process 
  -- begin
  --   -- vld_firewall <= '1'; wait;
    
  -- end process;

   
    end; 
-- //                                      ;;.
-- //                                     ,t;i,                 ,;;;:
-- //                                     :t::i,              ,;i;:,:,
-- //                                     11;:;i;.          .;i;:::,,:
-- //                                    ,1;i11i11iii;;;;::;;:,:,..,,:.
-- //                                  .:1ttt11i;iii1111ii;:.,:,. .,::.
-- //                              ,i1tfftfffti;;ii;iiiiiii;:,,.  ,:;,
-- //                             ;Lfffttttft1;;;i111i;;iii11i:..,:,;;
-- //                            .fLLLt:,,;t1i;;1tttt1ii;iii1111i;:,:1;
-- //                            1C00Ci. .i1t111ii;;:,:;;iii11111i;,,it.
-- //                           ,C00Ct1i1tttftti:. :.  ,ii11111111i;:;1,
-- //                           t0GGGfffftffftt1i;::,:i1tfffttttt11iii1;
-- //                          ,CCGC;,...,;fLftt1tt11111tfLLftffftt11i11.
-- //                          iGLGt       tLfftttfffLffffffLfffttt1ii11i
-- //                          iGLf;.    .:i1tt11ffffffLfffftt1111ii;iiit;
-- //                          1GLt:..  ..:iii1111ttttt1ttt1111111i;;i;i1t
-- //                          ;GLLt,     .,::::,:i11111t11ttfttt1i;;;;iit:
-- //                          .LCLft;.........,:i1111ttttttttt11i;;;;;;i1i
-- //                           ,LLfff1iiiiiiii111111111tttt11iii;;;;::;;it;
-- //                            tfffftttt1111iiiiii1ttttt111iii;;;:::;;;iti
-- //                           :Ltttttt1111iiiiiii1tttt111111iii;:::;iii1t1
-- //                           ;Lftt11111111iiiiiiii;iii11111ii;;;ii111t1f1
-- //                           tLffftt1ii;ii;;;;;;;;ii11111111ii1tttttttttf
-- //                           fCLfftt11ii;;;;;;ii11t11111tttttffffffftttt1
-- //                          ,LCLLfft111iiiiiii11t111ttt11tttffttfffftt11:
-- //                       .:1fLLLffttt11iiiiii111111111ttft1tffffffftt1ii;
-- //                     ,1fLLCLLffttt111iiiii11111111t1tttfftfffffftt1i;;i
-- //                  .:tffLCCCCLfftt1111i1i1111111t1t1111ttffffttt11ii;;;i
-- //                 ,fLffLGGCGCLfftt111ii11111t1tttttttt11tfffftt111i;;;;1
-- //                :fftfCGGLCCLLftt111ii1ii1111111tt11tttt1tttttttttti;;;t.
-- //                :11tLGGLfffffttt1111iiiiiiii11111111i1111tttttffft1;;;1.
-- //            .,;i111tCCLfftt11t11111i1ii1iiiiiii1i1ii11111ttttttfft1;:;:
-- //          ,:;iiiii1tLLfttftt1iiiiiiiiiiiiiiiii1iii11111i111ttttttti;;;,
-- //          ;;:;;;::1ffffffLLfftt111111iii1iiiii1ii111111ii11ttttttti;;i,
-- //          .:::::iLGftffLLLLLLfttttttt1iii11tttttt11iiiii111ttttttti;;;
-- //            ...;1tt1tfLLLLLLLfftt11t1ttfLCCLLLftt111iiii1111tttttt1ii.
-- //                    1CLLLLLLLfftttffLGGGGCLLCLft1t11iii111t111ttttt1,
-- //                    ,ttfffLLLLLfffLLGGLCCff11fttt11iiii11111111tt1t,
-- //                        ..:;itf1tfffttt;1ti;::11i;;;iiiii111111111i
-- //                              ..:1t1;::...:;, :1tfi,;ii;ii1111ii;i.
-- //                                  ..,;;:.....;11tLL;:,:::;;;iiii;:
-- //                                      ,;... .:,:i;1i,         ...
-- //                                               ....,

 
      
    


    -- //                 .
    -- //                .;;:,.
    -- //                 ;iiii;:,.                                   .,:;.
    -- //                 :i;iiiiii:,                            .,:;;iiii.
    -- //                  ;iiiiiiiii;:.                    .,:;;iiiiii;i:
    -- //                   :iiiiiiiiiii:......,,,,,.....,:;iiiiiiiiiiii;
    -- //                    ,iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:
    -- //                     .:iii;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;,
    -- //                       .:;;iiiiiiiiiiiiiiiiiiiiiiiiiii;;ii;,
    -- //                        :iiii;;iiiiiiiiiiiiiii;;iiiiiii;:.
    -- //                       ,iiii;1f:;iiiiiiiiiiii;if;:iiiiiii.
    -- //                      .iiiii:iL..iiiiiiiiiiii;:f: iiiiiiii.
    -- //                      ;iiiiii:.,;iiii;iiiiiiii:..:iiiiiiii:
    -- //                     .i;;;iiiiiiiiii;,,;iiiiiiiiiiii;;iiiii.
    -- //                     ::,,,,:iiiiiiiiiiiiiiiiiiiiii:,,,,:;ii:
    -- //                     ;,,,,,:iiiiiiii;;;;;;;iiiiii;,,,,,,;iii.
    -- //                     ;i;;;;iiiiiiii;:;;;;;:iiiiiii;::::;iiii:
    -- //                     ,iiiiiiiiiiiiii;;;;;;:iiiiiiiiiiiiiiiiii.
    -- //                      .iiiiiiiiiiiiii;;;;;iiiiiiiiiiiiiiiiiii:
    -- //                       .;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii;
    -- //                        ;iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii.
    -- //                       .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,


-- //                                                       ..,;;:::::...,,,,:,,,,,,,,
-- //                                                     .,::,,::.1:.
-- //              ,,..        ;;:;,:::,.                .:,:  ,,. ,..
-- //         .1CCi:t;::,     ,1;::itttti:               ,,,. ,.
-- //        :GCCf1i111ii;.   .   .::11ii;.              ..,.
-- //       .CLffttffLLft1i. .   ,:::ii:,:.    ..... ..     .
-- //       tC1LttffftLL1;::.   ,;1tii1ti;    i111,.,,:.    .:,           ..
-- //      ,ti1t;iii::1fi;;::   :;;;;;ii;.    :;i:,::;;.     ;LCffftff1i1Lt.         .
-- //    ,,;;,;::i111tttttfi:.  .itfftLL1:::. :i: :;:::.      18@@@@@@@0Gf.
-- // itLft;;;;:;i11tfttt1ii, ,1CGGCCCLLCCLt. ,:. .,,:,      .GGG80LG8888:
-- // 1t:,:if1;1;;i1i1i::,:;;L088CfLC0fi;1;  ,,.    .,.      ,LCtL00GG08@i
-- // ;: ,1GC::;,:;i1tii11itGCCLtfLLCCf;,,:  ,,  .   .,      .ft;i;ifCCGG:
-- // i:tG0GftLtf1:::i111fCGft1,.:tti,.         .     .    .:;1tftttttttti;;:;:.  ....
-- // ;it;;:,.:;i;,ii.,1C0GCCi.   .,.                     ,t1...;111LLfftii;;t1i,tCGCf
-- // 1;,        .;;iifGGCCCi    ..,,                .  .:,..       ....,,,.,.,ifLffi:
-- // CCCL,:fLfi, :1L0GCLLf;      .,.                    ....,,,::,,,,,,,::1ttiitLfttt
-- // 1ii:.C8008GiLGCCLfff;       .,.       ..    ......          ::i;::;:,iLLLLCLLLLf
-- // ;11:1C0000GCCLLfftf;        .,.       ..,:,,,;;:;;;;;;;;iii1fLCLLCLt1it1ttttt1t1
-- // :;;;iffGCCLffftttt;..        .      .. .,,.........,,,,,:itLttffttfttt1111111i;;
-- //   .: :tLLfftttt1i, .         ,.    ...  ..,,........... ,i1fii1t1111111t1i11tt;t

-- //            ..,:;i;:::,,,..
-- //       ,:;ii11111111i11111ii;,                       ..,,::;:,,,...
-- //    :11t11iii;;;;;;;;;;;;;;iiii:                 ,;1111111111iiiiiii;:.
-- //  ,tt1i;;;;;;;;;;;;;;;;;iii;::;i;..           .;1t1ii;;;;;;;;;;;;;;;;ii;,
-- // i1i::::;;:::::::::::;1tffft1i:,:::;         it1i::;;;;:::::;;;;i1t1i:::;;,
-- // i::::::::::::::::::;1ttttttfft1i;i:        :1;:::::::::::::::i1ffffft1;::i,
-- // ,:::::,,,:,,,,,,::ittttttttttttt1;,        :::::::::::::::::itttttttttt1i;.
-- // ,::::,,,,,,,,,,,:;1ttttttttttttt1i.       ,:::::,,,,,,,,,,:;tttttttttttt1:
-- // ,:::,,,,,,,,,,,,,;tttttttftttttttLf;     .:::::,,,,,,,,,,,:1tttttt111ttt1i.
-- // ,:,,,,,.,,,,,,,,,,iffttt11G00GffLiL8,   .::::::,,,,,,,,,,,,ittttttLCCLttLGL.
-- // ,,,,........,,,.,.,;1ttt, G@0Gttf;1L.  .:::::,,...,,,,,,,,,:1ttttG801;tfC8i
-- // ,,..................,i11;;11iifftf;    .::,,,,.......,,,....,:1t1tti.:tft1,
-- // ,,,,................,:i111ii1ffffLt:.  .,,,.,,................:11i;;1tffft:
-- // .,;;................:ii1ttffffttttti:  .,...,;;,.............,;i1ttffffffft:
-- //  .,................,ii1tttttttt1:...,.  .,...::,............,;11ttttttt1;:,,
-- //   .................:;;:;;;iiiii:,..      .,.................,i;;iiii111;. .
-- //    ..  ......  ....,:;iiiiiiiii;;.        .,.. .........  ..,:;;;;;;;;;:::.
-- //     ...          ...,,,,,,,:::;:.          .:;,        ......,::;;:;;;i;:.
-- //      .1ft1i;,...     .........,.           .:1tii;:,,...      .......,,:
-- //       iftfttt1tttt11i;::,...  ..             1tfftttffftt1iii;:,,..   ..
-- //     :tLLft111ii;;iii1111111i;;;:           .tCLLf111iiiiii111ttt111i;::
-- // ::;L0GfLLCCCCCCLt1i;;;;;ittft111;:,,..,::;1G0LfLCCCCLLLft1ii;;;;iii1111;::::::::