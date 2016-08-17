----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:00:02 08/13/2016 
-- Design Name: 
-- Module Name:    cam_ctrl - Behavioral 
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

entity cam_ctrl is Port ( 
	clk_i : in  STD_LOGIC;
	rst_i : in  STD_LOGIC;

	cmd_mode_i : in std_logic_vector(7 downto 0);
	cmd_reg_adr_i : in std_logic_vector(7 downto 0);
	cmd_byte_wr_i : in std_logic_vector(7 downto 0);
	cmd_byte_rd_o : out std_logic_vector(7 downto 0);

	cmd_start_i : in std_logic;
	cmd_busy_o : out std_logic;
	uart_tick_i : in std_logic;

	scio_c_o : out std_logic;
	scio_d_io : inout std_logic
	);
end cam_ctrl;

architecture Behavioral of cam_ctrl is
   -- 42"; -- Device write ID - see top of page 11 of data sheet
	constant CAM_WR_ADR : std_logic_vector(7 downto 0) := x"42"; 
	constant CAM_RD_ADR : std_logic_vector(7 downto 0) := x"43";
	
	TYPE reg_init_type is (OV_DONE, OV_START, OV_WRITE, OV_WAIT, OV_SEND_ONCE);
	signal init_reg, init_next : reg_init_type;
	
	signal ov_addr_reg : unsigned(5 downto 0);
	signal ov_addr_next : unsigned(5 downto 0);


	signal camera_address : std_logic_vector(7 downto 0);
	signal cam_byte_wr : std_logic_vector(7 downto 0);

	signal cam_reg : std_logic_vector(7 downto 0);
	signal cam_send : std_logic;
	signal uart_send : std_logic;

   signal rom_cmd0  : std_logic_vector(15 downto 0);
   signal rom_cmd1  : std_logic_vector(15 downto 0);
	
   signal finished : std_logic := '0';
   signal xfer_busy    : std_logic := '0';
   signal rom_send     : std_logic;

   signal rom_resend : std_logic;
 

begin
	cmd_busy_o <= xfer_busy;
	
	-- TODO make this edge detection 
	X2: entity work.debounce PORT MAP(
		clk => clk_i,
		i   => cmd_start_i,
		o   => rom_resend
	);


	ctrl1: entity work.OV7670_comm port map(
		clk_i => clk_i,
		cam_ip_adr_i => camera_address,
		cam_sub_adr_i => cam_reg,
		cam_byte_wr_i => cam_byte_wr,
		cam_byte_rd_o => cmd_byte_rd_o,

		xfer_start_i => cam_send,
		xfer_busy_o => xfer_busy,

		scio_c_o => scio_c_o,
		scio_d_io => scio_d_io
	);


	-- this ROM initializes all OV7670 registers and turns video on
	rom1: entity work.ov7670_rom(ov7670_video) PORT MAP(
		clk => clk_i,
		addr => std_logic_vector(ov_addr_reg),
		data => rom_cmd0
	);


	-- this ROM switches between video=0, color_bars=1, faded_color_bars=2,
	-- or line-on=3;
	rom2 : entity work.ov7670_mode_rom port map (
		clk => clk_i,
		mode => cmd_reg_adr_i(1 downto 0),
		adr => std_logic_vector(ov_addr_reg(1 downto 0)),
		data => rom_cmd1
	);


	process(clk_i, rst_i)
	begin
		if rst_i='1' then
			-- initialize all registers from ROM
			camera_address <= CAM_WR_ADR;
			cam_reg <= rom_cmd0(15 downto 8);
			cam_byte_wr <= rom_cmd0(7 downto 0);
			cam_send <= rom_send;

		elsif rising_edge(clk_i) then
			case cmd_mode_i is
				-- uart command to write OV7670 register
				when x"21" =>
					camera_address <= CAM_WR_ADR;
					cam_reg <= cmd_reg_adr_i;
					cam_byte_wr <= cmd_byte_wr_i;
					cam_send <= uart_tick_i;
				
				-- uart command to read OV7670 register
				when x"22" =>
					camera_address <= CAM_RD_ADR;
					cam_reg <= cmd_reg_adr_i;
					cam_byte_wr <= (others => '0');
					cam_send <= uart_tick_i;

				-- uart command to change to test display or video
				when x"23" =>
					camera_address <= CAM_WR_ADR;
					cam_reg <= rom_cmd1(15 downto 8);
					cam_byte_wr <= rom_cmd1(7 downto 0);
					cam_send <= rom_send;

				-- initialize all registers from ROM
				when others =>
					camera_address <= CAM_WR_ADR;
					cam_reg <= rom_cmd0(15 downto 8);
					cam_byte_wr <= rom_cmd0(7 downto 0);
					cam_send <= rom_send;
				

			end case;
		end if;
	end process;


	----------------------------------------------------------
	-- OV7670 state machine to initialize registers from ROM 
	----------------------------------------------------------	
	cam_ctrl1: process(clk_i, rst_i)
	begin
		if (rst_i='1') then
			init_reg <= OV_START;
			ov_addr_reg <= (others => '0');
		elsif rising_edge(clk_i) then
			init_reg <= init_next;
			ov_addr_reg <= ov_addr_next;
		end if;
	end process;
	
	
	process(init_reg, xfer_busy, cam_reg, ov_addr_reg, rom_resend)
	begin
		init_next <= init_reg;
		ov_addr_next <= ov_addr_reg;
		rom_send <= '0';

		case init_reg is
			when OV_DONE =>
				ov_addr_next <= (others => '0');

				if (rom_resend='1') then
					init_next <= OV_START;
				end if;
				
			when OV_START =>
				ov_addr_next <= (others => '0');
				init_next <= OV_WRITE;
				
			when OV_WRITE =>
				if (cam_reg /= x"FF") then
					rom_send <= '1';
					if xfer_busy='1' then
						init_next <= OV_WAIT;
					end if;
				else
					init_next <= OV_SEND_ONCE;
				end if;
					
			when OV_WAIT =>
				rom_send <= '0';
				if (xfer_busy='0') then
					init_next <= OV_WRITE;
					ov_addr_next <= ov_addr_reg + 1;
				end if;
				
			when OV_SEND_ONCE =>
				-- checks that ROM_RESEND is low so we don't resend 
				if rom_resend='0' then
					init_next <= OV_DONE;
				end if;
		end case;
	end process;
	
	

	
end Behavioral;

