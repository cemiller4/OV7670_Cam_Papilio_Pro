----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:55:03 08/05/2016 
-- Design Name: 
-- Module Name:    OV7670_comm - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity OV7670_comm is Port ( 
	clk_i : in  STD_LOGIC;

	cam_ip_adr_i : in  STD_LOGIC_VECTOR (7 downto 0);
	cam_sub_adr_i : in  STD_LOGIC_VECTOR (7 downto 0);
	cam_byte_wr_i : in  STD_LOGIC_VECTOR (7 downto 0);
	cam_byte_rd_o : out  STD_LOGIC_VECTOR (7 downto 0);

	xfer_start_i : in  STD_LOGIC;
	xfer_busy_o : out  STD_LOGIC;

	-- passthru from sccb module
	scio_c_o : out std_logic;
	scio_d_io : inout std_logic);
end OV7670_comm;

architecture Behavioral of OV7670_comm is
--	signal scio_c : std_logic;
--	signal scio_d : std_logic;
	signal cam_ip_adr : std_logic_vector(7 downto 0);
	signal cam_sub_adr : std_logic_vector(7 downto 0);
	signal cam_byte_wr : std_logic_vector(7 downto 0);
	signal cam_byte_rd : std_logic_vector(7 downto 0);
	
		
	signal sccb_rd_wrn : std_logic;
	signal start_bit : std_logic;
	signal ack_bit : std_logic;
	signal stop_bit : std_logic;
	
	signal sccb_start : std_logic;
	signal sccb_busy : std_logic;
	
	signal xfer_busy : std_logic;
	signal sccb_byte_rd : std_logic_vector(7 downto 0);
	signal sccb_byte_wr : std_logic_vector(7 downto 0);

	type comm_state_type is (IDLE, COMM_RD_WR, COMM_WR_TX_PH1, COMM_WR_TX_PH2, COMM_WR_TX_PH3,
									COMM_WR_TX_PH1_BUSY, COMM_WR_TX_PH2_BUSY, COMM_WR_TX_PH3_BUSY,
									COMM_RD_TX_PH1, COMM_RD_TX_PH2, COMM_RD_RX_PH1, COMM_RD_RX_PH2,
									COMM_RD_TX_PH1_BUSY, COMM_RD_TX_PH2_BUSY, COMM_RD_RX_PH1_BUSY,
									COMM_RD_RX_PH2_BUSY, COMM_RD_RX_DONE);
	signal comm_state, comm_state_prev : comm_state_type;

	
