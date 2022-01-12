library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all; 
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity Collect_Header is
    port (
      clk : in std_logic;
      reset : in std_logic;
      packet_in : in std_logic_vector (7 downto 0);
      SoP : in std_logic;
      EoP : in std_logic;
      vld : in std_logic;
      ready_FIFO : in std_logic;
      ready_hash : in std_logic;
  
      ready_hdr : out std_logic;
      header_data : out std_logic_vector (95 downto 0); 
      packet_forward : out std_logic_vector (7 downto 0);
      vld_hdr : out std_logic;
      hdr_SoP : out std_logic;
      hdr_EoP :out std_logic
  
    );
  end entity;

architecture Collect_header_arch of Collect_Header is

  type State_type is (idle, packet_next, collect_header, stop_wait, forward_header);
  signal current_state, next_state : State_type;
  
  -- signal declarations
  signal srcaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store source address here
  signal destaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store destination address her
  signal srcport : std_logic_vector (15 downto 0) := x"0000"; -- fang source ports her
  signal destport : std_logic_vector (15 downto 0) := x"0000"; -- fang destsource ports her
  signal header_data_store : std_logic_vector (95 downto 0) := x"000000000000000000000000";
  
  signal bytenum : integer := 0;
  
  signal store0 : std_logic_vector (7 downto 0) := x"00";
  signal store1 : std_logic_vector (7 downto 0) := x"00";
  signal store2 : std_logic_vector (7 downto 0) := x"00";
  signal store3 : std_logic_vector (7 downto 0) := x"00";
  

  --signal readvld_hdr : std_logic := '1';
  --signal forwardSoP : std_logic;
  --signal forwardEoP : std_logic;

  signal header_sent : std_logic := '0';
  signal bytenum_next : integer := 0;
  signal wipe_cnt : std_logic;
  --signal doneloop : std_logic;
  
  

begin

  STATE_MEMORY_LOGIC : process (clk, reset)
  begin
    if reset = '1' then
      current_state <= idle;
  elsif rising_edge(clk) then
      current_state <= next_state;
      bytenum <= bytenum_next;
      if wipe_cnt = '1' then
        bytenum <= 0;
      end if;
  end if ;
  end process;

  NEXT_STATE_LOGIC : process (current_state, vld, ready_hash, ready_FIFO, SoP, EoP, bytenum_next, header_sent)
  begin
    next_state <= current_state;
    case current_state is

      when idle =>
       if ready_hash = '1' and ready_FIFO = '1' and EoP = '1' and vld = '1' then
          next_state <= packet_next;
      end if;

      when packet_next =>

        if ready_FIFO = '1' and ready_hash = '1' and bytenum_next >= 10 and bytenum_next <= 23 and vld = '1' then
            next_state <= collect_header;
          elsif bytenum_next >= 24 and SoP = '0' and header_sent = '0' then
            next_state <= forward_header;
          elsif ready_FIFO = '1' and ready_hash = '1' and vld = '1' then
          next_state <= packet_next;
          elsif ready_FIFO = '0' or ready_hash = '0' or vld = '0' then
            next_state <= stop_wait;
          --elsif doneloop = '1' then
           -- next_state <= idle;
        end if;

      when stop_wait => 

        if ready_FIFO = '0' or ready_hash = '0' or vld = '0' then
          next_state <= stop_wait;
          elsif ready_FIFO = '1' and ready_hash = '1' and bytenum_next >= 10 and bytenum_next <= 23 and vld = '1' then
            next_state <= collect_header;
          elsif ready_FIFO = '1' and ready_hash = '1' and bytenum_next >= 23 and vld = '1' and header_sent = '0' then
          next_state <= forward_header;

        elsif ready_FIFO = '1' and ready_hash = '1' and vld = '1' then
          next_state <= packet_next;            
        end if;
      
      when collect_header =>
        if ready_FIFO = '0' or ready_hash = '0' or vld = '0' then
         next_state <= stop_wait;
        elsif ready_FIFO = '1' and ready_hash = '1' and vld = '1' and header_sent = '0' and bytenum_next <=23 then
          next_state <= collect_header;
        elsif ready_FIFO = '1' and ready_hash = '1' and vld = '1' then
        next_state <= forward_header;
        end if;

      when forward_header =>
      if ready_FIFO = '1' and ready_hash = '1' and vld = '1' and header_sent = '1' then
        next_state <= packet_next;
      elsif (ready_FIFO = '0' or ready_hash = '0' or vld = '0') and header_sent = '0' then
          next_state <= stop_wait;
      else
        next_state <= forward_header;
      end if;

      when others =>
        next_state <= idle;
    end case;
  end process;
  
  OUTPUT_LOGIC : process (current_state, SoP, EoP, bytenum)
  begin
    bytenum_next <= bytenum;
    case current_state is
      when idle =>
        -- Do nothing

        when forward_header =>
          header_data <= srcaddr & destaddr & srcport & destport;
          header_sent <= '1';
          packet_forward <= packet_in;
          

      when packet_next =>
          if SoP = '1' then
            bytenum_next <= 0;
            header_sent <= '0';
            srcaddr <= x"00000000";
            destaddr <= x"00000000";
            srcport <= x"0000";
            destport <= x"0000";
            store1 <= x"00";
            store2 <= x"00";
            store3 <= x"00";
            header_data <= x"000000000000000000000000";
            header_data_store <= x"000000000000000000000000";
          end if;
          wipe_cnt <= SoP;
          bytenum_next <= bytenum +1;
          hdr_SoP <= SoP;
          packet_forward <= packet_in;
          hdr_EoP <= EoP;
          --doneloop <= doneloops;

      when collect_header =>
          bytenum_next <= bytenum +1;
          packet_forward <= packet_in;

          if bytenum_next >= 11 and bytenum_next <= 14 then -- SRCADDR
            if bytenum_next = 11 then
              store1 <= packet_in;
            end if;
            if bytenum_next = 12 then
              store2 <= packet_in;
            end if;
            if bytenum_next = 13 then
              store3 <= packet_in;
            end if;

              srcaddr <= store1 & store2 & store3 & packet_in;
          end if; 
          
          if bytenum_next >= 15 and bytenum_next <= 18 then -- DESTADDR
            if bytenum_next = 15 then
              store1 <= packet_in;
            end if;
            if bytenum_next = 16 then
              store2 <= packet_in;
            end if;
            if bytenum_next = 17 then
              store3 <= packet_in;
            end if;
            
            destaddr <= store1 & store2 & store3 & packet_in;
          end if;
    
          if bytenum_next >= 19 and bytenum_next <= 20 then -- SRCPORT
            if bytenum_next = 19 then
              store1 <= packet_in;
            end if;
            srcport <= store1 & packet_in;
          end if;
    
          if bytenum_next >= 21 and bytenum_next <= 22 then -- DESTPORT
            if bytenum_next = 21 then
              store1 <= packet_in;
            end if;
            destport <= store1 & packet_in;
          end if;
    
          if bytenum_next = 23 then
            header_data_store <= srcaddr & destaddr & srcport & destport;
          end if;

          when stop_wait =>
          -- Wait for signals to pop up

      when others =>
      report "ERROR IN OUTPUT LOGIC" severity failure;

    end case;

  end process;
end architecture;

