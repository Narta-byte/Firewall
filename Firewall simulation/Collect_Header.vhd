library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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
    -- vld_hdr : in std_logic | for test.
    vld_hdr : out std_logic;
    hdr_SoP : out std_logic;
    hdr_EoP :out std_logic

  );
end entity;

architecture Collect_Header_arch of Collect_Header is

  -- type Statype is (idle, collect_header, );

  -- signal declarations
  signal srcaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store source address here
  signal destaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store destination address her
  signal srcport : std_logic_vector (15 downto 0) := x"0000"; -- fang source ports her
  signal destport : std_logic_vector (15 downto 0) := x"0000"; -- fang destsource ports her
  signal header_data_store : std_logic_vector (95 downto 0) := x"000000000000000000000000";
  
  signal iter : integer := 0;
  
  signal store0 : std_logic_vector (7 downto 0) := x"00";
  signal store1 : std_logic_vector (7 downto 0) := x"00";
  signal store2 : std_logic_vector (7 downto 0) := x"00";

  signal readvld_hdr : std_logic;
  signal forwardSoP : std_logic;
  signal forwardEoP : std_logic;

  signal headerinfo : std_logic;

  signal rhash : std_logic;
  signal rfifo : std_logic;
  signal rhdr : std_logic;
  
  
  
  

  -- signal rdy_FIFO : std_logic;
  -- signal rdy_hash : std_logic;

begin

  Collect : process (clk, reset)  
  begin
    if reset = '1' then
      srcaddr <= x"00000000";
      destaddr <= x"00000000";
      srcport <= x"0000";
      destport <= x"0000";
      -- rdy_fifo <='0';
      -- rdy_hash <= '0';


      iter <= 0;
    elsif Rising_edge(clk) then
      
      iter <= iter + 1;
      hdr_SoP <= SoP;
      hdr_EoP <= EoP;

      rhash <= '1';
      rFIFO <= '1';


      if EoP = '1' then
        vld_hdr <= '0';
        readvld_hdr <= '0';
      end if;
      if SoP = '1' then
        vld_hdr <= '1';
        readvld_hdr <= '1';
      end if;

      if SoP = '1' and clk'event then
        iter <= 0;
        srcaddr <= x"00000000";
        destaddr <= x"00000000";
        srcport <= x"0000";
        destport <= x"0000";
        headerinfo <= '1';
        store0 <= x"00";
        store1 <= x"00";
        store2 <= x"00";
        forwardSoP <= '1';
        else
          forwardSoP <= '0';

      end if;
        if EoP = '1' then
        forwardEoP <= '1';
        else
          forwardEoP <= '0';
        end if;

      if iter >= 11 and iter <= 14 then -- SRCADDR
        if iter = 11 then
          store0 <= packet_in;
        end if;
        if iter = 12 then
          store1 <= packet_in;
        end if;
        if iter = 13 then
          store2 <= packet_in;
        end if;
        
        srcaddr <= store0 & store1 & store2 & packet_in;

      end if; 
      
      if iter >= 15 and iter <= 18 then -- DESTADDR
        if iter = 15 then
          store0 <= packet_in;
        end if;
        if iter = 16 then
          store1 <= packet_in;
        end if;
        if iter = 17 then
          store2 <= packet_in;
        end if;
        
        destaddr <= store0 & store1 & store2 & packet_in;
      end if;

      if iter >= 19 and iter <= 20 then -- SRCPORT
        if iter = 19 then
          store0 <= packet_in;
        end if;
        srcport <= store0 & packet_in;
      end if;

      if iter >= 21 and iter <= 22 then -- DESTPORT
        if iter = 21 then
          store0 <= packet_in;
        end if;
        destport <= store0 & packet_in;
      end if;

      if iter = 24 then
        header_data_store <= srcaddr & destaddr & srcport & destport;
      end if;


      if rhash = '1' and readvld_hdr = '1' then -- Send headerdata til cuckooo SKIFT TIL ready_hash!
        header_data <= header_data_store;
        headerinfo <= '1';
      else
        header_data <= x"000000000000000000000000";
      end if;

      if rFIFO = '1' and readvld_hdr = '1' then -- Send SoP, packet og EoP SKIFT TIL ready_FIFO
        if SoP = '1' then
          hdr_SoP <= '1';
        end if;
      end if;
      packet_forward <= packet_in;
      if EoP = '1' then
       hdr_EoP <= '1';
      end if; 

    end if;  
    
  end process;
  
end architecture;
