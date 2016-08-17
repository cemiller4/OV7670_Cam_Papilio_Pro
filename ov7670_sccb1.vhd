----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:46:08 08/05/2016 
-- Design Name: 
-- Module Name:    ov7670_sccb1 - Behavioral 
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

entity ov7670_sccb1 is Port ( 
	clk_i : in  STD_LOGIC;

	-- serial pins
	scio_c_o : out  STD_LOGIC;
	scio_d_io : inout  STD_LOGIC;

	-- parallel data pins
	sccb_byte_wr_i : in  STD_LOGIC_VECTOR (7 downto 0);
	sccb_byte_rd_o : out  STD_LOGIC_VECTOR (7 downto 0);

	-- configuration inputs
	sccb_rd_wrn_i : in std_logic;
	start_bit_i : in  STD_LOGIC;
	ack_bit_i : in  STD_LOGIC;
	stop_bit_i : in  STD_LOGIC;

	-- control and status
	sccb_start_i : in  STD_LOGIC;
	sccb_busy_o : out  STD_LOGIC;
	ack_o : out  STD_LOGIC);
end ov7670_sccb1;

architecture Behavioral of ov7670_sccb1 is
	signal scio_c : std_logic;
	signal scio_d : std_logic;
	signal ack : std_logic;
	signal busy : std_logic;
	signal tick_sccb : std_logic;
	signal sccb_byte_rd : std_logic_vector(7 downto 0);
	signal sccb_byte_wr : std_logic_vector(7 downto 0);

	type sccb_state_type is (SCCB_IDLE, SCCB_START, SCCB_START2, SCCB_DATA, SCCB_DATA2, SCCB_ACK, SCCB_ACK2,
										SCCB_STOP, SCCB_STOP2, SCCB_STOP3, SCCB_BUS_FREE, SCCB_START_ZERO);
	signal sccb_state : sccb_state_type;
	
	signal num_bits : unsigned(2 downto 0);
	signal clk_div_reg : unsigned(8 downto 0);
	
	signal start_sccb : std_logic;
	signal ack_z : std_logic;

	type edge_state_type  is (one, zero);
	signal edge_reg, edge_next : edge_state_type;
	signal edge_tick : std_logic;
	
