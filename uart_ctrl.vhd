----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:21:22 08/14/2016 
-- Design Name: 
-- Module Name:    uart_cmd - Behavioral 
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

entity uart_ctrl is port (
	clk_i : in  STD_LOGIC;
   rst_i : in  STD_LOGIC;
	
	uart_cmd_o : out std_logic_vector(7 downto 0);
	uart_arg0_o : out std_logic_vector(7 downto 0);
	uart_arg1_o : out std_logic_vector(7 downto 0);
	uart_byte_rd_i : in std_logic_vector(7 downto 0);
	
	uart_tick_o : out std_logic;
	rom_tick_o : out std_logic;
	xfer_busy_i : in std_logic;
	
	uart_rx_i : in std_logic;
	uart_tx_o : out std_logic);
end uart_ctrl;

architecture Behavioral of uart_ctrl is
	
	-- receive signals
	signal rd_uart : std_logic;
	signal rx_empty : std_logic;
	signal rx_reg : std_logic_vector(7 downto 0);

	-- transmit signals
	signal wr_uart : std_logic;
	signal wr_data : std_logic_vector(7 downto 0);
	
	-- state machine signals 
	type cmd_state_type is (IDLE, CMD_RECEIVED, CMD_ARGS, CMD_EXECUTE, CMD_RESPONSE, CMD_BUSY,
									CMD_BUSY2, CMD_ARGS_DELAY, CMD_ROM, CMD_ROM2);
	signal cmd_state : cmd_state_type;
	
	type arg_file_type is array(7 downto 0) of std_logic_vector(7 downto 0);
	signal uart_arg : arg_file_type;
	
	signal uart_cmd : std_logic_vector(7 downto 0);
	signal num_args : unsigned(2 downto 0);
	signal cnt_args : unsigned(2 downto 0);

	signal uart_tick : std_logic;
	signal rom_tick : std_logic;

begin

	----------------------------------------------
	-- wiring to transmit and receive functions
	----------------------------------------------
	comm1: entity work.UART_BUF port map(
		clk_i => clk_i, 
		rst_i => rst_i,
		
		-- receive signals
		rx_i => uart_rx_i,
		rd_uart_i => rd_uart,
		rx_empty_o => rx_empty,
		rx_data_o => rx_reg,

		-- tx signals
		wr_data_i => wr_data,
		tx_o => uart_tx_o,
		wr_uart_o => wr_uart,
		tx_full_o => open
	);


	-------------------------------------------------
	-- FSM that process serial commands on the uart
	-- Interacts with the camera control module to
	-- read registers, write registers, and initialize
	-- the camera.
	------------------------------------------------
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			wr_uart <= '0';
			rd_uart <= '0';

			case cmd_state is 
				when IDLE =>

					if (rx_empty='0') then
						rd_uart <= '1';
						uart_cmd <= rx_reg;
						cmd_state <= cmd_received;
					end if;
					
				when CMD_RECEIVED =>
					cmd_state <= CMD_ARGS;
					cnt_args <= (others => '0');
					
					case uart_cmd is
						
						when x"10" => num_args <= "000";  -- firmware version
						when x"11" => num_args <= "000";  -- status register
						when x"20" => num_args <= "000";  -- OV7670 Status Register
						when x"21" => num_args <= "010";  -- OV7670 Write Register
						when x"22" => num_args <= "001";  -- OV7670 Read Register
						when x"23" => num_args <= "001";  -- switch test modes of OV7670
						
						-- unknown command
						when others =>
							wr_data <= x"00";
							num_args <= "000";
							
							-- TBD should have error handling routine but will just go to idle for now
							cmd_state <= CMD_RESPONSE;
					end case;
					
				when CMD_ARGS =>
					if (num_args=cnt_args) then
						cmd_state <= CMD_EXECUTE;
					else
						cmd_state <= CMD_ARGS_DELAY;
											
						-- read a character
						if (rx_empty='0') then
							cnt_args <= cnt_args + 1;
							--num_args <= num_args - 1;

							rd_uart <= '1';
							uart_arg(to_integer(cnt_args)) <= rx_reg;
						end if;
					end if;
					
				when CMD_ARGS_DELAY =>
						rd_uart <= '0';
						cmd_state <= CMD_ARGS;
						
				when CMD_EXECUTE =>
					case uart_cmd is
						
						-- firmware version
						when x"10" => 
							cmd_state <= CMD_RESPONSE;
						wr_data <= x"11";
						
						-- status register
						when x"11" =>
							cmd_state <= CMD_RESPONSE;
							wr_data <= x"22";
				
						-- OV7670 Status Register
						when x"20" =>  
							cmd_state <= CMD_RESPONSE;
							wr_data <= x"33";
				
						-- OV7670 Write Register
						when x"21" => 
							uart_tick <= '1';
							cmd_state <= CMD_BUSY;
							wr_data <= x"21";
				
						-- OV7670 Read Register
						when x"22" =>  
							uart_tick <= '1';
							cmd_state <= CMD_BUSY;
							wr_data <= x"22";
				
						-- OV7670 change modes based on arg0 value
						when x"23" =>
							rom_tick <= '1';
							cmd_state <= CMD_ROM;
							wr_data <= x"23";
						
				
						-- unknown command
						when others =>
							
							-- TBD should have error handling routine but will just go to idle for now
							cmd_state <= CMD_RESPONSE;
					end case;
				
				when CMD_BUSY => 
					if xfer_busy_i='1' then
						cmd_state <= CMD_BUSY2;
					end if;

				when CMD_BUSY2 =>					
					uart_tick <= '0';
					if xfer_busy_i='0' then
						wr_data <= uart_byte_rd_i;
						cmd_state <= CMD_RESPONSE;
					end if;
				
				when CMD_ROM =>
					if xfer_busy_i='1' then
						cmd_state <= CMD_ROM2;
					end if;
					
				when CMD_ROM2 =>
					rom_tick <= '0';
					if xfer_busy_i='0' then
						cmd_state <= CMD_RESPONSE;
					end if;
				
				when CMD_RESPONSE => 
					wr_uart <= '1';
					cmd_state <= IDLE;

		end case;
		end if;
	end process;

	-- command/control state machine outputs
	uart_cmd_o <= uart_cmd;
	uart_arg0_o <= uart_arg(0);
	uart_arg1_o <= uart_arg(1);
	uart_tick_o <= uart_tick;
	rom_tick_o <= rom_tick;


end Behavioral;

