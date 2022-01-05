library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Collect_Header_TB is
end entity;

architecture Collect_Header_TB_arch of Collect_Header_TB is

  component Collect_Header is
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

  end component;

  -- signal declarations
  signal clk_TB : std_logic;
  signal reset_TB : std_logic;
  signal packet_in_TB : std_logic_vector (7 downto 0);
  signal SoP_TB : std_logic;
  signal EoP_TB : std_logic;
  signal vld_TB : std_logic;
  signal ready_FIFO : std_logic;
  signal ready_hash : std_logic;
  signal ready_hash : std_logic;

  signal ready_hdr : std_logic;
  signal header_data : std_logic_vector (95 downto 0);
  signal packet_forward : std_logic_vector (7 downto 0);
  signal vld_FIFO : std_logic;
  signal vld_hash : std_logic

begin

  DUT : Collect_Header port map(
    clk_TB,
    reset_TB,
    packet_in_TB,
    SoP_TB,
    EoP_TB,
    vld_TB,
    ready_FIFO,
    ready_hash,
    ready_hash,
    ready_hdr,
    header_data,
    packet_forward,
    vld_FIFO,
    vld_hash

  );

  Resetten : process
  begin
    reset_TB <= '1'; wait for 1ns;
    reset_TB <= '0'; wait;
  end process;

  Clocken : process
  begin
    clk_TB <= '1'; wait for 1ns;
    clk_TB <= '0'; wait for 0ns;
  end process;

  logic : process (clk_TB, reset_TB)
  begin
    if reset_TB = '1' then
      -- set all to 0
      packet_in <= x"00";
      SoP <= '0';
      EoP <= '0';
      vld <= '0';
      ready_FIFO <= '0';
      ready_hash <= '0';

    elsif Rising_Edge(clk_TB) then
      -- Logics

    end if;

  end process;
end architecture;