library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity Firewall is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        -- collect header interface
        packet : out std_logic_vector(7 downto 0);
        sop : out std_logic;
        eop : out std_logic;
        full : in std_logic;
        
        --cuckoo hashing interface
        ready : in std_logic;
        key_out : out std_logic_vector(95 downto 0);
        cmd_out : out std_logic_vector(95 downto 0);
        set_rule : out std_logic

        --accept/deny interface
        acc_packet : out std_logic_vector(7 downto 0);
        sop : out std_logic;
        eop : out std_logic;

            
    );
end entity;

entity Collect_Header is
    port (
      clk : in std_logic;
      reset : in std_logic;
      packet_in : in std_logic_vector (7 downto 0);
      SoP : in std_logic;
      EoP : in std_logic;
      ready : in std_logic;
      
      --Control interface
      header_in : out std_logic_vector (95 downto 0);
      packet_forward : out std_logic_vector (7 downto 0);
  
    );
  end entity;

entity FIFO is
    generic (depth  : integer := 16);
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        wren        : in std_logic; --Writer = '0' when not in use 
        rden        : in std_logic; --Reader = '0' when not in use 
        data_in     : in std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        fifo_full   : out std_logic

        sop : out std_logic;
        eop : out std_logic
    );
end entity;

entity Accept_deny is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        -- fifo interface
        packet_forward : in std_logic_vector(7 downto 0);
        send_packet : out std_logic;
        sop_in : in std_logic;
        eop_in : in std_logic;

        --cuckoo hash interface
        ack : out std_logic;
        accept_deny : in std_logic

        --control interface
        sop_out : out std_logic;
        eop_out : out std_logic;
        packet_packet : out std_logic_vector(7 downto 0);
    );
end entity;


entity Cuckoo_hashing is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        --Control interface
        rule_in : in std_logic_vector(95 downto 0); -- aka key in
        cmd_in : in std_logic_vector(1 downto 0);
        set_rule : in std_logic;
        ready_for_rule : out std_logic;

        --SRAM interface
        address : out std_logic;
        RW : out std_logic;
        hash_out : out std_logic_vector(4 downto 0);
        key_out : out std_logic_vector(95 downto 0);
        hash_in : in std_logic_vector(4 downto 0);
        key_in : in std_logic_vector(95 downto 0);

        --Accept/deny interface
        ack : in std_logic;
        accept_deny : out std_logic;

        --collect header interface
        ready_for_packet : out std_logic;
        packet_in : in std_logic_vector(95 downto 0)
        
    );
end entity;


entity SRAM is
    port (
      clk : in std_logic;
      reset : in std_logic;
      WE : in std_logic; -- read/write
      address : in std_logic_vector(5 downto 0);
      hash_in : in std_logic_vector(5 downto 0);
      key_in : in std_logic_vector(8 downto 0);
      data_out : out std_logic_vector(20 downto 0) 
    ) ;
  end SRAM ;
  