library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Accept_Deny_tb is
end;

architecture bench of Accept_Deny_tb is

  component Accept_Deny
      port (
      clk : in std_logic;
      reset : in std_logic;
      out_dat : out std_logic_vector(7 downto 0);
      out_sop : out std_logic;
      out_eop : out std_logic;
      ok_cnt : out std_logic_vector;
      ko_cnt : out std_logic_vector;
      dat_FIFO : in std_logic_vector(7 downto 0);
      FIFO_sop : in std_logic;
      FIFO_eop : in std_logic;
      vld_fifo : in std_logic;
      rdy_ad_f : out std_logic;
      acc_deny : in std_logic;
      vld_hash : in std_logic;
      rdy_ad_h : out std_logic
    );
  end component;

  -- Other signals here 
  type state_type is (wait_hash, get_packet, accept_and_forward, deny_and_delete);
  signal current_state, next_state : state_type;

  -- Ports
  signal clk : std_logic;
  signal reset : std_logic;
  signal out_dat : std_logic_vector(7 downto 0);
  signal out_sop : std_logic;
  signal out_eop : std_logic;
  signal ok_cnt : std_logic_vector;
  signal ko_cnt : std_logic_vector;
  signal dat_FIFO : std_logic_vector(7 downto 0);
  signal FIFO_sop : std_logic;
  signal FIFO_eop : std_logic;
  signal vld_fifo : std_logic;
  signal rdy_ad_f : std_logic;
  signal acc_deny : std_logic;
  signal vld_hash : std_logic;
  signal rdy_ad_h : std_logic;

begin

  Accept_Deny_inst : Accept_Deny
    port map (
      clk => clk,
      reset => reset,
      out_dat => out_dat,
      out_sop => out_sop,
      out_eop => out_eop,
      ok_cnt => ok_cnt,
      ko_cnt => ko_cnt,
      dat_FIFO => dat_FIFO,
      FIFO_sop => FIFO_sop,
      FIFO_eop => FIFO_eop,
      vld_fifo => vld_fifo,
      rdy_ad_f => rdy_ad_f,
      acc_deny => acc_deny,
      vld_hash => vld_hash,
      rdy_ad_h => rdy_ad_h
    );


   clk_process : process
       begin
           clk <= '1';
       wait for 10 ns;
           clk <= '0';
        wait for 10 ns;
    end process clk_process;

    
    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= wait_hash;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if ;
    end process;  


    NEXT_STATE_LOGIC : process (all)
    begin
        
    end process;


    OUTPUT_LOGIC : process (all)
    begin
        
    end process;

end;