begin
	xfer_busy_o <= xfer_busy;
	cam_byte_rd_o <= cam_byte_rd;
	
	-- data read from sccb module directly wired to camera module
	
	sccb1: entity work.ov7670_sccb1 port map( 
		clk_i => clk_i,

		-- serial pins
		scio_c_o => scio_c_o,
		scio_d_io  => scio_d_io,

		-- parallel data pins
		sccb_byte_wr_i  => sccb_byte_wr,
		sccb_byte_rd_o  => sccb_byte_rd,

		-- configuration inputs
		sccb_rd_wrn_i  => sccb_rd_wrn,
		start_bit_i  => start_bit,
		ack_bit_i  => ack_bit,
		stop_bit_i  => stop_bit,

		-- control and status
		sccb_start_i => sccb_start,
		sccb_busy_o => sccb_busy,
		ack_o  => open
	);




	process(clk_i)
	begin
		if rising_edge(clk_i) then
			--xfer_busy <= '1';
	
				case comm_state is
					when IDLE =>
						sccb_start <= '0'; -- this is an initialization
						xfer_busy <= '0';
						
						if xfer_start_i='1' then
							-- latch data
								cam_ip_adr <= cam_ip_adr_i;
								cam_sub_adr <= cam_sub_adr_i;
								cam_byte_wr <= cam_byte_wr_i;
								xfer_busy <= '1';
								comm_state <= COMM_RD_WR;
						end if;
					
					when COMM_RD_WR =>
						--xfer_busy <= '0';
						
						-- determine if read or write
						if cam_ip_adr(0) = '0' then
							comm_state <= COMM_WR_TX_PH1;
						else
							comm_state <= COMM_RD_TX_PH1;
						end if;
					
					
					
					-- OV7670 Register Write
					--
					when COMM_WR_TX_PH1 =>
						sccb_byte_wr <= cam_ip_adr;
						sccb_rd_wrn <= '0';
						start_bit <= '1';
						ack_bit <= '0';
						stop_bit <= '0';
						
						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_WR_TX_PH1_BUSY;
						end if;

					when COMM_WR_TX_PH1_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							comm_state <= COMM_WR_TX_PH2;
						end if;
					
					
					when COMM_WR_TX_PH2 =>
						sccb_byte_wr <= cam_sub_adr;
						sccb_rd_wrn <= '0';
						start_bit <= '0';
						ack_bit <= '0';
						stop_bit <= '0';

						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_WR_TX_PH2_BUSY;
						end if;

					when COMM_WR_TX_PH2_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							comm_state <= COMM_WR_TX_PH3;
						end if;
					
											
					when COMM_WR_TX_PH3 =>
						sccb_byte_wr <= cam_byte_wr;
						sccb_rd_wrn <= '0';
						start_bit <= '0';
						ack_bit <= '0';
						stop_bit <= '1';

						-- issue start and wait for it sccb to indicate busy
						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_WR_TX_PH3_BUSY;
						end if;
					
					when COMM_WR_TX_PH3_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							comm_state <= IDLE;
						end if;
					
					-- 8-bit register read of OV7670
					-- consists of two transactions:
					-- 1st:  start + ph1(IP_write_address) + ph2(sub address) + stop
					-- 2nd:  start + ph1(IP_read_address) + ph2(read data) + stop 
					when COMM_RD_TX_PH1 =>
						sccb_byte_wr <= cam_ip_adr(7 downto 1) & '0';
						sccb_rd_wrn <= '0';
						start_bit <= '1';
						ack_bit <= '0';
						stop_bit <= '0';

						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_RD_TX_PH1_BUSY;
						end if;

					when COMM_RD_TX_PH1_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							comm_state <= COMM_RD_TX_PH2;
						end if;
				
					when COMM_RD_TX_PH2 =>
						sccb_byte_wr <= cam_sub_adr;
						sccb_rd_wrn <= '0';
						start_bit <= '0';
						ack_bit <= '0';
						stop_bit <= '1';

						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_RD_TX_PH2_BUSY;
						end if;

					when COMM_RD_TX_PH2_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							comm_state <= COMM_RD_RX_PH1;
						end if;
				
					when COMM_RD_RX_PH1 =>
						sccb_byte_wr <= cam_ip_adr;
						sccb_rd_wrn <= '0';
						start_bit <= '1';
						ack_bit <= '0';
						stop_bit <= '0';

						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_RD_RX_PH1_BUSY;
						end if;

					when COMM_RD_RX_PH1_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							comm_state <= COMM_RD_RX_PH2;
						end if;
					
					when COMM_RD_RX_PH2 =>
						sccb_rd_wrn <= '1';
						start_bit <= '0';
						ack_bit <= '1';
						stop_bit <= '1';

						sccb_start <= '1';
						if sccb_busy='1' then
							comm_state <= COMM_RD_RX_PH2_BUSY;
						end if;

					when COMM_RD_RX_PH2_BUSY =>
						sccb_start <= '0';
						if sccb_busy='0' then
							cam_byte_rd <= sccb_byte_rd;
							comm_state <= COMM_RD_RX_DONE;
						end if;
						
					when COMM_RD_RX_DONE => 
						cam_byte_rd <= sccb_byte_rd;
						comm_state <= IDLE;
						
				end case;
			end if;
	end process;


end Behavioral;

