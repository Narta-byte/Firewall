library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Accept_Deny is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        
        --rdy_in_ad   : in std_logic;
        --vld_ad      : out std_logic; 
        out_dat     : out std_logic_vector(7 downto 0);
        out_sop     : out std_logic;
        out_eop     : out std_logic;
        ok_cnt      : out std_logic_vector;
        ko_cnt      : out std_logic_vector;

        -- FIFO interface 
        dat_FIFO    : in std_logic_vector(7 downto 0);
        FIFO_sop    : in std_logic;
        FIFO_eop    : in std_logic;
        vld_fifo    : in std_logic;
        rdy_ad_f    : out std_logic := '1';

        -- Cuckoo interface 
        acc_deny    : in std_logic;
        vld_hash    : in std_logic;
        rdy_ad_h    : out std_logic := '1'

    );
end entity;


architecture rtl of Accept_Deny is

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

                        when accept_and_forward => next_state <= wait_hash;

                        when deny_and_delete => next_state <= wait_hash; 

                    end case; 
        end process;


        OUTPUT_LOGIC : process (current_state, vld_hash, full, empty, full_packet, acc_deny, vld_fifo)
        begin

                case(current_state) is 

                    when wait_hash =>
                        -- if vld_hash = '0' then 
                        --     rdy_ad_f <= '0';
                        -- elsif vld_hash = '1' then
                        --     rdy_ad_f<= '1';
                        -- end if;
                        rdy_ad_h <= '1';

                    when get_packet =>
                        if (full = '1') and (vld_fifo= '1') then 
                            full_packet <= q;
                            --rdy_ad_h <= '0';
                        elsif  empty = '0' and (vld_fifo= '1') then 
                            report "FALIURE" severity failure; 
                        end if; 
                        rdy_ad_h <= '0';
                        rdy_ad_f <= '1';

                    when accept_and_forward => 
                        if acc_deny = '1'  then 
                            packet_out <= q;
                            rdy_ad_h <= '0';
                            rdy_ad_f <= '0'; 
                        end if;
                        int_ok <= int_ok + 1;

                    when deny_and_delete => 
                        if acc_deny = '0' then 
                            packet_out <= (others => '0'); --"00000000" 
                            rdy_ad_h <= '0';
                            rdy_ad_f <= '0';  
                        end if; 
                        int_ko <= int_ko + 1;  
                    
                    when others => report "ERROR IN OUTPUT LOGIC" severity failure; 
                    
                end case;

            
        end process;

        full_packet <=  dat_FIFO & FIFO_sop  & FIFO_eop;
        packet_out <= q; 
        ok_cnt <= std_logic_vector(to_signed(int_ok, ok_cnt'length));
        ko_cnt <= std_logic_vector(to_signed(int_ko, ko_cnt'length));
        

end architecture;