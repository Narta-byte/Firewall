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
end entity;

architecture Collect_header_arch of Collect_Header is

  type State_type is (wait_for_packetstart, packet_next, collect_header, stop_wait, forward_header);
  signal current_state, next_state : State_type;

  -- signal declarations
  signal srcaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store source address here
  signal destaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store destination address her
  signal srcport : std_logic_vector (15 downto 0) := x"0000"; -- fang source ports her
  signal destport : std_logic_vector (15 downto 0) := x"0000"; -- fang destsource ports her
  signal header_data_store : std_logic_vector (95 downto 0) := x"000000000000000000000000";

  signal srcaddr_next : std_logic_vector(31 downto 0);
  signal destaddr_next : std_logic_vector(31 downto 0);
  signal srcport_next : std_logic_vector(15 downto 0);
  signal destport_next : std_logic_vector(15 downto 0);
  signal header_data_store_next : std_logic_vector (95 downto 0) := x"000000000000000000000000";
  


  signal bytenum : integer := 0;

  constant collect_start: integer := 11;
  
  signal store1 : std_logic_vector (7 downto 0) := x"00";
  signal store2 : std_logic_vector (7 downto 0) := x"00";
  signal store3 : std_logic_vector (7 downto 0) := x"00";

  signal store1_next : std_logic_vector (7 downto 0);
  signal store2_next : std_logic_vector (7 downto 0);
  signal store3_next : std_logic_vector (7 downto 0);
  signal header_sent_next : std_logic;

  signal header_sent : std_logic := '0';
  signal bytenum_next : integer := 0;
  signal packetnum : integer := 0;
  signal packetnum_next : integer := 0;
  

  signal packetSop : std_logic;
  signal packetEop : std_logic;
  

