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

entity ov7670_rom is
  port (
	clk : in std_logic;
	addr : in std_logic_vector(5 downto 0);
	data : out std_logic_vector(15 downto 0)
  );
end ov7670_rom;



------------------------------------------------------------------------
-- Architecture for video
------------------------------------------------------------------------
architecture ov7670_video of ov7670_rom is
	constant ADDR_WIDTH: integer:=6;
	constant DATA_WIDTH: integer:=16;
	signal addr_reg: std_logic_vector(ADDR_WIDTH-1 downto 0);
	type rom_type is array (0 to 2**ADDR_WIDTH-1)
		of std_logic_vector(DATA_WIDTH-1 downto 0);
		
	-- ROM definition
	constant ROM: rom_type := (
		x"1280",	 -- COM7   Reset
      x"1280", -- COM7   Reset
      x"1100", -- CLKRC  Prescaler - Fin/(1+1)
      x"1204", -- COM7   QIF + RGB output
      x"0C04", -- COM3  Lots of stuff, enable scaling, all others off
      x"3E19", -- COM14  PCLK scaling = 0
            
      x"4010", -- COM15  Full 0-255 output, RGB 565
      x"3a04", -- TSLB   Set UV ordering,  do not auto-reset window
      x"8C00", -- RGB444 Set RGB format
            
      x"1714", -- HSTART HREF start (high 8 bits)
      x"1802", -- HSTOP  HREF stop (high 8 bits)
      x"32A4", -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
      x"1903", -- VSTART VSYNC start (high 8 bits)
      x"1A7b", -- VSTOP  VSYNC stop (high 8 bits) 
      x"030a", -- VREF   VSYNC low two bits
            
      x"703a", -- SCALING_XSC
      x"7135", -- SCALING_YSC
      x"7211", -- SCALING_DCWCTR
      x"73f1", -- SCALING_PCLK_DIV
      x"a202", -- SCALING_PCLK_DELAY  PCLK scaling = 4, must match COM14
            
      x"1500", -- COM10 Use HREF not hSYNC
		x"7a20", -- SLOP
      x"7b10", -- GAM1
      x"7c1e", -- GAM2
      x"7d35", -- GAM3
      x"7e5a", -- GAM4
      x"7f69", -- GAM5
      x"8076", -- GAM6
      x"8180", -- GAM7
      x"8288", -- GAM8
      x"838f", -- GAM9
      x"8496", -- GAM10
      x"85a3", -- GAM11
      x"86af", -- GAM12
      x"87c4", -- GAM13
      x"88d7", -- GAM14
      x"89e8", -- GAM15
      x"13E0", -- COM8 - AGC, White balance
      x"0000", -- GAIN AGC 
      x"1000", -- AECH Exposure
      x"0D40", -- COMM4 - Window Size
      x"1418", -- COMM9 AGC 
      x"a505", -- AECGMAX banding filter step
      x"2495", -- AEW AGC Stable upper limite
      x"2533", -- AEB AGC Stable lower limi
      x"26e3", -- VPT AGC fast mode limits
      x"9f78", -- HRL High reference level
      x"A068", -- LRL low reference level
      x"a103", -- DSPC3 DSP control
      x"A6d8", -- LPH Lower Prob High
      x"A7d8", -- UPL Upper Prob Low
      x"A8f0", -- TPL Total Prob Low
      x"A990", -- TPH Total Prob High
      x"AA94", -- NALG AEC Algo select
      x"13E5", -- COM8 AGC Settings
				
		-- Uncomment below two lines to get standard video
		x"704A",
		x"7135",
				
		-- Uncomment below two lines to get the 8-bar color test pattern out of OV7670
		--x"704A",
		--x"71B5",

		-- Uncomment below two lines to get fade to gray color bar
		--x"70CA", 
		--x"71B5",
				
		-- Uncomment below two lines to get Shifting '1' test pattern (line on, line off I think)
		--x"70CA",
		--x"7135",

		-- end of registers
      x"ffff",
      x"ffff",
      x"ffff",
      x"ffff",
      x"ffff",
      x"ffff",
		x"ffff");
	
begin
	process(clk)
	begin
		if(clk'event and clk='1') then
			addr_reg <= addr;
		end if;
	end process;
	data <= ROM(to_integer(unsigned(addr_reg)));

end ov7670_video;
