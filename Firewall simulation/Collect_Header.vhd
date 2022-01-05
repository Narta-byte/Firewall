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
    vld_FIFO : out std_logic;
    vld_hash : out std_logic

  );
end entity;

architecture Collect_Header_arch of Collect_Header is
  -- signal declarations
  signal srcaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store source address here
  signal destaddr : std_logic_vector (31 downto 0) := x"00000000"; --Store destination address here
  signal srcport : std_logic_vector (15 downto 0) := x"00000000"; -- fang source ports her
  signal destport : std_logic_vector (15 downto 0) := x"00000000"; -- fang destsource ports her
  signal iter : integer := 0;

begin

  Collect : process (clk, reset)
  begin
    if reset = '1' then
      srcaddr <= x"00000000";
      destaddr <= x"00000000";
      srcport <= x"00000000";
      destport <= x"00000000";
      iter <= 0;
    elsif Rising_edge(clock) then
      if Sop = '1' then
        iter <= 0;
      end if;
      iter <= iter + 1;

      if iter >= 12 and iter <= 16 then
        srcaddr <= srcaddr & packet_in;
      end if;

      if iter >= 17 and iter <= 21
        destaddr <= desaddr & packet_in;
      end if

      if iter = 22 and iter = 23 then
        srcport <= srcport & packet_in;
      end if;

      if iter = 24 and iter = 25 then
        destport <= destport & packet_in;
      end if;

      header_data <= srcaddr & header_data;
      header_data <= destaddr & header_data;
      header_data <= srcport & header_data;
      header_data <= destport & header_data;

      packet_in <= packet_forward;

    end if;

  end process;

end architecture;