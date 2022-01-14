library IEEE;
library std;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

entity Accept_Deny is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        
        --rdy_in_ad   : in std_logic;
        --vld_ad      : out std_logic; 

        -- FIFO interface 
        packet_forward_FIFO     : in std_logic_vector(9 downto 0);
        --FIFO_sop                : in std_logic;
        --FIFO_eop                : in std_logic;
        vld_fifo                : in std_logic;

        -- Cuckoo interface 
        acc_deny_hash          : in std_logic;
        vld_ad_hash       : in std_logic;

        rdy_ad_hash      : out std_logic;
        rdy_ad_FIFO      : out std_logic;
        
        -- skal måske tilføjes
        --out_sop          : out std_logic;
        --out_eop          : out std_logic;

        data_firewall    : out std_logic_vector(9 downto 0);
        ok_cnt           : out std_logic_vector(8 downto 0);
        ko_cnt           : out std_logic_vector(8 downto 0)
    );
end entity;


architecture arch_Accept_Deny of Accept_Deny is

    -- Other signals here 
    type state_type is (wait_hash, accept_and_forward, deny_and_delete);
    signal current_state, next_state : state_type;

    -- -- Component decleration 
    -- component minfifo is
    --     port (
    --         clock       : in std_logic;
    --         data		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
    --         rdreq		: IN STD_LOGIC ;
    --         wrreq		: IN STD_LOGIC ;
    --         empty		: OUT STD_LOGIC ;
    --         full		: OUT STD_LOGIC ;
    --         q			: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);
    --         usedw		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    --     );
    -- end component;

    -- -- Signals for portmapping 
    -- signal data : std_logic_vector(9 downto 0);
    -- signal rdreq, wrreq, empty, full : std_logic;
    -- signal q : std_logic_vector(9 downto 0);
    -- signal usedw : std_logic_vector(7 downto 0);  

    -- Test signals  
    signal int_ok      : integer := 0; 
    signal int_ko      : integer := 0;
    signal int_ok_next : integer := 0; 
    signal int_ko_next : integer := 0;
    --signal start_of_paket : std_logic := '0';
    signal start_of_packet : std_logic := '0';
    signal end_of_packet : std_logic := '0';

begin
    
    -- Portmapping of the FIFO.  
    -- FIFO : minfifo
    --     port map (
    --         clock => clk,
    --         data => data,
    --         rdreq => rdreq,
    --         wrreq => wrreq,
    --         empty => empty,
    --         full => full,
    --         q => q,
    --         usedw => usedw
    --     );
       
        -- michael evt andre værdier 
        --vld_fifo <= full;
        --rdreq <= rdy_ad_FIFO and (not empty);
        --wrreq <= vld_hdr and (not full);
        --FIFO_sop <= q(8);
        --FIFO_eop <= q(9);
        --data <=  packet_forward;    
        
        start_of_packet <= packet_forward_FIFO(1);
        end_of_packet <= packet_forward_FIFO(0);

        STATE_MEMORY_LOGIC : process (clk, reset)
        begin
            if reset = '1' then
                current_state <= wait_hash; 
            elsif rising_edge(clk) then
                current_state <= next_state; 
                int_ok <= int_ok_next;
                int_ko <= int_ko_next;
            end if ;

        end process;

        NEXT_STATE_LOGIC : process (current_state, vld_ad_hash, acc_deny_hash, vld_fifo, end_of_packet)
        begin
            next_state <= current_state;
                    case(current_state) is 
                        
                        when wait_hash => 
                            -- if vld_ad_hash = '1' then 
                            --     next_state <= get_packet;
                            -- elsif vld_ad_hash = '1' then 
                            --     next_state <= wait_hash; 
                            -- end if; 

                            if acc_deny_hash = '1' and vld_fifo = '1' and vld_ad_hash = '1' then 
                                next_state <= accept_and_forward; 
                            elsif acc_deny_hash = '0' and vld_fifo = '1' and vld_ad_hash = '1' then
                                next_state <= deny_and_delete;  
                            elsif vld_ad_hash = '0' then 
                                next_state <= wait_hash;
                            end if;

                       -- when get_packet =>
                                -- if acc_deny_hash = '1' and vld_fifo = '1' then 
                                --     next_state <= accept_and_forward; 
                                -- elsif acc_deny_hash = '0' and vld_fifo = '1' then
                                --     next_state <= deny_and_delete;  
                                -- end if;

                        when accept_and_forward =>
                                if end_of_packet = '1' then 
                                    next_state <= wait_hash;
                                elsif end_of_packet = '0' then
                                    next_state <= accept_and_forward;
                                end if;

                        when deny_and_delete => 
                                if end_of_packet = '1' then 
                                    next_state <= wait_hash;
                                elsif end_of_packet = '0' then
                                    next_state <= deny_and_delete;
                                end if; 
                    end case; 
        end process;


        OUTPUT_LOGIC : process (current_state, vld_ad_hash, acc_deny_hash, vld_fifo)
        begin
            data_firewall <= (others=>'0');
            rdy_ad_hash <= '0';
            rdy_ad_FIFO <= '0';
            int_ok_next <= int_ok;
            int_ko_next <= int_ko;

                case(current_state) is 

                    when wait_hash =>
                        rdy_ad_hash <= '1';

                   -- when get_packet =>
                        -- if (vld_fifo = '1') then 
                        --    data_firewall <= packet_forward_FIFO;
                        -- elsif (vld_fifo = '0') then 
                        --     report "FALIURE" severity failure; 
                        -- end if; 
                        -- rdy_ad_hash <= '0';
                        -- rdy_ad_FIFO <= '1';

                    when accept_and_forward => 
                        if acc_deny_hash = '1'  then 
                            data_firewall <= packet_forward_FIFO;
                            rdy_ad_hash <= '0';
                            rdy_ad_FIFO <= '0'; 
                        end if;
                            int_ok_next <= int_ok + 1;

                    when deny_and_delete => 
                        -- if acc_deny_hash = '0' then
                        --    data_firewall <= (others => '0');
                        --    rdy_ad_hash <= '0';
                        --    rdy_ad_FIFO <= '0';
                        -- end if; 
                        int_ko_next <= int_ko + 1;
                    
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure; 
                    
                end case;

            
        end process;

        ok_cnt <= std_logic_vector(to_signed(int_ok, ok_cnt'length));
        ko_cnt <= std_logic_vector(to_signed(int_ko, ko_cnt'length));
        
end architecture;