begin

  STATE_MEMORY_LOGIC : process (clk, reset)
  begin
    if reset = '1' then
      current_state <= wait_for_packetstart;
      FILE_CLOSE (output);
      FILE_OPEN (output, "headerdata.txt", WRITE_MODE);
    elsif rising_edge(clk) then
      current_state <= next_state;
      bytenum <= bytenum_next;
      packetnum <= packetnum_next;
      store1 <= store1_next;
      store2 <= store2_next;
      store3 <= store3_next;
      header_sent <= header_sent_next;
      srcaddr <= srcaddr_next;
      destaddr <= destaddr_next;
      srcport <= srcport_next;
      destport <= destport_next;
      header_data_store <= header_data_store_next;

    end if;
  end process;

  NEXT_STATE_LOGIC : process (current_state, vld_firewall, rdy_hash, rdy_FIFO, SoP, EoP, bytenum_next, header_sent_next)
  begin
    next_state <= current_state;
    case current_state is

      when wait_for_packetstart =>
        if rdy_hash = '1' and rdy_FIFO = '1' and SoP = '1' and vld_firewall = '1' then
          next_state <= packet_next;
        end if;


      when packet_next =>
        if rdy_FIFO = '1' and rdy_hash = '1' and bytenum_next >= collect_start and bytenum_next <= collect_start + 13 and vld_firewall = '1' then
          next_state <= collect_header;
        elsif bytenum_next >= collect_start + 14 and SoP = '0' and header_sent_next = '0' then
          next_state <= forward_header;
        elsif rdy_FIFO = '1' and vld_firewall = '1' then
          next_state <= packet_next;
        elsif rdy_FIFO = '0' or vld_firewall = '0' then
          next_state <= stop_wait;
        end if;


      when stop_wait =>
        if rdy_FIFO = '0' or rdy_hash = '0' or vld_firewall = '0' then
          next_state <= stop_wait;
        elsif rdy_FIFO = '1' and rdy_hash = '1' and bytenum_next >= collect_start -1 and bytenum_next <= collect_start +12 and vld_firewall = '1' then
          next_state <= collect_header;
        elsif rdy_FIFO = '1' and rdy_hash = '1' and bytenum_next >= collect_start +12 and vld_firewall = '1' and header_sent_next = '0' then 
          next_state <= forward_header;

        elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
          next_state <= packet_next;
        end if;


      when collect_header =>
        if rdy_FIFO = '0' or rdy_hash = '0' or vld_firewall = '0' then
          next_state <= stop_wait;
        elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' and header_sent_next = '0' and bytenum_next <= collect_start +13 then
          next_state <= collect_header;
        elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
          next_state <= forward_header;
        end if;


      when forward_header =>
        if rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' and header_sent_next = '1' then
          next_state <= packet_next;
        elsif (rdy_FIFO = '0' or rdy_hash = '0' or vld_firewall = '0') and header_sent_next = '0' then
          next_state <= stop_wait;
        else
          next_state <= forward_header;
        end if;


      when others =>
        next_state <= wait_for_packetstart;
    end case;
  end process;

  OUTPUT_LOGIC : process (current_state, SoP, EoP, bytenum, packetnum, store1, store2, store3, header_sent, srcaddr, destaddr, srcport, destport,header_data_store,packet_in)
    file output : TEXT open WRITE_MODE is "headerdata.txt";
    variable current_write_line : line;
  begin
     bytenum_next <= bytenum;
     packetnum_next <= packetnum;
     srcaddr_next <= srcaddr;
     destaddr_next <= destaddr;
     srcport_next <=  srcport;
     destport_next <=  destport;
     header_data_store_next <= header_data_store;
     store1_next <= store1;
     store2_next <= store2;
     store3_next <= store3;
     header_data <= x"000000000000000000000000";
     --vld_hdr <= '0';
     header_sent_next <= header_sent;
     hdr_SoP <= '0';
     hdr_EoP <= '0';
     --vld_hdr_FIFO <= '0';
     --rdy_collecthdr <= '1';
     packet_forward <= packet_in;

    case current_state is

      when wait_for_packetstart =>
      if SoP = '1' then
        packet_forward <= packet_in;
        bytenum_next <= bytenum + 1;
        packetnum_next <= packetnum + 1;
        --bytenum_next <= 0;

      end if;
        -- Do nothing

      when forward_header =>
        vld_hdr <= '1';
        vld_hdr_FIFO <= '1';
        header_data <= header_data_store;
        header_sent_next <= '1';
        packet_forward <= packet_in;
        --rdy_collecthdr <= '0';

        write(current_write_line, header_data_store);
        writeline(output, current_write_line);

      when packet_next =>
        if SoP = '1' then
          header_sent_next <= '0';
          srcaddr_next <= x"00000000";
          destaddr_next <= x"00000000";
          srcport_next <= x"0000";
          destport_next <= x"0000";
          store1_next <= x"00";
          store2_next <= x"00";
          store3_next <= x"00";
          header_data <= x"000000000000000000000000";
          header_data_store_next <= x"000000000000000000000000";
          bytenum_next <= 0;
          packetnum_next <= 0;

          if packetnum /= 1 then
          packetnum_next <= packetnum + 1;
          --bytenum_next <= 0;            
          end if;
        end if;
        --rdy_collecthdr <= '1';
         if SoP = '1' then
           bytenum_next <= 0;
         else
          bytenum_next <= bytenum +1;
         end if;
        hdr_SoP <= SoP;
        packet_forward <= packet_in;
        hdr_EoP <= EoP;
        vld_hdr <= '0';
        vld_hdr_FIFO <= '1';
        rdy_collecthdr <= '1';

        --rdy_collecthdr <= '1';

      when collect_header =>
        vld_hdr_FIFO <= '1';
        bytenum_next <= bytenum + 1;
        packet_forward <= packet_in;
        --rdy_collecthdr <= '1';

        if bytenum >= collect_start +1 and bytenum <= collect_start +4 then -- SRCADDR
          if bytenum = collect_start +1 then
            store1_next <= packet_in (9 downto 2);
          end if;
          if bytenum = collect_start +2 then
            store2_next <= packet_in (9 downto 2);
          end if;
          if bytenum = collect_start +3 then
            store3_next <= packet_in (9 downto 2);
          end if;

          srcaddr_next <= store1 & store2 & store3 & packet_in(9 downto 2);
        end if;

        if bytenum >= collect_start +5 and bytenum <= collect_start +9 then -- DESTADDR
          if bytenum = collect_start +6 then
            store1_next <= packet_in(9 downto 2);
          end if;
          if bytenum = collect_start +7 then
            store2_next <= packet_in(9 downto 2);
          end if;
          if bytenum = collect_start +8 then
            store3_next <= packet_in(9 downto 2);
          end if;

          destaddr_next <= store1 & store2 & store3 & packet_in(9 downto 2);
        end if;

        if bytenum >= collect_start +9 and bytenum <= collect_start +10 then -- SRCPORT
          if bytenum = collect_start +9 then
            store1_next <= packet_in(9 downto 2);
          end if;
          srcport_next <= store1 & packet_in(9 downto 2);
        end if;

        if bytenum >= collect_start +11 and bytenum <= collect_start +12 then -- DESTPORT
          if bytenum = collect_start +11 then
            store1_next <= packet_in(9 downto 2);
          end if;
          destport_next <= store1 & packet_in(9 downto 2);
        end if;

        if bytenum = collect_start +13 then
          header_data_store_next <= srcaddr & destaddr & srcport & destport;
        end if;

      when stop_wait =>
      --rdy_collecthdr <= '0';
        -- Wait for signals to pop up

      when others =>
        report "ERROR IN OUTPUT LOGIC" severity failure;

    end case;

  end process;