begin
		scio_c_o <= scio_c;
		scio_d_io <= 'Z' when ((ack_z='1') or (scio_d='1')) else '0';
		ack_o <= ack;
		sccb_busy_o <= busy;
		sccb_byte_rd_o <= sccb_byte_rd;
		
		process(clk_i)
		begin
			
			if rising_edge(clk_i) then
				--ack <= '0';
				--busy <= '1'; 
				

				if tick_sccb='1' then
					case sccb_state is

						-------------------------------------
						-- SCCB Idle
						-------------------------------------
						when SCCB_IDLE =>
							--scio_c <= '1';
							--scio_d <= '1';
							ack_z <= '0';
							busy <= '0';
							
						   if sccb_start_i='1' then
								busy <= '1';
								sccb_byte_wr <= sccb_byte_wr_i;
								--sccb_byte_rd <= (others => '0');
								num_bits <= (others => '0');
								
								if start_bit_i='1' then
									sccb_state <= SCCB_START;
								else
									sccb_state <= SCCB_DATA;
								end if;
							end if;
							
						-------------------------------------
						-- SCCB Start Bit
						-------------------------------------
						when SCCB_START =>
							scio_c <= '1';
							scio_d <= '1';
							sccb_state <= SCCB_START2;

						when SCCB_START2 =>
							scio_c <= '1';
							scio_d <= '0';
							sccb_state <= SCCB_DATA;


						-------------------------------------
						-- SCCB Data Bits
						-------------------------------------
						when SCCB_DATA =>
							scio_c <= '0';
							sccb_state <= SCCB_DATA2;
							
							if sccb_rd_wrn_i='1' then
								ack_z <= '1';
								--sccb_byte_rd <= sccb_byte_rd(6 downto 0) & scio_d;
							else
								scio_d <= sccb_byte_wr(7);
							end if;
						
						when SCCB_DATA2 =>
							scio_c <= '1';
							
							if sccb_rd_wrn_i='1' then
								ack_z <= '1';
								sccb_byte_rd <= sccb_byte_rd(6 downto 0) & scio_d_io;
							else
								scio_d <= sccb_byte_wr(7);
							end if;
						
							if num_bits=7 then
								sccb_state <= SCCB_ACK;
							else
								sccb_state <= SCCB_DATA;

								num_bits <= num_bits + 1;
								sccb_byte_wr <= sccb_byte_wr(6 downto 0) & '0';
							end if;
							
						-------------------------------------
						-- SCCB Acknowledge Bit
						-------------------------------------
						when SCCB_ACK =>
							scio_c <= '0';
							
							
							if sccb_rd_wrn_i='1' then
								ack_z <= '0';
								if ack_bit_i='1' then
									scio_d <= '1';  -- want to acknowledge we read the data
								else
									scio_d <= '0';
								end if;
							else
								ack_z <= '1';	-- high-impedance to allow camera to ack
								ack <= scio_d;
							end if;

							sccb_state <= SCCB_ACK2;
							
						when SCCB_ACK2 =>
							scio_c <= '1';

							if sccb_rd_wrn_i='1' then
								if ack_bit_i='1' then
									scio_d <= '1';  -- want to acknowledge we read the data
								else
									scio_d <= '0';
								end if;
							else
								ack_z <= '1';	-- high-impedance to allow camera to ack
								ack <= scio_d;
								scio_d <= '0'; -- set scio_d to zero so stop condition can be initiated
							end if;

							if stop_bit_i='1' then
								sccb_state <= SCCB_STOP;
							else
								sccb_state <= SCCB_IDLE;
							end if;

						-------------------------------------
						-- SCCB Stop Bit
						-------------------------------------							
						when SCCB_STOP =>
							ack_z <= '0';
							scio_d <= '0';
							scio_c <= '0'; -- need clock low so data can transition(?)
							sccb_state <= SCCB_STOP2;
							
						when SCCB_STOP2 =>
							scio_d <= '0';
							scio_c <= '1';
							sccb_state <= SCCB_STOP3;

						when SCCB_STOP3 =>
							scio_d <= '1';
							scio_c <= '1';
							sccb_state <= SCCB_BUS_FREE;

						
						-------------------------------------
						-- SCCB Bus Free
						-------------------------------------
						when SCCB_BUS_FREE =>
							scio_d <= '1';
							scio_c <= '1';
							sccb_state <= SCCB_START_ZERO;
							
						when SCCB_START_ZERO =>
							-- sit here until start goes low to prevent resending
							if sccb_start_i='0' then
								sccb_state <= SCCB_IDLE;
							end if;
						
					end case;
				end if;
			end if;
		end process;

		----------------------------------------------
		-- mod-m counter to create UART tick timer
		-- two ticks per clock
		-- 50MHz/2/(200kHz) = 125
		----------------------------------------------		
		process(clk_i)
		begin
			if rising_edge(clk_i) then
				if ((clk_div_reg=124) or (edge_tick='1')) then
					clk_div_reg <= (others => '0');
					tick_sccb <= '1';
				else
					clk_div_reg <= clk_div_reg + 1;
					tick_sccb <= '0';
				end if;
			end if;
		end process;

	process(clk_i)
	begin
		edge_reg <= edge_next;
	end process;

	


	process(edge_reg, sccb_start_i)
	begin
		edge_next <= edge_reg;
		edge_tick <= '0';
		
		case edge_reg is 
			when zero =>
				if sccb_start_i='1' then
					edge_next <= one;
					edge_tick <= '1';
				end if;	
			when one =>
				if sccb_start_i='0' then
					edge_next  <= zero;
				end if;
		
		end case;
	end process;

end Behavioral;

