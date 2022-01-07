library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity Accept_Deny is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        
        out_dat     : out std_logic_vector(7 downto 0);
        out_sop     : out std_logic;
        out_eop     : out std_logic;
        ok_cnt      : out std_logic;
        ko_cnt      : out std_logic;

        -- FIFO interface 
        dat_FIFO    : in std_logic_vector(7 downto 0);
        FIFO_sop    : in std_logic;
        FIFO_eop    : in std_logic;
        val_FIFO    : in std_logic;
        rdy_AD_F    : out std_logic;

        -- Cuckoo interface 
        AD          : in std_logic;
        val_hash    : in std_logic;
        rdy_AD_H    : out std_logic

    );
end entity;


architecture behavioral of Accept_Deny is

begin

    

end architecture;