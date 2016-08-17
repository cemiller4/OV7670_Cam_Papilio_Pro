--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:50:42 07/02/2016
-- Design Name:   
-- Module Name:   /home/cem/Eng/Xilinx/OV7670/OV7670_Serial3/ov7670_top_tb.vhd
-- Project Name:  OV7670_Serial3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ov7670_top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ov7670_top_tb IS
END ov7670_top_tb;
 
ARCHITECTURE behavior OF ov7670_top_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ov7670_top
    PORT(
         clk32 : IN  std_logic;
         OV7670_SIOC : OUT  std_logic;
         OV7670_SIOD : INOUT  std_logic;
         OV7670_RESET : OUT  std_logic;
         OV7670_PWDN : OUT  std_logic;
         OV7670_VSYNC : IN  std_logic;
         OV7670_HREF : IN  std_logic;
         OV7670_PCLK : IN  std_logic;
         OV7670_XCLK : OUT  std_logic;
         OV7670_D : IN  std_logic_vector(7 downto 0);
         vga_rgb : OUT  std_logic_vector(7 downto 0);
         vga_hsync : OUT  std_logic;
         vga_vsync : OUT  std_logic;
         btn_inv : IN  std_logic;
         --led_debug : OUT  std_logic;
			led : out STD_LOGIC_VECTOR(7 downto 0);
			rstn : in std_logic;
         rx : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk32 : std_logic := '0';
   signal OV7670_VSYNC : std_logic := '0';
   signal OV7670_HREF : std_logic := '0';
   signal OV7670_PCLK : std_logic := '0';
   signal OV7670_D : std_logic_vector(7 downto 0) := (others => '0');
   signal btn_inv : std_logic := '0';
   signal rx : std_logic := '0';
	signal rstn: std_logic := '0';

	--BiDirs
   signal OV7670_SIOD : std_logic;

 	--Outputs
   signal OV7670_SIOC : std_logic;
   signal OV7670_RESET : std_logic;
   signal OV7670_PWDN : std_logic;
   signal OV7670_XCLK : std_logic;
   signal vga_rgb : std_logic_vector(7 downto 0);
   signal vga_hsync : std_logic;
   signal vga_vsync : std_logic;
   --signal led_debug : std_logic;
	signal led : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk32_period : time := 10 ns;
   constant OV7670_PCLK_period : time := 10 ns;
   constant OV7670_XCLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ov7670_top PORT MAP (
          clk32 => clk32,
          OV7670_SIOC => OV7670_SIOC,
          OV7670_SIOD => OV7670_SIOD,
          OV7670_RESET => OV7670_RESET,
          OV7670_PWDN => OV7670_PWDN,
          OV7670_VSYNC => OV7670_VSYNC,
          OV7670_HREF => OV7670_HREF,
          OV7670_PCLK => OV7670_PCLK,
          OV7670_XCLK => OV7670_XCLK,
          OV7670_D => OV7670_D,
          vga_rgb => vga_rgb,
          vga_hsync => vga_hsync,
          vga_vsync => vga_vsync,
          btn_inv => btn_inv,
          led => led,
			 rstn => rstn,
          rx => rx
        );

   -- Clock process definitions
   clk32_process :process
   begin
		clk32 <= '0';
		wait for clk32_period/2;
		clk32 <= '1';
		wait for clk32_period/2;
   end process;
 
   OV7670_PCLK_process :process
   begin
		OV7670_PCLK <= '0';
		wait for OV7670_PCLK_period/2;
		OV7670_PCLK <= '1';
		wait for OV7670_PCLK_period/2;
   end process;
 
   OV7670_XCLK_process :process
   begin
		OV7670_XCLK <= '0';
		wait for OV7670_XCLK_period/2;
		OV7670_XCLK <= '1';
		wait for OV7670_XCLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		btn_inv <= '1';

      wait for clk32_period*10;
		rstn <= '0';
		wait for clk32_period;
		rstn <= '1';
      -- insert stimulus here 
		wait for clk32_period*15;
		
		btn_inv <= '0';
		wait for clk32_period*20;
		btn_inv <= '1';
		
      wait;
   end process;

END;
