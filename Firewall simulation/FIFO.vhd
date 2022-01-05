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
        data_in     : in std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        fifo_full   : out std_logic
    );
end entity;

architecture behavioral of FIFO is

    --signal pck_in   : std_logic := '0';
    --signal pck_out  : std_logic := '0'; 
    --signal send_rdy : std_logic := '0'; 
    
    type mem_type is array (0 to depth-1) of std_logic_vector(7 downto 0);
    signal mem      : mem_type := (others => (others => '0'));
    signal rpt, wpt : integer := 0; --Read and write pointer 
    signal full     : std_logic := '0';
    

begin

    fifo_full <= full; 

    process (clk, reset)

        variable element_num : integer := 0;

    begin
        if (reset = '1') then
            data_out    <= (others => '0');
            full        <= '0';
            rpt         <= 0;
            wpt         <= 0;
            element_num := 0;
        elsif(rising_edge(clk)) then
            if(rden = '1') then
                data_out <= mem(rpt);
                rpt <= rpt + 1;
                element_num := element_num - 1;
        end if;
        if (wren = '1' and full = '0') then
            mem(wpt) <= data_in;
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