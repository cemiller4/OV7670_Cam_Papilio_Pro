----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:13:52 07/30/2016 
-- Design Name: 
-- Module Name:    UART_BUF - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_BUF is port(
	clk_i : in std_logic;
	rst_i : in std_logic;

	-- receive signals
	rx_i : in std_logic;
	rd_uart_i : in std_logic;
	rx_empty_o : out std_logic;
	rx_data_o : out std_logic_vector(7 downto 0);

	-- transmit signals
	wr_data_i : in std_logic_vector(7 downto 0);
	tx_o : out std_logic;
	wr_uart_o : in std_logic;
	tx_full_o : out std_logic);
end UART_BUF;


architecture Behavioral of UART_BUF is
	signal baud_tick : std_logic;
	signal baud_reg : unsigned(8 downto 0); -- 324 needed for 50MHz clock and 9600 baud

	signal rx_empty_ff : std_logic;
	signal rx_buf_reg : std_logic_vector(7 downto 0);
	signal rx_done_tick : std_logic;
	signal dout : std_logic_vector(7 downto 0);
	
	-- tx signals
	signal tx_done_tick : std_logic;
	signal tx_fifo_not_empty : std_logic;
	signal tx_fifo_out : std_logic_vector(7 downto 0);
	signal tx_empty : std_logic;
	
begin
	-- Pong Chu's implementation of UART RX with one-word buffer
	rx1: entity work.uart_rx 
		port map(
			clk_i => clk_i, 
			reset_i => rst_i, 
			rx_i => rx_i, 
			s_tick_i => baud_tick,
			rx_done_tick_o => rx_done_tick,
			dout_o => dout
		);

	
		-- register to capture received data
		-- after byte received by uart_rx, the byte is moved into a 
		-- register so it isn't overwritten
		process(clk_i, rst_i)
		begin
			if rst_i='1' then
				rx_empty_ff <= '0';
				rx_buf_reg <= (others => '0');
			elsif rising_edge(clk_i) then
				if rx_done_tick='1' then
					rx_empty_ff <= '0';
					rx_buf_reg <= dout;
				elsif rd_uart_i='1' then
					rx_empty_ff <= '1';
				end if;
			end if;			
		end process;
		
		rx_empty_o <= rx_empty_ff;
		rx_data_o <= rx_buf_reg;
		
		
		-- mod-m counter to create UART tick timer
		-- 50MHz/(16*baud_rate) = 325
		process(clk_i, rst_i)
		begin
			if rst_i='1' then
				baud_reg <= (others => '0');
				baud_tick <= '0';
			elsif rising_edge(clk_i) then
				if (baud_reg=324) then
					baud_reg <= (others => '0');
					baud_tick <= '1';
				else
					baud_reg <= baud_reg + 1;
					baud_tick <= '0';
				end if;
			end if;
		end process;



--=========================================================
-- UART TX with FIFO
--=========================================================
	tx1 : entity work.uart_tx 
	port map	(
		clk_i => clk_i,
		reset_i => rst_i,

		din_i => wr_data_i,
		tx_done_tick_o => open,
		tx_start_i => wr_uart_o,
		
		tx_o => tx_o,
		s_tick_i => baud_tick
	);
	
	

	
 
		
end Behavioral;

