--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:27:24 03/18/2026
-- Design Name:   
-- Module Name:   C:/TEMP/lab2_final/parking_tb.vhd
-- Project Name:  lab2_final
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: parking
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
USE ieee.numeric_std.ALL;
 
ENTITY parking_tb IS
END parking_tb;
 
ARCHITECTURE behavior OF parking_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT parking
    PORT(
         a : IN  std_logic;
         b : IN  std_logic;
         clk : IN  std_logic;
         reset : IN  std_logic;
         z : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal a : std_logic := '0';
   signal b : std_logic := '0';
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
   signal z : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: parking PORT MAP (
          a => a,
          b => b,
          clk => clk,
          reset => reset,
          z => z
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      wait for 100 ns;
      for i in 0 to 4 loop -- 5 carros entrando
          a <= '1';
          wait for clk_period;
          b <= '1';
          wait for clk_period;
          a <= '0';
          wait for clk_period;
          b <= '0';
          wait for clk_period;
      end loop;
      for j in 0 to 1 loop -- 2 carros saindo
          b <= '1';
          wait for clk_period;
          a <= '1';
          wait for clk_period;
          b <= '0';
          wait for clk_period;
          a <= '0';
          wait for clk_period;
      end loop;
      -- carro entrando e desistindo
      a <= '1';
      wait for clk_period;
      b <= '1';
      wait for clk_period;
      b <= '0';
      wait for clk_period;
      a <= '0';
      wait for clk_period;
      -- sair 1 carro
      b <= '1';
      wait for clk_period;
      a <= '1';
      wait for clk_period;
      b <= '0';
      wait for clk_period;
      a <= '0';
      wait for clk_period;
      --entrar 1 carro
      a <= '1';
      wait for clk_period;
      b <= '1';
      wait for clk_period;
      a <= '0';
      wait for clk_period;
      b <= '0';
      wait for clk_period;

      wait;
   end process;

END;
