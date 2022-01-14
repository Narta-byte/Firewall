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
        packet_forward_FIFO    : in std_logic_vector(9 downto 0);
        --FIFO_sop    : in std_logic;
        --FIFO_eop    : in std_logic;
        vld_fifo    : in std_logic;

        -- Cuckoo interface 
        acc_deny_hash    : in std_logic;
        vld_ad_hash    : in std_logic;

        rdy_ad_hash    : out std_logic := '1';
        rdy_ad_FIFO    : out std_logic := '1';
        data_firewall     : out std_logic_vector(9 downto 0);
        --out_sop     : out std_logic;
        --out_eop     : out std_logic;
        ok_cnt      : out std_logic_vector;
        ko_cnt      : out std_logic_vector
    );
end entity;


architecture Accept_Deny_arch of Accept_Deny is

    -- Other signals here 
    type state_type is (wait_hash, get_packet, accept_and_forward, deny_and_delete);
    signal current_state, next_state : state_type;

    
    -- Signals for portmapping 
    signal data : std_logic_vector(9 downto 0);
    signal rdreq, wrreq, empty, full : std_logic; --Spørg om
    signal q : std_logic_vector(9 downto 0); -- spørg om
    signal usedw : std_logic_vector(7 downto 0);  -- spørg om

    -- Test signals 
    signal full_packet : std_logic_vector(9 downto 0);
    signal packet_out  : std_logic_vector(9 downto 0); 
    signal int_ok      : integer; 
    signal int_ko      : integer;


begin
    
        STATE_MEMORY_LOGIC : process (clk, reset)
        begin
            if reset = '1' then
                current_state <= wait_hash; 
            elsif rising_edge(clk) then
                current_state <= next_state; 
            end if ;
        end process;

        NEXT_STATE_LOGIC : process (current_state, vld_ad_hash, acc_deny_hash, vld_fifo)
        begin
            next_state <= current_state;
                    case(current_state) is 
                        
                        when wait_hash => 
                            if vld_ad_hash = '1' then 
                                next_state <= get_packet;
                            else 
                                next_state <= wait_hash; 
                            end if; 

                        when get_packet =>
                                if acc_deny_hash = '1' and vld_fifo = '1' then 
                                    next_state <= accept_and_forward; 
                                elsif acc_deny_hash = '0' and vld_fifo = '1' then
                                    next_state <= deny_and_delete;  
                                end if;

                        when accept_and_forward =>
                                if eop = '1'then 
                                    next_state <= wait_hash;
                                else 
                                    next_state <= accept_and_forward;
                                end if;
                        when deny_and_delete => next_state <= wait_hash; 

                    end case; 
        end process;


        OUTPUT_LOGIC : process (current_state, vld_ad_hash, full, empty, full_packet, acc_deny_hash, vld_fifo)
        begin

                case(current_state) is 

                    when wait_hash =>
                        -- if vld_ad_hash = '0' then 
                        --     rdy_ad_f <= '0';
                        -- elsif vld_ad_hash = '1' then
                        --     rdy_ad_f<= '1';
                        -- end if;
                        rdy_ad_hash <= '1';

                    when get_packet =>
                        if (full = '1') and (vld_fifo = '1') then 
                           data_firewall <= packet_forward_FIFO;
                        elsif  (empty = '0') and (vld_fifo = '1') then 
                            report "FALIURE" severity failure; 
                        end if; 
                        rdy_ad_hash <= '0';
                        rdy_ad_fifo <= '1';

                    when accept_and_forward => 
                        if acc_deny_hash = '1'  then 
                            packet_out <= q;
                            rdy_ad_hash <= '0';
                            rdy_ad_fifo <= '0'; 
                        end if;
                            int_ok <= int_ok + 1;

                    when deny_and_delete => 
                        if acc_deny_hash = '0' then 
                            packet_out <= (others => '0'); --"00000000" 
                            rdy_ad_hash <= '0';
                            rdy_ad_fifo <= '0';  
                        end if; 
                            int_ko <= int_ko + 1;
                    
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure; 
                    
                end case;

            
        end process;

        full_packet <=  packet_forward_fifo ;
        packet_out <= q; 
        ok_cnt <= std_logic_vector(to_signed(int_ok, ok_cnt'length));
        ko_cnt <= std_logic_vector(to_signed(int_ko, ko_cnt'length));
        
end architecture;