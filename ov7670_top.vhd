----------------------------------------------------------------------------------
-- Description: Top level for the OV7670 camera project.
--
-- OV7670_Serial15:
-- Cleaned up top levels by creating 4 main modules:
-- 1. Image module that creates signals to capture image from OV7670 and then store
--		it in a frame buffer
-- 2. Display module that creates the board and locates the box
-- 3. Control Module that communicates with the OV7670 to initialize and change modes
-- 4. Comm Module that uses a UART to allow user to change modes.  Talks to Control
-- 	module.

-- OV7670_Serial12:
	-- Eliminated some of the experiments including loading OV7670 memory from 
	-- FPGA RAM.  Added command 0x23 where it will change between modes based
	-- on  the 1st argument (0x00=video 0x01=color bards 0x02=faded color bars

-- OV7670_Serial11:
-- write register working.  Command "21 70 4a" or "21 70 ca" switches between 
-- color bars and faded color bars
--
-- 0x48 = color bars
-- 0x49 = faded color bars
-- 0x50 = line-on/line-off
-- 0x51 = video
-- 0x52 = faded color bars loaded from ov7670_reg_mem

-- OV7670_Serial10:
-- Read routine is working.  Command "22 70" displays the contents of OV7670
-- register 0x70 on the 7-seg display.  It also outputs the result on the serial
-- port when you do the next read.  Will fix the serial port delay in next rev.

-- OV7670_Serial9:
-- Need to improve ov7670_comm + sccb module to write more consistently.  Need
-- to get this reading registers.  Changed sccb module to use high-impedance '1'
-- which required adding pull-ups to clock and data.  Seems to work better than
-- when I was driving data with push-pull.  Tried to add read routine but it doesn't
-- seem to be working.

-- OV7670_Serial8:
--Adding state machine to read and write the registers.  Using command based approach.
--0x10 Firmware ID
--0x11 Status Register
--0x20 OV7670 Status Register (bit 0 is busy)
--0x21 OV7670 Write Register, 8-bit address, 16-bit data
--0x22 OV7670 Read Register, 8-bit address
-- Switching to Pong Chu's UART RX/TX routines
--
-- Added OV7670_comm and sccb1 as new I2C routines.  Was able to get them working
-- but not very well.  It seems like you have to hold the button longer to get
-- the mode changes.  It is a start


-- OV7670_Serial7:
-- Attempt to make the OV7670 registers programmable.  Should be able to 
-- leverage MUX setup created in previous versions.  May have to create a
-- more complex serial port routine (Such as Pong Chu's)
-- Switches between faded color barS, color bars, on/off lines, and video.
-- 1. Use CuteCom to send a hex value of 0x48, 0x49, 0x50,  or 0x51 and 
-- 2. then press joystick button to send the ROM image.  
-- Steps added:
-- 1. add memory to command mux
-- 2. create FSM to initialize memory
-- 3. add serial command to use programmable memory


-- OV7670_Serial6:
-- Attempt to make the OV7670 registers programmable.  Had problems so 
-- changed to 4 seven-segment LEDs to display the memory contents.  
-- The memory address to display is programmed thru the serial port.

-- OV7670_Serial5:
-- Combine the 4 ROMS into one file.  Change to one entity definition that has
-- four architectures.  VHDL learning experience, no real difference in code

-- OV7670_Serial4:
-- Adding in four ROMs and mux to switch between four test modes.  Will 
-- duplicate ROM for now, but eventually move to RAM that is programmable for 
-- the different modes.  

-- OV7670_Serial3: 
-- Added ROM to store OV7670 register init values.  This is an initial step towards
-- programmable registers.  A top level FSM was created to take values from ROM and
-- place them in I2C sender
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_top is Port ( 
	-- papilio board interface
	pap_clk32_i        : in    STD_LOGIC;

	pap_uart_rx_i : in STD_LOGIC;
	pap_uart_tx_o : out std_logic;


	-- camera inteface, grouped into system (sys), video (vid), and serial comm (sio)
	cam_sys_xclk_o  : out   STD_LOGIC;
	cam_sys_rst_o : out   STD_LOGIC;
	cam_sys_pwdn_o  : out   STD_LOGIC;

	cam_vid_pclk_i  : in    STD_LOGIC;
	cam_vid_vsync_i : in    STD_LOGIC;
	cam_vid_href_i  : in    STD_LOGIC;
	cam_vid_data_i  : in    STD_LOGIC_VECTOR(7 downto 0);	

	cam_sio_c_o  : out   STD_LOGIC;
	cam_sio_d_io  : inout STD_LOGIC;

	-- logic-wing board:  joystick (joy), vga, and 7-segment (sseg)
	lwing_joy_but_i : in    STD_LOGIC;		-- resend ROM data to OV7670
	lwing_joy_up_i : in std_logic;			-- reset signal

	lwing_vga_rgb_o		:out STD_LOGIC_VECTOR(7 downto 0);
	lwing_vga_hsync_o    : out   STD_LOGIC;
	lwing_vga_vsync_o    : out   STD_LOGIC);
end ov7670_top;

architecture Behavioral of ov7670_top is
	signal clk50 : std_logic;
	signal rst : std_logic;

	---------------------------------------
	-- signals to connect camera image 
	---------------------------------------
   signal fb_adr  : std_logic_vector(14 downto 0);
   signal fb_rgb : std_logic_vector(7 downto 0);
   signal xclk_clk  : std_logic := '0';   
 
	---------------------------------------
	-- signals for the camera control 
	---------------------------------------
	signal xfer_busy : std_logic;
	signal uart_tick : std_logic;
	signal rom_tick : std_logic;

	---------------------------------------
	-- signals for the uart 
	---------------------------------------
	signal uart_cmd : std_logic_vector(7 downto 0);
	signal uart_arg0 : std_logic_vector(7 downto 0);
	signal uart_arg1 : std_logic_vector(7 downto 0);
	signal cam_byte_rd : std_logic_vector(7 downto 0);
	

	
begin
   cam_sys_rst_o <= '1';                   -- Normal mode
   cam_sys_pwdn_o  <= '0';                   -- Power device up

	rst <= not lwing_joy_up_i;

 	------------------------------------------------------------
	-- convert 32MHz Papilio clock to 50MHz internal clock
 	------------------------------------------------------------
	X12 : entity work. DCM32to50 port map(
		-- Clock in ports
		CLK_IN1 => pap_clk32_i,
		-- Clock out ports
		CLK_OUT1 => clk50
	);

	
 	------------------------------------------------------------
	-- divide 50MHz clock by two to get camera clock
 	------------------------------------------------------------
	process(clk50)
   begin
      if rising_edge(clk50) then
         xclk_clk <= not xclk_clk;
		end if;
   end process;
	cam_sys_xclk_o  <= xclk_clk;

	
 	------------------------------------------------------------
	-- Camera video interface with  frame buffer
	------------------------------------------------------------
	image1: entity work.ov7670_capture PORT MAP(
      cam_pclk_i  => cam_vid_pclk_i,
      cam_vsync_i => cam_vid_vsync_i,
      cam_href_i  => cam_vid_href_i,
      cam_data_i  => cam_vid_data_i,
      
		fb_clk_i  => clk50,
      fb_adr_i  => fb_adr,
      fb_rgb_o  => fb_rgb
   );
	

	------------------------------------------------------------
	-- VGA Display interface
	------------------------------------------------------------
	disp1: entity work.vga_disp port map ( 
		clk_i => clk50,
		rst_i => '0',

		fb_adr_o => fb_adr,
		fb_rgb_i => fb_rgb,

		vga_vsync_o => lwing_vga_vsync_o,
		vga_hsync_o => lwing_vga_hsync_o,
		vga_rgb_o => lwing_vga_rgb_o

	);


	------------------------------------------------------------
	-- Camera control and initialization interface
	------------------------------------------------------------
	ctrl1: entity work.cam_ctrl port map (
     clk_i => clk50,
	  rst_i => rst,
		cmd_mode_i => uart_cmd,
		cmd_reg_adr_i => uart_arg0,
		cmd_byte_wr_i => uart_arg1,
		cmd_byte_rd_o => cam_byte_rd, 
	
		cmd_start_i => rom_tick,
		cmd_busy_o => xfer_busy,
		uart_tick_i => uart_tick,
	
		scio_c_o => cam_sio_c_o,
		scio_d_io => cam_sio_d_io
	);




	------------------------------------------------------------
	-- Serial Interface
	------------------------------------------------------------
	comm1: entity work.uart_ctrl port map (
		clk_i => clk50,
		rst_i => rst,
		
		uart_cmd_o => uart_cmd,
		uart_arg0_o => uart_arg0,
		uart_arg1_o => uart_arg1,
		uart_byte_rd_i => cam_byte_rd,
		
		uart_tick_o => uart_tick,
		rom_tick_o => rom_tick,
		xfer_busy_i => xfer_busy,
		
		uart_rx_i => pap_uart_rx_i,
		uart_tx_o => pap_uart_tx_o
	);
	





	
end Behavioral;