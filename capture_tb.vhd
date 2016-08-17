--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:07:54 06/18/2016
-- Design Name:   
-- Module Name:   /home/cem/Eng/Xilinx/OV7670/Hamster3/capture_tb.vhd
-- Project Name:  Hamster3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ov7670_capture
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
 
ENTITY capture_tb IS
END capture_tb;
 
ARCHITECTURE behavior OF capture_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ov7670_capture
    PORT(
         pclk : IN  std_logic;
         vsync : IN  std_logic;
         href : IN  std_logic;
         d : IN  std_logic_vector(7 downto 0);
			hold_pic : in std_logic;
         addr : OUT  std_logic_vector(14 downto 0);
         dout : OUT  std_logic_vector(7 downto 0);
         we : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal pclk : std_logic := '0';
   signal vsync : std_logic := '0';
   signal href : std_logic := '0';
   signal d : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal addr : std_logic_vector(14 downto 0);
   signal dout : std_logic_vector(7 downto 0);
   signal we : std_logic;
	signal hold_pic : std_logic;

   -- Clock period definitions
   constant pclk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ov7670_capture PORT MAP (
          pclk => pclk,
          vsync => vsync,
          href => href,
          d => d,
			 hold_pic => hold_pic,
          addr => addr,
          dout => dout,
          we => we
        );

   -- Clock process definitions
   pclk_process :process
   begin
		pclk <= '0';
		wait for pclk_period/2;
		pclk <= '1';
		wait for pclk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for pclk_period*10;

      -- insert stimulus here 
      -- insert stimulus here 
		hold_pic <= '0';
		vsync <= '0';
		href <= '0';
		d <= "00000000";
		wait until falling_edge(pclk);	
		vsync <= '1';
		wait for pclk_period*3;
		wait until falling_edge(pclk);
		vsync <= '0';
		
		wait for 10*pclk_period;
		href <= '1';
		
		wait until falling_edge(pclk);
		d <= "11101110";
		wait until falling_edge(pclk);
		d <= "00000111";
		wait until falling_edge(pclk);
		
		wait for 10*pclk_period;
		href <= '0';
		
      wait;
   end process;

END;
