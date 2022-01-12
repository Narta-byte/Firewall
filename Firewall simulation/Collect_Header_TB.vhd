
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
  signal clk : std_logic;
  signal reset : std_logic;
  signal packet_in : std_logic_vector (7 downto 0);
  signal SoP : std_logic;
  signal EoP : std_logic;
  signal vld : std_logic;
  signal ready_FIFO : std_logic;
  signal ready_hash : std_logic;
  
  signal ready_hdr : std_logic;
  signal header_data : std_logic_vector (95 downto 0);
  signal packet_forward : std_logic_vector (7 downto 0);
  --signal vld_hdr_TB : std_logic; -- Fjern alle "TB's her! / Test.
  signal vld_hdr : std_logic;
  signal hdr_SoP : std_logic;
  signal hdr_EoP : std_logic;

  signal doneloop : std_logic;
  signal bytenm : integer := 0;
  signal packet_start : std_logic := '0';
--  signal readvld_hdr : std_logic := '1';
  
  -- FSM Logics:
type State_type is (idle, packet_input, stop_wait);
signal current_state, next_state : State_type;

begin

  DUT : Collect_Header port map(
    clk,
    reset,
    packet_in,
    SoP,
    EoP,
    vld,
    ready_FIFO,
    ready_hash,

    ready_hdr,
    header_data,
    packet_forward,
    -- vld_hdr_TB
    vld_hdr,
    hdr_SoP,
    hdr_EoP
  );

  -- UNCOMMENT FOR TESTS
--  vlaiddd : process 
--  begin
--    readvld_hdr <= '1'; wait;
--  end process;
  TestInputs : process 
  begin
    ready_FIFO <= '1'; wait for 1390 ns;
--    ready_FIFO <= '1'; wait for 10000 ns;
    ready_FIFO <= '0'; wait for 10 ns;  
    ready_FIFO <= '1'; wait;

  end process;

  Testcuckoo : process
  begin
    ready_hash <= '0'; wait for 10 ns;
    ready_hash <= '1'; wait for 2033 ns;
    ready_hash <= '0'; wait for 6 ns;
    ready_hash <= '1'; wait for 2 ns;
    ready_hash <= '0'; wait for 6 ns;
    ready_hash <= '1'; wait;
  end process;

  testvld : process 
  begin
    vld <= '1'; wait;
    
  end process;


  Clocken : process
  begin
    clk <= '1'; wait for 1 ns;
    clk <= '0'; wait for 1 ns; 
  end process;

  STATE_MEMORY_LOGIC : process (clk, reset)
  begin
      if reset = '1' then
          current_state <= idle;
      elsif rising_edge(clk) then
          current_state <= next_state;
      end if ;
  end process;  

  NEXT_STATE_LOGIC : process (current_state, ready_FIFO, ready_hash, vld, SoP, EoP, doneloop)
  begin
    case current_state is
        when idle =>
        if doneloop = '1' then
          next_state <= idle;
      elsif vld = '1' and ready_hash = '1' and ready_FIFO = '1' then --and SoP = '1' then
            next_state <= packet_input;
        end if;
            
        when packet_input =>
        if doneloop = '1' then
          next_state <= idle;
        elsif ready_FIFO = '0' or ready_hash = '0' or vld = '0' then
          next_state <= stop_wait;          
        elsif ready_FIFO = '1' and ready_hash = '1' and vld = '1' then
          next_state <= packet_input;
        end if;

        when stop_wait =>
          if ready_FIFO = '0' or ready_hash = '0' or vld = '0' then
            next_state <= stop_wait;
          elsif ready_FIFO = '1' and ready_hash = '1' and vld = '1' then
            next_state <= packet_input;            
        end if;
        when others => next_state <= idle;
    end case;  
  end process;

OUTPUT_LOGIC : process (clk)
    file input : TEXT open READ_MODE is "Input_packet.txt"; 
    
    variable current_read_line  : line;
    variable current_read_field : std_logic_vector (7 downto 0);
    variable current_write_line : std_logic;
    variable start_of_data_Reader : std_logic;

begin
    if Rising_Edge(clk) then
    case current_state is
        when idle =>
            -- Do nothing
        
        when packet_input =>
        if not (endfile(input)) then 
          packet_start <= '1';
            bytenm <= bytenm + 1;
            readline(input, current_read_line);
            hread(current_read_line, current_read_field); 
            packet_in <= current_read_field;
    
            read(current_read_line, current_write_line); 
            SoP <= current_write_line;
        
            read(current_read_line, current_write_line);
            EoP <= current_write_line;
        else
          doneloop <= '1';
        end if;

        when stop_wait =>
          -- wait for recieving packets again

        when others => report "FAILURE" severity failure;

        end case;
    end if;
    end process;
end;