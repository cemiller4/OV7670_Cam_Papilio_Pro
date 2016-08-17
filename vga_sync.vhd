-- Listing 12.1
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity vga_sync is port(
	clk_i: in std_logic; 
	rst_i: in std_logic;
	hsync_o: out std_logic;
	vsync_o: out std_logic;
	video_on_o: out std_logic;
	p_tick_o: out std_logic;
	pixel_x_o: out std_logic_vector(10 downto 0);
	pixel_y_o: out std_logic_vector (10 downto 0));
end vga_sync;

architecture arch of vga_sync is
   -- VGA 800x600 60Hz, 40MHz pixel clock sync parameters
   constant HD: integer:=800; --horizontal display area
   constant HF: integer:=40 ; --h. front porch
   constant HB: integer:=88 ; --h. back porch
   constant HR: integer:=128 ; --h. retrace
   constant VD: integer:=600; --vertical display area
   constant VF: integer:=1;  --v. front porch
   constant VB: integer:=23;  --v. back porch
   constant VR: integer:=4;   --v. retrace
   -- mod-2 counter
   signal mod2_reg, mod2_next: std_logic;
   -- sync counters
   signal v_count_reg, v_count_next: unsigned(10 downto 0);
   signal h_count_reg, h_count_next: unsigned(10 downto 0);
   -- output buffer
   signal v_sync_reg, h_sync_reg: std_logic;
   signal v_sync_next, h_sync_next: std_logic;
   -- status signal
   signal h_end, v_end, pixel_tick: std_logic;
begin
   -- registers
   process (clk_i,rst_i)
   begin
      if rst_i='1' then
         mod2_reg <= '0';
         v_count_reg <= (others=>'0');
         h_count_reg <= (others=>'0');
         v_sync_reg <= '0';
         h_sync_reg <= '0';
      elsif rising_edge(clk_i) then
         mod2_reg <= mod2_next;
         v_count_reg <= v_count_next;
         h_count_reg <= h_count_next;
         v_sync_reg <= v_sync_next;
         h_sync_reg <= h_sync_next;
      end if;
   end process;
	
   -- mod-2 circuit to generate 25 MHz enable tick
   mod2_next <= not mod2_reg;
   
	-- 25 MHz pixel tick
   pixel_tick <= '1' when mod2_reg='1' else '0';
   
	-- status
   h_end <=  -- end of horizontal counter
      '1' when h_count_reg=(HD+HF+HB+HR-1) else --799
      '0';

   v_end <=  -- end of vertical counter
      '1' when v_count_reg=(VD+VF+VB+VR-1) else --524
      '0';

   -- mod-800 horizontal sync counter
   process (h_count_reg,h_end,pixel_tick)
   begin
         if h_end='1' then
            h_count_next <= (others=>'0');
         else
            h_count_next <= h_count_reg + 1;
         end if;
   end process;


   -- mod-525 vertical sync counter
   process (v_count_reg,h_end,v_end,pixel_tick)
   begin
      if h_end='1' then
         if (v_end='1') then
            v_count_next <= (others=>'0');
         else
            v_count_next <= v_count_reg + 1;
         end if;
      else
         v_count_next <= v_count_reg;
      end if;
   end process;

   -- horizontal and vertical sync, buffered to avoid glitch
   h_sync_next <=
      '1' when (h_count_reg>=(HD+HF))           --656
           and (h_count_reg<=(HD+HF+HR-1)) else --751
      '0';

   v_sync_next <=
      '1' when (v_count_reg>=(VD+VF))           --490
           and (v_count_reg<=(VD+VF+VR-1)) else --491
      '0';

   -- video on/off
   video_on_o <=
      '1' when (h_count_reg<HD) and (v_count_reg<VD) else
      '0';

   -- output signal
   hsync_o <= h_sync_reg;
   vsync_o <= v_sync_reg;
   pixel_x_o <= std_logic_vector(h_count_reg);
   pixel_y_o <= std_logic_vector(v_count_reg);
   p_tick_o <= pixel_tick;
	
end arch;
