LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY rotary_db_tb IS
END rotary_db_tb;
 
ARCHITECTURE behavior OF rotary_db_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT rotary_db
    PORT(
         clk   : IN  std_logic;
         reset : IN  std_logic;
         rot_a : IN  std_logic;
         rot_b : IN  std_logic;
         rot_c : IN  std_logic;
         leds  : OUT std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    
   --Inputs
   signal clk   : std_logic := '0';
   signal reset : std_logic := '0';
   signal rot_a : std_logic := '0';
   signal rot_b : std_logic := '0';
   signal rot_c : std_logic := '0';

   --Outputs
   signal leds : std_logic_vector(7 downto 0);

   -- Clock period definitions (100 MHz para bater com 10ns)
   constant clk_period : time := 10 ns;
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
   uut: rotary_db PORT MAP (
          clk   => clk,
          reset => reset,
          rot_a => rot_a,
          rot_b => rot_b,
          rot_c => rot_c,
          leds  => leds
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
      -- 1. Segura o Reset inicial
      reset <= '1';
      wait for 10 ns;    
      reset <= '0';
      wait for clk_period*10;
		
      rot_b <= '1'; wait for 2 ms;
      rot_a <= '1'; wait for 2 ms;
      rot_b <= '0'; wait for 2 ms;
      rot_a <= '0'; wait for 2 ms;
      
      rot_b <= '1'; wait for 2 ms;
      rot_a <= '1'; wait for 2 ms;
      rot_b <= '0'; wait for 2 ms;
      rot_a <= '0'; wait for 2 ms;
      
      rot_c <= '1'; wait for 2 ms;
      rot_c <= '0'; wait for 2 ms;
      
      rot_a <= '1'; wait for 2 ms;
      rot_b <= '1'; wait for 2 ms;
      rot_a <= '0'; wait for 2 ms;
      rot_b <= '0'; wait for 2 ms;

      -- Finaliza a simulação
      wait;
   end process;

END;