library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity firewall is
end entity;

architecture firewall_arch of firewall is

  component Collect_Header
      port (
      clk : in std_logic;
      reset : in std_logic;
      packet_in : in std_logic_vector (7 downto 0);
      SoP : in std_logic;
      EoP : in std_logic;
      vld_firewall : in std_logic;
      rdy_FIFO : in std_logic;
      rdy_hash : in std_logic;
      rdy_collecthdr : out std_logic;
      header_data : out std_logic_vector (95 downto 0);
      packet_forward : out std_logic_vector (7 downto 0);
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
  acc_deny_out : out std_logic;
  vld_ad_hash : out std_logic;
  rdy_ad_hash : in std_logic
);
end component;

component minfifo
      port (
      clk : in STD_LOGIC;
      packet_forward : in STD_LOGIC_VECTOR (9 DOWNTO 0);
      rdreq : in STD_LOGIC; -- Michael, hjælp!
      wrreq : in STD_LOGIC; --Michael, hjælp!
      empty : out STD_LOGIC; --Michail, hilfe!
      full : out STD_LOGIC;--Michail, hilfe!
      q : out STD_LOGIC_VECTOR (9 DOWNTO 0);--Michail, hilfe!
      usedw : out STD_LOGIC_VECTOR (7 DOWNTO 0)--Michail, hilfe!
    );
  end component;

  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics

  -- Ports for Collect_header
  signal clk : std_logic;
  signal reset : std_logic;
  signal packet_in : std_logic_vector (7 downto 0);
  signal SoP : std_logic;
  signal EoP : std_logic;
  signal vld_firewall : std_logic;
  signal rdy_FIFO : std_logic;
  signal rdy_hash : std_logic;
  signal rdy_collecthdr : std_logic;
  signal header_data : std_logic_vector (95 downto 0);
  signal packet_forward : std_logic_vector (7 downto 0);
  signal vld_hdr : std_logic;
  signal hdr_SoP : std_logic;
  signal hdr_EoP : std_logic;

  --cuckoo
  
  signal set_rule : std_logic;
  signal cmd_in : std_logic_vector(1 downto 0);
  signal key_in : std_logic_vector(95 downto 0);
  signal header_in : std_logic_vector(95 downto 0);
  --signal vld_hdr : std_logic;
  --signal rdy_hash : std_logic;
  signal vld_firewall_hash : std_logic;
  signal rdy_firewall_hash : std_logic;
  signal acc_deny_out : std_logic;
  signal vld_ad_hash : std_logic;
  signal rdy_ad_hash : std_logic;

  signal clock : STD_LOGIC;
  signal data : STD_LOGIC_VECTOR (9 DOWNTO 0);
  signal rdreq : STD_LOGIC;
  signal wrreq : STD_LOGIC;
  signal empty : STD_LOGIC;
  signal full : STD_LOGIC;
  signal q : STD_LOGIC_VECTOR (9 DOWNTO 0);
  signal usedw : STD_LOGIC_VECTOR (7 DOWNTO 0);


begin
  Clocken : process 
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
      acc_deny_out => acc_deny_out, --kan ikke implementeres pt
      vld_ad_hash => vld_ad_hash, 
      rdy_ad_hash => rdy_ad_hash
    );
  
    minfifo_inst : minfifo
    port map (
      clock => clock,
      data => data,
      rdreq => rdreq,
      wrreq => wrreq,
      empty => empty,
      full => full,
      q => q,
      usedw => usedw
    );

    --
    
    
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



