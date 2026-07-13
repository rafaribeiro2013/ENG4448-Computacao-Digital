--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   08:14:17 05/30/2022
-- Design Name:   
-- Module Name:  
-- Project Name:
-- Target Device:  
-- Tool versions:  
-- Description:   
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
 
ENTITY adc_module_tb IS
END adc_module_tb;
 
ARCHITECTURE behavior OF adc_module_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT adc_module
    PORT(
         CLK : IN  std_logic;
         RESET : IN  std_logic;
         SPI_MISO : IN  std_logic;
         AD_CONV : OUT  std_logic;
         LEDS : OUT  std_logic_vector(7 downto 0);
         SPI_MOSI : OUT  std_logic;
         AMP_CS : OUT  std_logic;
         SPI_SCK : OUT  std_logic;
         SPI_SS_B : OUT  std_logic;
         SF_CE0 : OUT  std_logic;
         FPGA_INIT_B : OUT  std_logic;
         DAC_CS : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RESET : std_logic := '0';
   signal SPI_MISO : std_logic := '0';

 	--Outputs
   signal AD_CONV : std_logic;
   signal LEDS : std_logic_vector(7 downto 0);
   signal SPI_MOSI : std_logic;
   signal AMP_CS : std_logic;
   signal SPI_SCK : std_logic;
   signal SPI_SS_B : std_logic;
   signal SF_CE0 : std_logic;
   signal FPGA_INIT_B : std_logic;
   signal DAC_CS : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adc_module PORT MAP (
          CLK => CLK,
          RESET => RESET,
          SPI_MISO => SPI_MISO,
          AD_CONV => AD_CONV,
          LEDS => LEDS,
          SPI_MOSI => SPI_MOSI,
          AMP_CS => AMP_CS,
          SPI_SCK => SPI_SCK,
          SPI_SS_B => SPI_SS_B,
          SF_CE0 => SF_CE0,
          FPGA_INIT_B => FPGA_INIT_B,
          DAC_CS => DAC_CS
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
