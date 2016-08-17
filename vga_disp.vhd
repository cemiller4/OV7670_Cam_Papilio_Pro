----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:29:31 08/13/2016 
-- Design Name: 
-- Module Name:    vga_disp - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_disp is Port ( 
	clk_i : in  STD_LOGIC;
	rst_i : in  STD_LOGIC;

	fb_adr_o : out  STD_LOGIC_VECTOR (14 downto 0);
	fb_rgb_i : in std_logic_vector(7 downto 0);

	vga_vsync_o : out  STD_LOGIC;
	vga_hsync_o : out  STD_LOGIC;
	vga_rgb_o : out std_logic_vector(7 downto 0));
end vga_disp;

architecture Behavioral of vga_disp is
	--------------------------------------------------------------
	-- camera dimensions and where to locate it on VGA display
	--------------------------------------------------------------
	constant CAM_RES_X: integer := 160;
	constant CAM_RES_Y: integer := 120;
	constant VID_POS_LEFT: integer := 100;
	constant VID_POS_TOP: integer := 100;
	constant VID_POS_RIGHT: integer := VID_POS_LEFT + CAM_RES_X - 1;
	constant VID_POS_BOTTOM: integer := VID_POS_TOP + CAM_RES_Y - 1;
	
	signal pixel_x_temp : std_logic_vector(10 downto 0);
	signal pixel_y_temp : std_logic_vector(10 downto 0);
	signal pix_x : unsigned(10 downto 0);
	signal pix_y : unsigned(10 downto 0);
   signal fb_adr : unsigned(14 downto 0) := (others => '0');
 
	signal video_on : std_logic;
	signal cam1_on : std_logic;
	signal cam1_border_on : std_logic;
 	signal graph_rgb: std_logic_vector(7 downto 0);
	signal vsync : std_logic;
	
begin

	----------------------------------------------------------	
	-- Determine frame buffer address based on pixel counts
	-- Count the pixels only when video is being displayed.
	---------------------------------------------------------
	process(clk_i)
	begin	
		if rising_edge(clk_i) then
			if (vsync='1') then
				fb_adr <= (others => '0');
			elsif cam1_on = '1' then
				fb_adr <= fb_adr + 1;
			end if;
			
		end if;
	end process;	

	fb_adr_o <= std_logic_vector(fb_adr);


	--------------------------------------------------------------
	-- Graphic generation using Object-Mapped scheme (Pong Chu)
	--------------------------------------------------------------
	-- instantiate VGA sync circuit
	b6: entity work.vga_sync port map(
		clk_i => clk_i, 
		rst_i => '0', 
		vsync_o => vsync, 
		hsync_o => vga_hsync_o,
		video_on_o =>video_on,
		p_tick_o => open, 
		pixel_x_o => pixel_x_temp, 
		pixel_y_o => pixel_y_temp
	);

	pix_x <= unsigned(pixel_x_temp);
	pix_y <= unsigned(pixel_y_temp);


	vga_vsync_o <= vsync;

	cam1_on <=
		'1' when (VID_POS_LEFT<=pix_x) and (pix_x <= VID_POS_RIGHT) and
					(VID_POS_TOP<=pix_y) and (pix_y <= VID_POS_BOTTOM) else
		'0';

	cam1_border_on <= 
		'1' when (((pix_x = (VID_POS_LEFT-1)) or (pix_x = (VID_POS_RIGHT+1))) and  
							(((VID_POS_TOP-1)<=pix_y) and (pix_y <= (VID_POS_BOTTOM+1)))) or
					(((pix_y = (VID_POS_TOP-1)) or (pix_y = (VID_POS_BOTTOM+1))) and
						(VID_POS_LEFT<=pix_x) and (pix_x <= VID_POS_RIGHT))else
		'0';

	
	--------------------------------------------------------------
	-- RGB Multiplexing Circuit
	--------------------------------------------------------------
	process(video_on, cam1_on, fb_rgb_i, cam1_border_on)
	begin
		if video_on='0' then
			graph_rgb <= (others => '0');
		else
			if cam1_on='1' then
				graph_rgb <= fb_rgb_i;
			elsif cam1_border_on='1' then
				graph_rgb <= "11100000";
			else
				graph_rgb <= (others => '0'); --black background
			end if;
		end if;
	end process;
	
	vga_rgb_o <= graph_rgb;
end Behavioral;

