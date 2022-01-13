library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity Accept_Deny_tb is
end;


architecture bench of Accept_Deny_tb is

  --Decleration of Accept_Deny signals  
  signal clk                 : std_logic;
  signal reset               : std_logic;
  signal data_firewall       : std_logic_vector(9 downto 0) := (others => '0');
  --signal out_sop : std_logic;
  --signal out_eop : std_logic;
  signal ok_cnt              : std_logic_vector(8 downto 0):= (others => '0');
  signal ko_cnt              : std_logic_vector(8 downto 0):= (others => '0');
  signal packet_forward_FIFO : std_logic_vector(9 downto 0) := "1010101010";
  --signal FIFO_sop : std_logic;
  --signal FIFO_eop : std_logic;
  signal vld_fifo : std_logic := '1';
  signal acc_deny : std_logic := '0';
  signal rdy_ad_FIFO : std_logic;
  signal vld_hash : std_logic := '1';
  signal rdy_ad_hash : std_logic;
  
  -- Component for Accept_Deny
  component Accept_Deny
    port (
    clk                 : in std_logic; --yes
    reset               : in std_logic; --yes
    packet_forward_FIFO : in std_logic_vector(9 downto 0); --yes
    --FIFO_sop : in std_logic; 
    --FIFO_eop : in std_logic; 
    vld_fifo            : in std_logic; --yes
    acc_deny            : in std_logic; --yes
    vld_hash            : in std_logic; --yes
    rdy_ad_hash         : out std_logic; --yes
    rdy_ad_FIFO         : out std_logic; -- micheal hjælp
    data_firewall       : out std_logic_vector(9 downto 0); --yes
    --out_sop : out std_logic; 
    --out_eop : out std_logic;
    ok_cnt               : out std_logic_vector(8 downto 0); --yes ændres måske senere
    ko_cnt               : out std_logic_vector(8 downto 0) --yes ændres måske senere
  );
end component;

--Other signals 
type state_type is (do_nothing, packet_input, waiting);
signal current_state, next_state : state_type;

signal set_data : std_logic := '1'; 


begin

  -- Portmapping
  DUT : Accept_Deny
    port map (
      clk => clk,
      reset => reset,
      packet_forward_FIFO => packet_forward_FIFO,
      vld_fifo => vld_fifo,
      acc_deny => acc_deny,
      vld_hash => vld_hash,
      rdy_ad_hash => rdy_ad_hash,
      rdy_ad_FIFO => rdy_ad_FIFO,
      data_firewall => data_firewall,
      ok_cnt => ok_cnt,
      ko_cnt => ko_cnt
      );

   --SUPER
   clk_process : process
       begin
           clk <= '1';
       wait for 1 ns;
           clk <= '0';
        wait for 1 ns;
    end process;

    -- SUPER 
    STATE_MEMORY_LOGIC : process (clk, reset)
    begin
        if reset = '1' then
            current_state <= do_nothing;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if ;
    end process;  


    --PENDING 
    NEXT_STATE_LOGIC : process (current_state, vld_fifo, vld_hash, set_data)
    begin
        case current_state is
          when do_nothing =>
            if set_data = '0' then
              next_state <= do_nothing;
              
            elsif vld_fifo = '1' and vld_hash = '1' then 
              next_state <= packet_input;
             
            end if;
          
          when packet_input => 
            if set_data = '0' then 
              next_state <= do_nothing; 
    
            elsif vld_fifo = '0' and vld_hash = '0' then
              next_state <= waiting;
        
            elsif vld_fifo = '1' and vld_hash = '1' then 
              next_state <= packet_input;
     
            end if;  

          when waiting =>
            if vld_fifo = '0' and vld_hash = '0' then
              next_state <= waiting; 
       
            elsif vld_fifo = '1' and vld_hash = '1' then 
              next_state <= packet_input;
   
            end if;

          when others => next_state <= do_nothing;

        end case;
    end process;

    --PENDING
    OUTPUT_LOGIC : process (clk)
    
    begin
      if Rising_Edge(clk) then 
        case current_state is 
          when do_nothing =>
              -- Do Nothing 
          
          when packet_input => 

              data_firewall <= packet_forward_FIFO;
        
          when waiting => 
              -- Waiting
         
          when others => report "FAILURE" severity failure;
        end case;
      end if;
    end process;

end;