end architecture;


-- library IEEE;
-- library std;
-- use IEEE.std_logic_1164.all;
-- use IEEE.numeric_std.all;
-- use IEEE.numeric_std_unsigned.all;
-- use std.textio.all;
-- use STD.textio.all;
-- use IEEE.std_logic_textio.all; 

-- entity Collect_Header is
--   port (
--     clk : in std_logic;
--     reset : in std_logic;
--     packet_in : in std_logic_vector (9 downto 0);
--     SoP : in std_logic;
--     EoP : in std_logic;
--     vld_firewall : in std_logic;
--     rdy_FIFO : in std_logic;
--     rdy_hash : in std_logic;

--     rdy_collecthdr : out std_logic;
--     header_data : out std_logic_vector (95 downto 0);
--     packet_forward : out std_logic_vector (9 downto 0);
--     vld_hdr : out std_logic;
--     vld_hdr_FIFO : out std_logic;
--     hdr_SoP : out std_logic;
--     hdr_EoP : out std_logic

--   );
-- end entity;

-- architecture Collect_header_arch of Collect_Header is

--   type State_type is (wait_for_packetstart, packet_next, collect_header, stop_wait, forward_header);
--   signal current_state, next_state : State_type;

--   -- signal declarations
--   signal srcaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store source address here
--   signal destaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store destination address her
--   signal srcport : std_logic_vector (15 downto 0) := x"0000"; -- fang source ports her
--   signal destport : std_logic_vector (15 downto 0) := x"0000"; -- fang destsource ports her
--   signal header_data_store : std_logic_vector (95 downto 0) := x"000000000000000000000000";

--   signal bytenum : integer := 0;

--   signal store0 : std_logic_vector (7 downto 0) := x"00";
--   signal store1 : std_logic_vector (7 downto 0) := x"00";
--   signal store2 : std_logic_vector (7 downto 0) := x"00";
--   signal store3 : std_logic_vector (7 downto 0) := x"00";

--   signal header_sent : std_logic := '0';
--   signal bytenum_next : integer := 0;
--   signal packet_num : integer := 0;

--   signal packetSop : std_logic;
--   signal packetEop : std_logic;
--   signal wipe_cnt : std_logic;

--   --signal doneloop : std_logic; 

-- begin

--   STATE_MEMORY_LOGIC : process (clk, reset)
--   begin
--     if reset = '1' then
--       current_state <= wait_for_packetstart;
--       FILE_CLOSE (output);
--       FILE_OPEN (output, "headerdata.txt", WRITE_MODE);
--     elsif rising_edge(clk) then
--       current_state <= next_state;
--       bytenum <= bytenum_next;
--       if wipe_cnt = '1' then
--         bytenum <= 0;
--       end if;

--       --     if FILE_CLOSE (output, "headerdata.txt", WRITE_MODE) then
--       --   FILE_OPEN (output, "headerdata.txt", WRITE_MODE);
--       -- end if;
--     end if;
--   end process;

--   NEXT_STATE_LOGIC : process (current_state, vld_firewall, rdy_hash, rdy_FIFO, SoP, EoP, bytenum_next, header_sent)
--   begin
--     next_state <= current_state;
--     case current_state is

--       when wait_for_packetstart =>
--         if rdy_hash = '1' and rdy_FIFO = '1' and SoP = '1' and vld_firewall = '1' then
--           next_state <= packet_next;
          
--         end if;

--       when packet_next =>

--         if rdy_FIFO = '1' and rdy_hash = '1' and bytenum_next >= 12 and bytenum_next <= 25 and vld_firewall = '1' then
--           next_state <= collect_header;
--         elsif bytenum_next >= 26 and SoP = '0' and header_sent = '0' then
--           next_state <= forward_header;
--         elsif rdy_FIFO = '1' and vld_firewall = '1' then
--           next_state <= packet_next;
--           elsif rdy_FIFO = '1' and vld_firewall = '1' and header_sent = '1' then
--           next_state <= packet_next;
--         elsif rdy_FIFO = '0' or vld_firewall = '0' then
--           next_state <= stop_wait;
--         end if;

--       when stop_wait =>

--         if rdy_FIFO = '0' or rdy_hash = '0' or vld_firewall = '0' then
--           next_state <= stop_wait;
--         elsif rdy_FIFO = '1' and rdy_hash = '1' and bytenum_next >= 11 and bytenum_next <= 24 and vld_firewall = '1' then
--           next_state <= collect_header;
--         elsif rdy_FIFO = '1' and rdy_hash = '1' and bytenum_next >= 24 and vld_firewall = '1' and header_sent = '0' then 
--           next_state <= forward_header;

