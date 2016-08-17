----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: Captures the pixels coming from the OV760 camera and 
--              Stores them in block RAM
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_capture is port ( 
	cam_pclk_i  : in   STD_LOGIC;
	cam_vsync_i : in   STD_LOGIC;
	cam_href_i  : in   STD_LOGIC;
	cam_data_i    : in   STD_LOGIC_VECTOR (7 downto 0);
	
	-- frame_buffer
	fb_clk_i : in std_logic;
	fb_adr_i : in std_logic_vector(14 downto 0);
	fb_rgb_o : out std_logic_vector(7 downto 0));
end ov7670_capture;

architecture Behavioral of ov7670_capture is
	-- Can think of it as a 160x240 display with 4 bytes per pixel or
	-- you can think of it as 320x240 display with 2 bytes per pixel where you are throwing
	-- out every other pixel to get to 160x240.
	-- The OV7670 spec seems to say there are two bytes per pixel.
	
	constant CAM_RES_X: integer := 160;
	constant CAM_RES_Y: integer := 120;
	constant CAM_PIXELS: integer := CAM_RES_X * CAM_RES_Y;
	constant BYTES_PER_PIXEL: integer := 4;
	
   signal d2,d1    : std_logic_vector(7 downto 0)  := (others => '0');
	signal href1 : std_logic;
   signal byte_cnt    : unsigned(16 downto 0);

   -- signals to connect frame buffer
	signal cam_adr  : std_logic_vector(14 downto 0);
   signal cam_data  : std_logic_vector(7 downto 0);
   signal cam_we    : std_logic_vector(0 downto 0);

begin
   process(cam_pclk_i)
   begin
		-- Couldn't get it to work reading the OV7670 spec.  This is based on Hamter's OV7670 code
		-- that was already working.  Seems like it reads two bytes to get a pixel and 
		-- then throws out the next two bytes.  The camera may be in 320x240 mode and we are just
		-- throwing out every other pixel.  

		-- Counts the number of bytes read and creates the address and data from them.
		if rising_edge(cam_pclk_i) then
			href1 <= cam_href_i;
			d1 <= cam_data_i;
			d2 <= d1;
			
         if cam_vsync_i = '1' then 
				byte_cnt <= (others => '0');
         else       
				if cam_href_i = '1' and byte_cnt < (CAM_PIXELS * BYTES_PER_PIXEL) then  
					byte_cnt <= byte_cnt + 1; 
            end if;
         end if;
       
      end if;
   end process;	

	-- increment address every 4 bytes of data
	cam_adr <= std_logic_vector(byte_cnt(16 downto 2));

	-- I think you want to use registered href1 since it takes two clock to form a pixel.
	--		Otherwise you may lose the last pixel(?).
	-- Want to assert we_o at the same time the second byte is stored into d1.  
	cam_we(0) <= '1' when ((byte_cnt(1 downto 0) = "10") and (href1 = '1')) else '0';

	-- output is red(2:0) + grn(2:0) + blue(2:1) 
	cam_data <= d2(7 downto 5) & d2(2 downto 0) & d1(4 downto 3);	
	
	
	
	---------------------------------------------------------------------
	-- frame buffer with camera on 'A' side and vga on 'B' side
	---------------------------------------------------------------------
	image2 : entity work.frame_buffer PORT MAP (
		clka  => cam_pclk_i,
		wea => cam_we,
		addra => cam_adr,
		dina  => cam_data,

		-- frame buffer 'B' side connected to display (VGA)
		clkb  => fb_clk_i,
		addrb => fb_adr_i,
		doutb => fb_rgb_o
	);

	
end Behavioral;

