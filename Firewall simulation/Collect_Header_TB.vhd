library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

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
      -- vld_hdr : in std_logic -- Til test!
      vld_hdr : out std_logic;
      hdr_SoP : out std_logic;
      hdr_EoP : out std_logic

    );

  end component;

  -- signal declarations
  signal clk_TB : std_logic;
  signal reset_TB : std_logic;
  signal packet_in_TB : std_logic_vector (7 downto 0);
  signal SoP_TB : std_logic;
  signal EoP_TB : std_logic;
  signal vld_TB : std_logic;
  signal ready_FIFO_TB : std_logic;
  signal ready_hash_TB : std_logic;
  
  signal ready_hdr : std_logic;
  signal header_data : std_logic_vector (95 downto 0);
  signal packet_forward : std_logic_vector (7 downto 0);
  --signal vld_hdr_TB : std_logic; -- Fjern alle "TB's her! / Test.
  signal vld_hdr : std_logic;
  signal hdr_SoP : std_logic;
  signal hdr_EoP : std_logic;

begin

  DUT : Collect_Header port map(
    clk_TB,
    reset_TB,
    packet_in_TB,
    SoP_TB,
    EoP_TB,
    vld_TB,
    ready_FIFO_TB,
    ready_hash_TB,

    ready_hdr,
    header_data,
    packet_forward,
    -- vld_hdr_TB
    vld_hdr,
    hdr_SoP,
    hdr_EoP
  );

  Resetten : process
  begin
    reset_TB <= '1'; wait for 1 ns;
    reset_TB <= '0'; wait;
  end process;

  Clocken : process
  begin
    clk_TB <= '1'; wait for 1 ns;
    clk_TB <= '0'; wait for 1 ns; 
  end process;

  -- vld_hdr_test : process
  -- begin 
  --   vld_hdr_TB <= '0'; wait for 150 ns;
  --   vld_hdr_TB <= '1'; wait for 100 ns;
  --   vld_hdr_TB <= '0'; wait;
  -- end process;

  -- rdy_hash_test : process 
  -- begin
  --   ready_hash_TB <= '0'; wait for 100 ns;
  --   ready_hash_TB <= '1'; wait for 100 ns;
  --   ready_hash_TB <= '0'; wait;
  -- end process;

  -- rdy_FIFO_test : process
  -- begin
  --   ready_FIFO_TB <= '0'; wait for 100 ns;
  --   ready_FIFO_TB <= '1'; wait for 100 ns;
  --   ready_FIFO_TB <= '0'; wait;
  -- end process;


  indput : process (clk_TB, reset_TB)

  file Fin : TEXT open READ_MODE is "Input_packet.txt"; 

    variable current_read_line	: line;
    variable current_read_field	: std_logic_vector (7 downto 0);
    variable current_write_line 	: std_logic;
    variable start_of_data_Reader : std_logic;

  begin
    if reset_TB = '1' then
      -- set all to 0
      packet_in_tB <= x"00";
      SoP_TB <= '0';
      EoP_TB <= '0';
      vld_TB <= '0';
      --ready_FIFO_TB <= '0';
      --ready_hash_TB <= '0'; 

       elsif (Rising_edge(clk_TB) and (not (endfile(Fin)))) then 
      
      readline(Fin, current_read_line);
      hread(current_read_line, current_read_field);
      packet_in_TB <= current_read_field;
    
      read(current_read_line, current_write_line); 
      SoP_TB <= current_write_line;
      
      read(current_read_line, current_write_line);
      EoP_TB <= current_write_line; 

      end if;

  end process;
end architecture;