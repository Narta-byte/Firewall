-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;



-- entity FIFO is
--     generic (depth  : integer := 16);
--     port (
--         clk         : in std_logic;
--         reset       : in std_logic;
--         read_en     : in std_logic; --Reader = '0' when not in use 
--         write_en    : in std_logic; --Writer = '0' when not in use

--         -- Collect Header interface 
--         hdr_dat     : in std_logic_vector(7 downto 0);
--         hdr_sop     : in std_logic;
--         hrd_eop     : in std_logic;
--         val_hdr     : in std_logic; 
--         rdy_FIFO    : out std_logic; 

--         -- Accept/Deny interface 
--         rdy_AD      : in std_logic;
--         dat_FIFO    : out std_logic_vector(7 downto 0);
--         FIFO_sop    : out std_logic;
--         FIFO_eop    : out std_logic;
--         val_FIFO    : out std_logic
--     );
-- end entity;


-- architecture behavioral of FIFO is
    
--     type FILL_UP is (filled, empty);
--     signal currentstate, nextstate: FILL_UP;
   
--     type mem_type is array (0 to depth-1) of std_logic_vector(7 downto 0);
--     signal mem      : mem_type  := (others => (others => '0'));

--     signal readpoint, writepoint : integer   := 0; --Read and write pointer 
--     signal full     : std_logic := '0';

--     --signal all_data : hdr_sop + hdr_dat + hrd_eop;
--     --signal send_pck : std_logic := '0'; 
--    -- type State_type is (readpoint, writepoint );
--    -- signal current_state, next_state : State_type;

-- begin

--     rdy_FIFO <= not(full); 

--     --read_en <= '1' when rdy_FIFO = '1';
--     Clk : process (clk, reset)
--     begin
--         if(reset = '1') then 
--             currentstate <= element_num;
--         end if; 
--     end process;

--     FILL : process (clk, reset)

        

--     begin
--         if (reset = '1') then
--             full        <= '0';
--             val_FIFO    <= '0';
--             dat_FIFO    <= (others => '0');
--             FIFO_sop    <= '0';
--             FIFO_eop    <= '0';
--             element_num := 0;
--             readpoint   <= 0;
--             writepoint  <= 0;
           
--         elsif(rising_edge(clk)) then 
--             if (read_en = '1' and rdy_FIFO='1') then 
--                 dat_FIFO     <= mem(readpoint);
--                 readpoint    <= readpoint + 1; 
--                 element_num  := depth - 1; 
--             end if;
--             if (write_en = '1' and full = '0') then
--                 mem(writepoint) <= hdr_sop + hdr_dat + hrd_eop;
--                 writepoint <= writepoint + 1; 
--                 element_num := element_num + 1; 
--             end if;
    
--             -- When FIFO is full/ready  
--             if (readpoint = depth - 1) then
--             readpoint <= 0;
--             end if;
--             if (writepoint = depth - 1) then
--             writepoint <= 0;            
--             end if;

--             if (element_num = depth) then
--             full <= '1';            
--             else
--             full <= '0';
--             end if;
--     end if;

--     end process;


--     --NEXT_STATE_LOGIC : process (current_state)
--     --begin
--       --  next_state <= current_state;
--         --
--           --  if rising_edge(clk) then
--             --    case(current_state) is
--               --  
--                 --    when rden => if full ='0' then
--                   --      next_state <= mem(rpt);
--                     --end if ;
                        
--                    -- when wren => if full = '1' then
--                    --     next_state <= rden;
--                     --end if ;

--                    -- when others => next_state <= wren;
--                 --
--                 --end case ;
--             --end if ;
--     --end process;
    
    

-- end architecture;