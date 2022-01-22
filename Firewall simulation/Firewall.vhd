library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity firewall is
  port (
    ADC_CLK_10 : in std_logic;
    KEY0 : in std_logic;
    LEDR : out std_logic_vector(9 downto 0);
    HEX0, HEX1, HEX3, HEX4 : out std_logic_vector(0 to 6)
  );
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
      clock : in std_logic;
      data : in std_logic_vector (9 downto 0);
      rdreq : in std_logic;
      wrreq : in std_logic;
      empty : out std_logic;
      full : out std_logic;
      q : out std_logic_vector (9 downto 0);
      usedw : out std_logic_vector (7 downto 0)
    );
  end component;

  component Accept_Deny
    port (
      clk : in std_logic;
      reset : in std_logic;

      data_firewall : out std_logic_vector(9 downto 0);
      ok_cnt : out std_logic_vector(7 downto 0);
      ko_cnt : out std_logic_vector(7 downto 0);

      packet_forward_FIFO : in std_logic_vector(9 downto 0);
      rdy_ad_FIFO : out std_logic;
      vld_fifo : in std_logic;

      acc_deny_hash : in std_logic;
      vld_ad_hash : in std_logic;
      rdy_ad_hash : out std_logic
    );
  end component;

  component prog_keys_rom
    port (
      address : in std_logic_vector(6 downto 0);
      data_out : out std_logic_vector(95 downto 0)
    );
  end component;
  component input_packet_rom
    port (
      address : in std_logic_vector(12 downto 0);
      data_out : out std_logic_vector(9 downto 0)
    );

  end component;

  component delete_keys_rom
    port (
      address : in std_logic_vector(2 downto 0);
      data_out : out std_logic_vector(95 downto 0)
    );
  end component;

  -- Ports for Collect_header
  signal clk : std_logic := '0';
  signal reset : std_logic := '0';
  signal packet_in : std_logic_vector (9 downto 0) := (others => '0');
  signal SoP : std_logic := '0';
  signal EoP : std_logic := '0';
  signal vld_firewall : std_logic := '0';
  signal rdy_FIFO : std_logic := '0';
  signal rdy_hash : std_logic := '0';
  signal rdy_collecthdr : std_logic := '0';
  signal header_data : std_logic_vector (95 downto 0);
  signal packet_forward : std_logic_vector (9 downto 0) := (others => '0');
  signal vld_hdr : std_logic := '0';
  signal vld_hdr_FIFO : std_logic;
  signal hdr_SoP : std_logic := '0';
  signal hdr_EoP : std_logic := '0';
  signal entire_packet : std_logic_vector (9 downto 0);

  -- Cuckoo_Hasing
  signal set_rule : std_logic := '0';
  signal cmd_in : std_logic_vector(1 downto 0) := "00";
  signal key_in : std_logic_vector(95 downto 0) := (others => '0');
  signal header_in : std_logic_vector(95 downto 0) := (others => '0');
  signal vld_firewall_hash : std_logic := '0';
  signal rdy_firewall_hash : std_logic := '0';
  signal acc_deny_hash : std_logic := '0';
  signal vld_ad_hash : std_logic := '0';
  signal rdy_ad_hash : std_logic := '0';

  -- FIFO
  signal data : std_logic_vector (9 downto 0) := (others => '0');
  signal rdreq : std_logic := '0';
  signal wrreq : std_logic := '0';
  signal empty : std_logic := '0';
  signal full : std_logic := '0';
  signal q : std_logic_vector (9 downto 0) := (others => '0');
  signal usedw : std_logic_vector (7 downto 0); 
  
  -- Accept_Deny
  signal packet_forward_FIFO : std_logic_vector(9 downto 0) := (others => '0');
  signal FIFO_sop : std_logic; 
  signal FIFO_eop : std_logic; 
  signal vld_fifo : std_logic;
  signal rdy_ad_FIFO : std_logic;
  signal data_firewall : std_logic_vector(9 downto 0) := (others => '0');
  signal ok_cnt : std_logic_vector(7 downto 0) := (others => '0');
  signal ko_cnt : std_logic_vector(7 downto 0) := (others => '0');

  -- Test signals
  signal test1_fin, test2_fin, test3_fin : std_logic := '0';
  
  -- Next signals
  signal set_rule_next : std_logic;
  signal data_end_next : std_logic;
  signal cmd_in_next : std_logic_vector(1 downto 0);
  signal vld_firewall_hash_next : std_logic;
  signal key_in_next : std_logic_vector(95 downto 0);
  signal test1_fin_next, test2_fin_next, test3_fin_next : std_logic;
  signal deletion_done_next : std_logic;
  signal ledr0_next, ledr1_next, ledr2_next : std_logic;
  signal ledr0_reg, ledr1_reg, ledr2_reg : std_logic := '0';
  signal address_keys_next : std_logic_vector(6 downto 0);
  signal address_packet_next : std_logic_vector(12 downto 0);
  signal address_delete_next : std_logic_vector(2 downto 0);

  type State_type is (
    -- Test 1
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

    -- Test 2
    reset_all,

    -- Test 3
    setup_delete_key,
    delete_key,
    wait_delete_key,
    terminate_delete
  );
  
  signal current_state, next_state : State_type;
  signal data_end, done_looping : std_logic := '0';

  -- File management
  constant data_length_keys : integer range 0 to 85 := 85;
  constant data_length_packet : integer range 0 to 5598 := 5598;
  constant data_length_delete : integer range 0 to 4:= 4;

  -- Signals in hashmatching
  signal byte_stream_done : std_logic := '0';
  signal cnt_calc_fin : integer range 0 to 2 := 0;
  signal cnt_calc_fin_next : integer range 0 to 2 := 0;

  -- Test 3
  signal deletion_done : std_logic := '0';

  -- ROMS
  signal address_keys : std_logic_vector(6 downto 0) := (others => '0');
  signal data_out_keys : std_logic_vector(95 downto 0);

  signal address_packet : std_logic_vector(12 downto 0) := (others => '0');
  signal data_out_packet : std_logic_vector(9 downto 0);

  signal address_delete : std_logic_vector(2 downto 0) := (others => '0');
  signal data_out_delete : std_logic_vector(95 downto 0);

