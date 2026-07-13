LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY decoder_tb IS
END decoder_tb;
 
ARCHITECTURE behavior OF decoder_tb IS 

    COMPONENT decoder
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         hex0 : IN  std_logic_vector(3 downto 0);
         hex1 : IN  std_logic_vector(3 downto 0);
         an : OUT  std_logic;
         sseg : OUT  std_logic_vector(6 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal hex0 : std_logic_vector(3 downto 0) := (others => '0');
   signal hex1 : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal an : std_logic;
   signal sseg : std_logic_vector(6 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: decoder PORT MAP (
          clk => clk,
          reset => reset,
          hex0 => hex0,
          hex1 => hex1,
          an => an,
          sseg => sseg
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
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
      hex0 <= "0010";
      wait for 100 ns;
      hex1 <= "1001";
      -- insert stimulus here 

      wait;
   end process;

END;
