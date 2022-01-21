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

        -- Accept/Deny interface
        data_firewall    : out std_logic_vector(9 downto 0);
        ok_cnt           : out std_logic_vector(7 downto 0);
        ko_cnt           : out std_logic_vector(7 downto 0);

        -- FIFO interface 
        packet_forward_FIFO     : in std_logic_vector(9 downto 0);
        vld_fifo                : in std_logic;
        rdy_ad_FIFO             : out std_logic;

        -- Cuckoo interface 
        acc_deny_hash          : in std_logic;
        vld_ad_hash            : in std_logic;
        rdy_ad_hash            : out std_logic
        
    );
end entity;


architecture arch_Accept_Deny of Accept_Deny is

    -- States
    type state_type is (wait_hash, accept_and_forward, deny_and_delete, wait_start);
    signal current_state, next_state : state_type;

    -- Count signals  
    signal int_ok      : integer := 0; 
    signal int_ko      : integer := 0;
    signal int_ok_next : integer := 0; 
    signal int_ko_next : integer := 0;

    signal ok_cnt_firewall, ko_cnt_firewall : integer := 0;
    signal ok_cnt_firewall_next, ko_cnt_firewall_next : integer;
    


    -- Other signals 
    signal end_of_packet : std_logic := '0';

    signal first_time_cnt : std_logic:='0';
    signal first_time_cnt_next : std_logic;
    



    signal rdy_ad_FIFO_next : std_logic;
    signal rdy_ad_FIFO_read : std_logic;
    
    

begin

        end_of_packet <= packet_forward_FIFO(0);
        rdy_ad_FIFO <= rdy_ad_FIFO_next;

        STATE_MEMORY_LOGIC : process (clk, reset)
        begin
            if reset = '1' then
                current_state <= wait_start; 

            elsif rising_edge(clk) then
                current_state <= next_state;
                rdy_ad_FIFO_read <= rdy_ad_FIFO_next;
                ok_cnt_firewall <= ok_cnt_firewall_next;
                ko_cnt_firewall <= ko_cnt_firewall_next;
                first_time_cnt <= first_time_cnt_next;

            end if ;

        end process;

        NEXT_STATE_LOGIC : process (current_state, vld_ad_hash, acc_deny_hash, vld_fifo, end_of_packet,
                                    ko_cnt_firewall_next, ok_cnt_firewall_next)
        begin
            next_state <= current_state;
                    case(current_state) is 
                        
                        when wait_start =>
                        if acc_deny_hash = '1' and vld_fifo = '1' and vld_ad_hash = '1' then 
                            next_state <= accept_and_forward;                            
                        elsif acc_deny_hash = '0' and vld_fifo = '1' and vld_ad_hash = '1' then
                                next_state <= deny_and_delete;  
                        elsif vld_ad_hash = '0' and ok_cnt_firewall_next = 0 and ko_cnt_firewall_next = 0 then 
                                next_state <= wait_start;
                        elsif vld_ad_hash = '0' then
                            next_state <= wait_hash;
                            end if;



                        when wait_hash => 
                            if acc_deny_hash = '1' and vld_fifo = '1' and vld_ad_hash = '1' then 
                                next_state <= accept_and_forward; 
                            elsif acc_deny_hash = '0' and vld_fifo = '1' and vld_ad_hash = '1' then
                                next_state <= deny_and_delete;  
                            elsif vld_ad_hash = '0' then 
                                next_state <= wait_hash;
                            end if;

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


        OUTPUT_LOGIC : process (current_state, reset, vld_ad_hash, acc_deny_hash, vld_fifo,first_time_cnt, packet_forward_FIFO,
                                ok_cnt_firewall, ko_cnt_firewall, rdy_ad_FIFO_read)
        begin
            data_firewall <= (others=>'0');
            rdy_ad_FIFO_next <= rdy_ad_FIFO_read;
            ok_cnt_firewall_next <= ok_cnt_firewall;
            ko_cnt_firewall_next <= ko_cnt_firewall;
            first_time_cnt_next <= first_time_cnt;

                case(current_state) is 

                    when wait_start =>
                    ok_cnt_firewall_next <= 0;
                    ko_cnt_firewall_next <= 0;

                    rdy_ad_hash <= '1';
                    first_time_cnt_next <= '0';

                    when wait_hash =>
                        rdy_ad_hash <= '1';
                        first_time_cnt_next <= '0';

                    when accept_and_forward => 
                            data_firewall <= packet_forward_FIFO;
                            rdy_ad_FIFO_next <= '1'; 
                            
                            rdy_ad_hash <= '0';
                            if first_time_cnt = '0' then
                                ok_cnt_firewall_next <= ok_cnt_firewall +1;
                                first_time_cnt_next <= '1';
                            end if ;
                    when deny_and_delete => 
                        
                        rdy_ad_FIFO_next <= '1'; 
                        rdy_ad_hash <= '0';
                        
                        if first_time_cnt = '0' then
                            ko_cnt_firewall_next <= ko_cnt_firewall +1;
                            first_time_cnt_next <= '1';
                        end if ;
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure; 
                    
                end case;

            
        end process;

        ok_cnt <= std_logic_vector(to_unsigned(ok_cnt_firewall,ok_cnt'length));
        ko_cnt <= std_logic_vector(to_unsigned(ko_cnt_firewall,ok_cnt'length));
        
end architecture;