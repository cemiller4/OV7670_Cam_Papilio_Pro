----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:47:25 07/01/2016 
-- Design Name: 
-- Module Name:    ov7670_reg_init - Behavioral 
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
use ieee.numeric_std.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ov7670_mode_rom is
  port (
   clk : in std_logic;
	mode : in std_logic_vector(1 downto 0);
	adr : in std_logic_vector(1 downto 0);
	data : out std_logic_vector(15 downto 0)
  );
end ov7670_mode_rom;



------------------------------------------------------------------------
-- Architecture for video
------------------------------------------------------------------------
architecture behave of ov7670_mode_rom is

	type cmd_array is array (0 to 3) of std_logic_vector(15 downto 0);
	type mode_rom is array(0 to 3) of cmd_array;
	
	signal cmd_row : cmd_array;
		
	-- ROM definition
	constant OV7670_MODE: mode_rom := 
	(
				
		-- standard video
		(x"704A", x"7135", x"ffff", x"ffff"),
		
		-- 8-bar color test pattern out of OV7670
		(x"704A", x"71B5", x"ffff", x"ffff"),

		-- fade to gray color bar
		(x"70CA", x"71B5", x"ffff", x"ffff"),
				
		-- line on, line off I think)
		(x"70CA", x"7135", x"ffff", x"ffff")
	);

	
begin

	process(clk)
	begin
		if rising_edge(clk) then
			-- determine which mode we are switching to
			cmd_row <= OV7670_MODE(to_integer(unsigned(mode)));
			
			-- determine which command to send based on the address
			data <= cmd_row(to_integer(unsigned(adr)));
		end if;
	end process;
end behave;
