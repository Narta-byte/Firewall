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
        --fifo_sop                : in std_logic;
        --fifo_eop                : in std_logic;
        vld_fifo                : in std_logic;

        -- Cuckoo interface 
        acc_deny    : in std_logic;
        vld_hash    : in std_logic;

        rdy_ad_hash      : out std_logic;
        rdy_ad_FIFO      : out std_logic;
        data_firewall    : out std_logic_vector(9 downto 0);
        --out_sop          : out std_logic;
        --out_eop          : out std_logic;
        ok_cnt           : out std_logic_vector(8 downto 0);
        ko_cnt           : out std_logic_vector(8 downto 0)
    );
end entity;


architecture arch_Accept_Deny of Accept_Deny is

    -- Other signals here 
    type state_type is (wait_hash, get_packet, accept_and_forward, deny_and_delete);
    signal current_state, next_state : state_type;

    -- Component decleration 
    component minfifo is
        port (
            clock       : in std_logic;
            data		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
            rdreq		: IN STD_LOGIC ;
            wrreq		: IN STD_LOGIC ;
            empty		: OUT STD_LOGIC ;
            full		: OUT STD_LOGIC ;
            q			: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);
            usedw		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    end component;
    
    -- Signals for portmapping 
    signal data : std_logic_vector(9 downto 0);
    signal rdreq, wrreq, empty, full : std_logic;
    signal q : std_logic_vector(9 downto 0);
    signal usedw : std_logic_vector(7 downto 0);  

    -- Test signals 
    signal full_packet : std_logic_vector(9 downto 0);
    signal packet_out  : std_logic_vector(9 downto 0); 
    signal int_ok      : integer; 
    signal int_ko      : integer;


begin
    
    -- Portmapping of the FIFO.  
    FIFO : minfifo
        port map (
            clock => clk,
            data => data,
            rdreq => rdreq,
            wrreq => wrreq,
            empty => empty,
            full => full,
            q => q,
            usedw => usedw
        );
    
        STATE_MEMORY_LOGIC : process (clk, reset)
        begin
            if reset = '1' then
                current_state <= wait_hash; 
            elsif rising_edge(clk) then
                current_state <= next_state; 
            end if ;
        end process;

        NEXT_STATE_LOGIC : process (current_state, vld_hash, acc_deny, vld_fifo)
        begin
            next_state <= current_state;
                    case(current_state) is 
                        
                        when wait_hash => 
                            if vld_hash = '1' then 
                                next_state <= get_packet;
                            else 
                                next_state <= wait_hash; 
                            end if; 

                        when get_packet =>
                                if acc_deny = '1' and vld_fifo = '1' then 
                                    next_state <= accept_and_forward; 
                                elsif acc_deny = '0' and vld_fifo = '1' then
                                    next_state <= deny_and_delete;  
                                end if;

                        when accept_and_forward =>
                                if eop = '1'then 
                                    next_state <= wait_hash;
                                else 
                                    next_state <= accept_and_forward;

                        when deny_and_delete => next_state <= wait_hash; 

                    end case; 
        end process;


        OUTPUT_LOGIC : process (current_state, vld_hash, full, empty, acc_deny, vld_fifo)
        begin

                case(current_state) is 

                    when wait_hash =>
                        rdy_ad_hash <= '1';

                    when get_packet =>
                        if (full = '1') and (vld_fifo = '1') then 
                           data_firewall <= packet_forward_FIFO;
                        elsif  (empty = '0') and (vld_fifo = '1') then 
                            report "FALIURE" severity failure; 
                        end if; 
                        rdy_ad_hash <= '0';
                        rdy_ad_FIFO <= '1';

                    when accept_and_forward => 
                        if (acc_deny = '1')  then 
                            data_firewall <= packet_forward_FIFO;
                            rdy_ad_hash <= '0';
                            rdy_ad_FIFO <= '0'; 
                        end if;
                            int_ok <= int_ok + 1;

                    when deny_and_delete => 
                        if (acc_deny = '0') then
                           data_firewall <= (others => '0');
                           rdy_ad_hash <= '0';
                           rdy_ad_FIFO <= '0';
                        end if; 
                            int_ko <= int_ko + 1;
                    
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure; 
                    
                end case;

            
        end process;

        ok_cnt <= std_logic_vector(to_signed(int_ok, ok_cnt'length));
        ko_cnt <= std_logic_vector(to_signed(int_ko, ko_cnt'length));
        
end architecture;