library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Cuckoo_Hashing_tb is
end;

architecture bench of Cuckoo_Hashing_tb is

  component Cuckoo_Hashing
      port (
      clk : in std_logic;
      reset : in std_logic;
      set_rule : in std_logic;
      cmd_in : in std_logic_vector(1 downto 0);
      key_in : in std_logic_vector(95 downto 0);
      header_in : in std_logic_vector(95 downto 0);
      address : out std_logic_vector(5 downto 0);
      RW : out std_logic;
      hash_out : out std_logic_vector(7 downto 0);
      key_out : out std_logic_vector(8 downto 0);
      occupied_flag_out : out std_logic;
      SRAM_data : in std_logic_vector(13 downto 0);
      acc_deny_out : out std_logic
    );
  end component;

  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

  -- Ports
  signal clk : std_logic;
  signal reset : std_logic;
  signal set_rule : std_logic;
  signal cmd_in : std_logic_vector(1 downto 0);
  signal key_in : std_logic_vector(95 downto 0);
  signal header_in : std_logic_vector(95 downto 0);
  signal address : std_logic_vector(5 downto 0);
  signal RW : std_logic;
  signal hash_out : std_logic_vector(7 downto 0);
  signal key_out : std_logic_vector(8 downto 0);
  signal occupied_flag_out : std_logic;
  signal SRAM_data : std_logic_vector(13 downto 0);
  signal acc_deny_out : std_logic;

begin

  Cuckoo_Hashing_inst : Cuckoo_Hashing
    port map (
      clk => clk,
      reset => reset,
      set_rule => set_rule,
      cmd_in => cmd_in,
      key_in => key_in,
      header_in => header_in,
      address => address,
      RW => RW,
      hash_out => hash_out,
      key_out => key_out,
      occupied_flag_out => occupied_flag_out,
      SRAM_data => SRAM_data,
      acc_deny_out => acc_deny_out
    );

    process 
    begin
        clk <= '1';
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
        
    end process;
--   clk_process : process
--   begin
--   clk <= '1';
--   wait for clk_period/2;
--   clk <= '0';
--   wait for clk_period/2;
--   end process clk_process;

end;
