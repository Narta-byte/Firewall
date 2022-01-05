library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity FIFO is
    generic (depth  : integer := 16);
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        wren        : in std_logic; --Writer = '0' when not in use 
        rden        : in std_logic; --Reader = '0' when not in use 

        -- Collect Header interface 
        hdr_dat     : in std_logic_vector(7 downto 0);
        hdr_sop     : in std_logic;
        hrd_eop     : in std_logic;
        val_hdr     : in std_logic; 
        rdy_FIFO    : out std_logic; 

        -- Accept/Deny interface 
        rdy_AD      : in std_logic;
        dat_FIFO    : out std_logic_vector(7 downto 0);
        FIFO_sop    : out std_logic;
        FIFO_eop    : out std_logic;
        val_FIFO    : out std_logic
    );
end entity;


architecture behavioral of FIFO is
  
    type mem_type is array (0 to depth-1) of std_logic_vector(7 downto 0);
    signal mem      : mem_type  := (others => (others => '0'));
    signal rpt, wpt : integer   := 0; --Read and write pointer 
    signal full     : std_logic := '0';
    --signal send_pck : std_logic := '0'; 

begin

    rdy_FIFO <= not(full); 

    process (clk, reset)

        variable element_num : integer := 0;

    begin
        if (reset = '1') then
            dat_FIFO    <= (others => '0');
            full        <= '0';
            rpt         <= 0;
            wpt         <= 0;
            element_num := 0;
        elsif(rising_edge(clk)) then
            if(rden = '1') then
                dat_FIFO <= mem(rpt);
                rpt <= rpt + 1;
                element_num := element_num - 1;
            end if;
        if (wren = '1' and full = '0') then
            mem(wpt) <= hdr_dat;
            wpt <= wpt + 1; 
            element_num := element_num - 1; 
        end if;

        if (rpt = depth - 1) then
            rpt <= 0;
        end if;
        if (wpt = depth - 1) then
            wpt <= 0;            
        end if;

        if (element_num = depth) then
            full <= '1';            
        else
            full <= '0';
        end if;
    end if;

    

    end process;
    

end architecture;