begin

  Collect_Header_inst : Collect_Header
  port map(
    clk => clk,
    reset => reset,
    packet_in => packet_in,
    SoP => SoP,
    EoP => EoP,
    vld_firewall => vld_firewall,
    rdy_FIFO => rdy_FIFO, 
    rdy_hash => rdy_hash, 
    rdy_collecthdr => rdy_collecthdr,
    header_data => header_data,
    packet_forward => packet_forward, 
    vld_hdr => vld_hdr,
    vld_hdr_FIFO => vld_hdr_FIFO,
    hdr_SoP => hdr_SoP, 
    hdr_EoP => hdr_EoP 
  );
  SoP <= packet_in(1);
  EoP <= packet_in(0);
  Cuckoo_Hashing_inst : Cuckoo_Hashing
  port map(
    clk => clk, 
    reset => reset, 
    set_rule => set_rule, 
    cmd_in => cmd_in_next, 
    key_in => key_in_next,
    header_data => header_data, 
    vld_hdr => vld_hdr, 
    rdy_hash => rdy_hash, 
    vld_firewall_hash => vld_firewall_hash_next, 
    rdy_firewall_hash => rdy_firewall_hash, 
    acc_deny_hash => acc_deny_hash, 
    vld_ad_hash => vld_ad_hash,
    rdy_ad_hash => rdy_ad_hash
  );

  minfifo_inst : minfifo
  port map(
    clock => clk,
    data => data, 
    rdreq => rdreq,
    wrreq => wrreq, 
    empty => empty,
    full => full, 
    q => packet_forward_FIFO,
    usedw => usedw
  );
  vld_fifo <= not full;
  rdreq <= rdy_ad_FIFO and (not empty);
  wrreq <= vld_hdr_FIFO and (not full);
  rdy_collecthdr <= not full;
  data <= packet_forward;

  Accept_Deny_inst : Accept_Deny
  port map(
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

  prog_keys_rom_inst : prog_keys_rom
  port map(
    address => address_keys,
    data_out => data_out_keys
  );
  input_packet_rom_inst : input_packet_rom
  port map(
    address => address_packet,
    data_out => data_out_packet
  );
  delete_keys_rom_inst : delete_keys_rom
  port map(
    address => address_delete,
    data_out => data_out_delete
  );
  STATE_MEMORY_LOGIC : process (clk, reset)
  begin
    if reset = '1' then
      current_state <= setup_rulesearch;

    elsif rising_edge(clk) then
      current_state <= next_state;
      cnt_calc_fin <= cnt_calc_fin_next;
      set_rule <= set_rule_next;
      data_end <= data_end_next;
      cmd_in <= cmd_in_next;
      vld_firewall_hash <= vld_firewall_hash_next;
      key_in <= key_in_next;
      test1_fin <= test1_fin_next;
      test2_fin <= test2_fin_next;
      test3_fin <= test3_fin_next;
      deletion_done <= deletion_done_next;
      LEDR0_reg <= ledr0_next;
      LEDR0_reg <= ledr1_next;
      LEDR0_reg <= ledr2_next;
      address_keys <= address_keys_next;
      address_packet <= address_packet_next;
      address_delete <= address_delete_next;
    end if;
  end process;

  NEXT_STATE_LOGIC : process (current_state,
    done_looping,
    rdy_firewall_hash,
    vld_firewall_hash,
    data_end,
    rdy_hash,
    vld_hdr, cnt_calc_fin,
    rdy_ad_hash,
    byte_stream_done,
    deletion_done,
    rdy_fifo,
    vld_firewall,
    test1_fin_next,
    test2_fin_next,
    test3_fin_next)
  begin
    next_state <= current_state;
    cnt_calc_fin_next <= cnt_calc_fin;

    case current_state is
      when setup_rulesearch =>
        next_state <= set_keys_and_read_input_packets;
        cnt_calc_fin_next <= 0;
      when set_keys_and_read_input_packets => 
      if done_looping = '1' and rdy_firewall_hash = '1' then
        next_state <= wait_for_ready_insert;
      end if;
      next_state <= send_key;

      when wait_for_ready_insert =>
      if data_end = '1' then
        next_state <= wait_for_last_calc_to_finish;
      elsif rdy_firewall_hash = '1' and vld_firewall_hash = '1'then
        next_state <= send_key;
      end if;

      when send_key =>
      next_state <= wait_for_ready_insert;

      when terminate_insertion =>
      if not (cnt_calc_fin = 2) and rdy_firewall_hash = '1' then
        cnt_calc_fin_next <= cnt_calc_fin + 1;

  elsif (cnt_calc_fin = 2) then
    next_state <= goto_cmd_state;
  end if;

  when wait_for_last_calc_to_finish =>
  if rdy_firewall_hash = '1' then
    next_state <= terminate_insertion;
  end if;

  when goto_cmd_state =>
  if test2_fin_next = '1' and deletion_done = '1' then
    next_state <= start_byte_stream;
  elsif test2_fin_next = '1' then
    next_state <= setup_delete_key;
  else
    next_state <= start_byte_stream;
  end if;

  when start_byte_stream => 
  next_state <= comince_byte_stream;
  when comince_byte_stream =>
  if byte_stream_done = '1' then
    next_state <= terminate_match;
  elsif rdy_FIFO = '0' or vld_firewall = '0' then
    next_state <= pause_byte_stream;
  elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
    next_state <= comince_byte_stream;
  end if;

  when pause_byte_stream =>
  if rdy_FIFO = '0' or vld_firewall = '0' then
    next_state <= terminate_match;
  elsif rdy_FIFO = '1' and vld_firewall = '1' then
    next_state <= comince_byte_stream;
  end if;

  when terminate_match =>
  if test3_fin_next = '1' then
    next_state <= terminate_match;
  elsif test1_fin_next = '1' and test2_fin_next = '1' and test3_fin_next = '0' then
    next_state <= setup_rulesearch;
  else
    next_state <= reset_all;
  end if;

  -- Test 2
  when reset_all => next_state <= setup_rulesearch;

  -- Test 3
  when setup_delete_key => next_state <= delete_key;

  when delete_key => next_state <= wait_delete_key;

  when wait_delete_key =>
  if data_end = '1' then
    next_state <= terminate_delete;
  elsif rdy_firewall_hash = '1' and vld_firewall_hash = '1'then
    next_state <= delete_key;
  end if;

  when terminate_delete => next_state <= goto_cmd_state;

  when others => next_state <= setup_rulesearch;

end case;
end process;

OUTPUT_LOGIC : process (
  current_state,
  set_rule,
  data_end,
  cmd_in,
  vld_firewall_hash,
  key_in,
  test1_fin,
  test2_fin,
  test3_fin,
  deletion_done,
  data_out_keys,
  data_out_packet,
  data_out_delete,
  address_keys,
  address_packet,
  address_delete,
  ok_cnt,
  ko_cnt,
  ledr0_reg,
  ledr1_reg,
  ledr2_reg)

  
begin
  -- Default
  set_rule_next <= set_rule;
  reset <= '0';
  byte_stream_done <= '0';
  data_end_next <= data_end;
  done_looping <= '0';
  cmd_in_next <= cmd_in;
  vld_firewall_hash_next <= vld_firewall_hash;
  key_in_next <= key_in;
  vld_firewall <= '1';
  packet_in <= (others => '0');
  test1_fin_next <= test1_fin;
  test2_fin_next <= test2_fin;
  test3_fin_next <= test3_fin;
  deletion_done_next <= deletion_done;
  ledr0_next <= LEDR0_reg;
  ledr1_next <= LEDR1_reg;
  ledr2_next <= LEDR2_reg;
  address_keys_next <= address_keys;
  address_packet_next <= address_packet;
  address_delete_next <= address_delete;

  case current_state is
    when setup_rulesearch =>
      set_rule_next <= '1';
      reset <= '0';
      byte_stream_done <= '0';
      data_end_next <= '0';
      address_keys_next <= (others => '0');
      address_packet_next <= (others => '0');
      address_delete_next <= (others => '0');

    when set_keys_and_read_input_packets =>
      done_looping <= '1';
      cmd_in_next <= "01";
      vld_firewall_hash_next <= '1';

    when wait_for_ready_insert =>

    when send_key =>
      key_in_next <= data_out_keys;
      address_keys_next <= address_keys + 1;
      if address_keys = data_length_keys then
        data_end_next <= '1';
      end if;

    when terminate_insertion =>
      vld_firewall_hash_next <= '0';
      cmd_in_next <= "11";

    when wait_for_last_calc_to_finish =>

    when goto_cmd_state =>

    when start_byte_stream =>
      cmd_in_next <= "11";
      vld_firewall <= '1';

    when comince_byte_stream => 
      set_rule_next <= '0';
      packet_in <= data_out_packet;
      address_packet_next <= address_packet + 1;

      if address_packet = data_length_packet then
        byte_stream_done <= '1';
      end if;

    when pause_byte_stream =>

    when terminate_match =>
      test1_fin_next <= '1';
      if test1_fin = '1' and test2_fin = '0' then
        test2_fin_next <= '1';
      end if;

      if test2_fin = '1' and test3_fin = '0'then
        test3_fin_next <= '1';
      end if;

      if ok_cnt = "00000011" and ko_cnt = "1010110" and test1_fin = '0' then
        report "TEST 1 PASSED" severity NOTE;
        LEDR0_next <= '1';
      elsif test1_fin = '0' then
        report "TEST 1 FAILED ok = " & integer'image(to_integer(unsigned(ok_cnt))) & " ko = " & integer'image(to_integer(unsigned(ko_cnt))) severity ERROR;
      end if;

      if ok_cnt = "00000011" and ko_cnt = "1010110" and test2_fin = '0' and test1_fin = '1' then
        report "TEST 2 PASSED" severity NOTE;
        LEDR1_next <= '1';
      elsif test2_fin = '0' and test1_fin = '1' then
        report "TEST 2 FAILED ok = " & integer'image(to_integer(unsigned(ok_cnt))) & " ko = " & integer'image(to_integer(unsigned(ko_cnt))) severity ERROR;
      end if;

      if ok_cnt = "00001011" and ko_cnt = "10100111" and test3_fin = '0' and test2_fin = '1' and test1_fin = '1' then
        report "TEST 3 PASSED" severity NOTE;
        LEDR2_next <= '1';
      elsif test2_fin = '1' and test1_fin = '1' and test3_fin = '0' then
        report "TEST 3 FAILED ok = " & integer'image(to_integer(unsigned(ok_cnt))) & " ko = " & integer'image(to_integer(unsigned(ko_cnt))) severity ERROR;
      end if;
    when test_a_wrong_header =>

    when wait_for_bytestream_to_fin =>

    when reset_all =>
      reset <= '1';

    when setup_delete_key =>
      cmd_in_next <= "10";
      vld_firewall <= '1';
      data_end_next <= '0';
      vld_firewall_hash_next <= '1';

    when delete_key =>
      key_in_next <= data_out_delete;
      address_delete_next <= address_delete + 1;
      if address_delete = data_length_delete then
        data_end_next <= '1';
      end if;

    when wait_delete_key =>

    when terminate_delete =>
      vld_firewall_hash_next <= '0';
      deletion_done_next <= '1';

    when others => report "FAILURE" severity failure;

  end case;

end process;

rdy_fifo <= '1';
LEDR(0) <= test1_fin;
LEDR(1) <= test2_fin;
LEDR(2) <= test3_fin;
clk <= ADC_CLK_10;
-- CLOCK : process
-- begin
--   clk <= '1';
--   wait for 10 ns;
--   clk <= '0';
--   wait for 10 ns;

-- end process;

with (ok_cnt(3 downto 0)) select
HEX0 <=
  "0000001" when "0000",
  "1001111" when "0001",
  "0010010" when "0010",
  "0000110" when "0011",
  "1001100" when "0100",
  "0100100" when "0101",
  "0100000" when "0110",
  "0001111" when "0111",
  "0000000" when "1000",
  "0000100" when "1001",
  "0001000" when "1010",
  "1100000" when "1011",
  "1110010" when "1100",
  "1000010" when "1101",
  "0110000" when "1110",
  "0111000" when "1111";

with (ok_cnt(7 downto 4)) select
HEX1 <=
  "0000001" when "0000",
  "1001111" when "0001",
  "0010010" when "0010",
  "0000110" when "0011",
  "1001100" when "0100",
  "0100100" when "0101",
  "0100000" when "0110",
  "0001111" when "0111",
  "0000000" when "1000",
  "0000100" when "1001",
  "0001000" when "1010",
  "1100000" when "1011",
  "1110010" when "1100",
  "1000010" when "1101",
  "0110000" when "1110",
  "0111000" when "1111";

with (ko_cnt(3 downto 0)) select
HEX3 <=
  "0000001" when "0000",
  "1001111" when "0001",
  "0010010" when "0010",
  "0000110" when "0011",
  "1001100" when "0100",
  "0100100" when "0101",
  "0100000" when "0110",
  "0001111" when "0111",
  "0000000" when "1000",
  "0000100" when "1001",
  "0001000" when "1010",
  "1100000" when "1011",
  "1110010" when "1100",
  "1000010" when "1101",
  "0110000" when "1110",
  "0111000" when "1111";

with (ko_cnt(7 downto 4)) select
HEX4 <=
  "0000001" when "0000",
  "1001111" when "0001",
  "0010010" when "0010",
  "0000110" when "0011",
  "1001100" when "0100",
  "0100100" when "0101",
  "0100000" when "0110",
  "0001111" when "0111",
  "0000000" when "1000",
  "0000100" when "1001",
  "0001000" when "1010",
  "1100000" when "1011",
  "1110010" when "1100",
  "1000010" when "1101",
  "0110000" when "1110",
  "0111000" when "1111";
HARDWARE_OUTPUT : process (clk, reset)
begin
  if reset = '1' then
    --packet_in <= (others => '0');
  elsif rising_edge(clk) then
    if data_firewall /= "0000000000" then
      LEDR(9) <= '1';
    else
      LEDR(9) <= '0';
    end if;
  end if;
end process;

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