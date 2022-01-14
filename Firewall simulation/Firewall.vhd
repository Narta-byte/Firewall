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
      rdreq : in STD_LOGIC; -- Michael, hjælp!
      wrreq : in STD_LOGIC; --Michael, hjælp!
      empty : out STD_LOGIC; --Michail, hilfe!
      full : out STD_LOGIC;--Michail, hilfe!
      q : out STD_LOGIC_VECTOR (9 DOWNTO 0);--Michail, hilfe!
      usedw : out STD_LOGIC_VECTOR (7 DOWNTO 0)--Michail, hilfe!
    );
  end component;

  component Accept_Deny
          port (
          clk : in std_logic; --yes
          reset : in std_logic; --yes
          packet_forward_FIFO : in std_logic_vector(9 downto 0); --yes
          --FIFO_sop : in std_logic; 
          --FIFO_eop : in std_logic; 
          vld_fifo : in std_logic; --yes
          acc_deny_hash : in std_logic; --yes
          vld_ad_hash : in std_logic; --yes
          rdy_ad_hash : out std_logic; --yes
          rdy_ad_FIFO : out std_logic; -- micheal hjælp
          data_firewall : out std_logic_vector(9 downto 0); --yes
          --out_sop : out std_logic; 
          --out_eop : out std_logic;
          ok_cnt : out std_logic_vector(8 downto 0); --yes ændres måske senere
          ko_cnt : out std_logic_vector(8 downto 0) --yes ændres måske senere
        );
      end component;
  -- component Accept_Deny
  --     port (
  --     clk : in std_logic;
  --     reset : in std_logic;
  --     packet_forward_FIFO : in std_logic_vector(9 downto 0);
  --     --FIFO_sop : in std_logic;
  --     --FIFO_eop : in std_logic;
  --     vld_fifo : in std_logic;
  --     acc_deny : in std_logic;
  --     vld_ad_hash : in std_logic;
  --     rdy_ad_hash : out std_logic;
  --     rdy_ad_FIFO : out std_logic;
  --     data_firewall : out std_logic_vector(9 downto 0);
  --     ok_cnt : out std_logic_vector(8 downto 0);
  --     ko_cnt : out std_logic_vector(8 downto 0)
  --   );
  -- end component;
 
 
      -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

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
  signal header_data : std_logic_vector (95 downto 0) := x"000000000000000000000000";
  signal packet_forward : std_logic_vector (9 downto 0) := "0000000000";
  signal vld_hdr : std_logic := '0';
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


  --accept deny
  --signal clk : std_logic;
  --signal reset : std_logic;
  signal packet_forward_FIFO : std_logic_vector(9 downto 0) := "0000000000";
  signal FIFO_sop : std_logic; --
  signal FIFO_eop : std_logic; --
  signal vld_fifo : std_logic; -- micheal hjælp
  --signal acc_deny_hash : std_logic; 
  --signal vld_ad_hash : std_logic; 
  --signal rdy_ad_hash : std_logic;
  signal rdy_ad_FIFO : std_logic; -- micheal hjælp
  signal data_firewall : std_logic_vector(9 downto 0) := "0000000000";
  signal ok_cnt : std_logic_vector(8 downto 0) := "000000000";
  signal ko_cnt : std_logic_vector(8 downto 0) := "000000000";

    -- cuckoo hash tb copy paste
  type State_type is (setup_rulesearch,
                      set_keys_and_read_input_packets,wait_for_ready_insert,
                      send_key,terminate_insertion,
                      wait_for_last_calc_to_finish,
                      goto_cmd_state,
                      start_byte_stream,
                      pause_byte_stream,
                      comince_byte_stream_to_accept,
                      pause_byte_stream_to_accept,
                      comince_byte_stream,

                      terminate_match,
                      test_a_wrong_header,
                      wait_for_bytestream_to_fin
                        );
  signal current_state, next_state : State_type;

  signal data_end,done_looping,last_rdy,calc_is_done : std_logic :='0';


  -- file management
  constant data_length_keys : integer := 160;
  constant data_length_packet : integer := 38689;
  

  --output logic signals 
  signal cnt : integer;
  type key_array is array (0 to data_length_keys) of std_logic_vector(95 downto 0);
  signal key_array_sig : key_array;

  type packet_array is array (0 to data_length_packet) of std_logic_vector(9 downto 0);
  signal packet_array_sig : packet_array;
  
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
  
  
  --signals for ac
  
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
    clk => clk, --yes
    reset => reset, --yes
    packet_in => packet_in, --yes
    SoP => SoP, --yes
    EoP => EoP, --yes
    vld_firewall => vld_firewall, --yes
    rdy_FIFO => rdy_FIFO, -- skal vare sit eget signal
    rdy_hash => rdy_hash, -- vi har signal
    rdy_collecthdr => rdy_collecthdr, --yes
    header_data => header_data, --yes burde virke
    packet_forward => packet_forward, -- kan ikke implementeres pt
    vld_hdr => vld_hdr, -- yes
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
    wrreq <= vld_hdr and (not full);
    rdy_collecthdr <= not full;
    FIFO_sop <= q(8);
    FIFO_eop <= q(9);
    data <=  packet_forward;
    --q <= packet_forward_FIFO;
    --
    Accept_Deny_inst : Accept_Deny
        port map (
          clk => clk,
          reset => reset,
          packet_forward_FIFO => packet_forward_FIFO,
          --FIFO_sop => FIFO_sop,
          --FIFO_eop => FIFO_eop,
          vld_fifo => vld_fifo,
          acc_deny_hash => acc_deny_hash,
          vld_ad_hash => vld_ad_hash,
          rdy_ad_hash => rdy_ad_hash,
          rdy_ad_FIFO => rdy_ad_FIFO,
          data_firewall => data_firewall,
          --out_sop => out_sop,
          --out_eop => out_eop,
          ok_cnt => ok_cnt,
          ko_cnt => ko_cnt
        );
    

        



     STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= setup_rulesearch;
        elsif rising_edge(clk) then
            current_state <= next_state;
            bytenumber <= nextbytenum;
        end if ;
    end process;  
    
    NEXT_STATE_LOGIC : process (current_state, done_looping, 
                              rdy_firewall_hash, vld_firewall_hash,
                              data_end,calc_is_done,
                              rdy_hash,
                              vld_hdr, cnt_calc_fin,
                              rdy_ad_hash)
  begin
    next_state <= current_state; -- måske sus
      case current_state is
        when setup_rulesearch =>
          next_state <= set_keys_and_read_input_packets;

       

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
          end if;

        when goto_cmd_state => next_state <= start_byte_stream;

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
          elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
            next_state <= comince_byte_stream;
        end if;
        

        when terminate_match => next_state <= terminate_match;        
        
        when others =>
          next_state <= setup_rulesearch;
      end case;
  end process;

  OUTPUT_LOGIC : process (current_state, bytenumber)
  file input : TEXT open READ_MODE is "keys_to_be_programmed.txt";
  variable current_read_line_keys : line;
  variable std_logic_vector_reader : std_logic_vector(95 downto 0);
  
  file input_packet : TEXT open READ_MODE is "Input_packet.txt"; 
  variable current_read_line	: line;
  variable current_read_field	: std_logic_vector (7 downto 0);
  variable current_bit_read_SoP : std_logic_vector (0 downto 0);
  variable current_bit_read_EoP : std_logic_vector (0 downto 0);
  variable start_of_data_Reader : std_logic;

  variable var_cnt : integer:=0;
  
  file output : text open WRITE_MODE is "DEBUG_OUTPUT.txt";
  variable write_line : line;
  begin
    nextbytenum <= bytenumber;
      case current_state is
      when setup_rulesearch => 
        set_rule <= '1';
	      cnt <= 0;
      
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
              --hex12 <= current_read_field;
              
              read(current_read_line, current_bit_read_SoP);
              --bits1 <= current_bit_read;
              -- if current_bit_read_SoP = "1" then
              --   SoP <= '1';
              -- else
              --   SoP <= '0';
              -- end if;
              
              read(current_read_line, current_bit_read_EoP);
              --bits2<= current_bit_read;
              -- if current_bit_read_EoP = "1" then
              --   EoP <= '1';
              -- else
              --   EoP <= '0';
              -- end if;
                
              --packet_in <= hex12 & bits1 & bits2;
              --entire_packet <= current_read_field & current_bit_read_SoP & current_bit_read_EoP;
              packet_array_sig(i) <= current_read_field & current_bit_read_SoP & current_bit_read_EoP;
              packet_data <= hex12;
                    
            else
              doneloop <= '1';
            end if;
          end loop ; -- READ_INPUT_PACKET



        done_looping <= '1';
        cmd_in <= "01";
        vld_firewall_hash <= '1';

      when wait_for_ready_insert => 
            
      when send_key =>
          key_in <= key_array_sig(cnt);
          cnt <= cnt+1;

          if cnt = data_length_keys 
      
      then
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
          
      when comince_byte_stream => --packet_input 
      set_rule <= '0';
      nextbytenum <= bytenumber +1;
      packet_in <= packet_array_sig(nextbytenum);
        if nextbytenum = data_length_packet-1 then
          byte_stream_done <= '1';
        end if ;
      
      when pause_byte_stream =>              

      when terminate_match => --vld_hdr <= '0';

      when test_a_wrong_header => 
        --header_data <= "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" & "00011111";

      when wait_for_bytestream_to_fin => 
      

      when others => report "FAILURE" severity failure;
          
      end case;
   
  end process;

  TestInputs : process 
  begin
    rdy_FIFO <= '1'; wait for 1390 ns;
--    ready_FIFO <= '1'; wait for 10000 ns;
    rdy_FIFO <= '0'; wait for 10 ns;  
    rdy_FIFO <= '1'; wait;

  end process;

  testvld : process 
  begin
    vld_firewall <= '1'; wait;
    
  end process;


    end; 
    
 
      
    


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



