

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
    ready : in std_logic;

    header_in : out std_logic_vector (95 downto 0);
    packet_forward : out std_logic_vector (7 downto 0);

  );
end entity;

architecture Collect_Header_arch of Collect_Header is
  -- signal declarations
  signal adressports : std_logic_vector (63 downto 0) := x"0000000000000000"; --fang adresseports her 
  signal ports : std_logic_vector (31 downto 0) := x"00000000"; -- fang source ports her

begin

  Collect : process (clk, reset)
  begin
    if reset = '1' then
      adressports <= x"0000000000000000";
      ports <= x"00000000";
    elsif Rising_edge(clock) then

    end if;

  end process;

end architecture;