--         elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
--           next_state <= packet_next;
--         end if;

--       when collect_header =>
--         if rdy_FIFO = '0' or rdy_hash = '0' or vld_firewall = '0' then
--           next_state <= stop_wait;
--         elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' and header_sent = '0' and bytenum_next <= 25 then
--           next_state <= collect_header;
--         elsif rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' then
--           next_state <= forward_header;
--         end if;

--       when forward_header =>
--         if rdy_FIFO = '1' and rdy_hash = '1' and vld_firewall = '1' and header_sent = '1' then
--           next_state <= packet_next;
--         elsif (rdy_FIFO = '0' or rdy_hash = '0' or vld_firewall = '0') and header_sent = '0' then
--           next_state <= stop_wait;
--         else
--           next_state <= forward_header;
--         end if;

--       when others =>
--         next_state <= wait_for_packetstart;
--     end case;
--   end process;

--   OUTPUT_LOGIC : process (current_state, SoP, EoP, bytenum)
--     file output : TEXT open WRITE_MODE is "headerdata.txt";
--     variable current_write_line : line;

--   begin
--     bytenum_next <= bytenum;
--     case current_state is
--       when wait_for_packetstart =>
--       if SoP = '1' then
--         packet_forward <= packet_in;
--         bytenum_next <= bytenum + 1;
--       end if;
--         -- Do nothing

--       when forward_header =>
--         --header_data <= srcaddr & destaddr & srcport & destport;
--         header_data <= header_data_store;
--         header_sent <= '1';
--         packet_forward <= packet_in;
--         vld_hdr <= '1';
        

--         write(current_write_line, header_data_store);
--         writeline(output, current_write_line);

--       when packet_next =>
--         if SoP = '1' then
--           bytenum_next <= 0;
--           header_sent <= '0';
--           srcaddr <= x"00000000";
--           destaddr <= x"00000000";
--           srcport <= x"0000";
--           destport <= x"0000";
--           store1 <= x"00";
--           store2 <= x"00";
--           store3 <= x"00";
--           header_data <= x"000000000000000000000000";
--           header_data_store <= x"000000000000000000000000";
--           --ready_collecthdr <= '0';
--           packet_num <= packet_num + 1;
--         end if;
--         wipe_cnt <= SoP;
--         bytenum_next <= bytenum + 1;
--         hdr_SoP <= SoP;
--         packet_forward <= packet_in;
--         hdr_EoP <= EoP;
--         vld_hdr <= '0';
--         vld_hdr_FIFO <= '1';
--         rdy_collecthdr <= '1';

--       when collect_header =>
--         bytenum_next <= bytenum + 1;
--         packet_forward <= packet_in;

--         if bytenum_next >= 13 and bytenum_next <= 16 then -- SRCADDR
--           if bytenum_next = 13 then
--             store1 <= packet_in (9 downto 2);
--           end if;
--           if bytenum_next = 14 then
--             store2 <= packet_in (9 downto 2);
--           end if;
--           if bytenum_next = 15 then
--             store3 <= packet_in (9 downto 2);
--           end if;

--           srcaddr <= store1 & store2 & store3 & packet_in(9 downto 2);
--         end if;

--         if bytenum_next >= 17 and bytenum_next <= 20 then -- DESTADDR
--           if bytenum_next = 17 then
--             store1 <= packet_in(9 downto 2);
--           end if;
--           if bytenum_next = 18 then
--             store2 <= packet_in(9 downto 2);
--           end if;
--           if bytenum_next = 19 then
--             store3 <= packet_in(9 downto 2);
--           end if;

--           destaddr <= store1 & store2 & store3 & packet_in(9 downto 2);
--         end if;

--         if bytenum_next >= 21 and bytenum_next <= 22 then -- SRCPORT
--           if bytenum_next = 21 then
--             store1 <= packet_in(9 downto 2);
--           end if;
--           srcport <= store1 & packet_in(9 downto 2);
--         end if;

--         if bytenum_next >= 23 and bytenum_next <= 24 then -- DESTPORT
--           if bytenum_next = 23 then
--             store1 <= packet_in(9 downto 2);
--           end if;
--           destport <= store1 & packet_in(9 downto 2);
--         end if;

--         if bytenum_next = 25 then
--           header_data_store <= srcaddr & destaddr & srcport & destport;
--         end if;

--       when stop_wait =>
--       rdy_collecthdr <= '1';
--         -- Wait for signals to pop up

--       when others =>
--         report "ERROR IN OUTPUT LOGIC" severity failure;

--     end case;

--   end process;
-- end architecture;