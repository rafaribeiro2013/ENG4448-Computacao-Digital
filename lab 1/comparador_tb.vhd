
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY comparador_tb IS
END comparador_tb;
 
ARCHITECTURE behavior OF comparador_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT comparador
    PORT(
         a : IN  std_logic;
         b : IN  std_logic;
         z : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal a : std_logic := '0';
   signal b : std_logic := '0';

 	--Outputs
   signal z : std_logic;
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: comparador PORT MAP (
          a => a,
          b => b,
          z => z
        );
 

   -- Stimulus process
   stim_proc: process
   begin		
      a <= '0';
      b <= '0';
      wait for 100 ns;
      a <= '1';
      b <= '0';
      wait for 100 ns;
      a <= '0';
      b <= '1';
      wait for 100 ns;
      a <= '1';
      b <= '1';
      wait for 100 ns;      

      -- insert stimulus here 

      wait;
   end process;

END;
