LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY comparador2bits_tb IS
END comparador2bits_tb;
 
ARCHITECTURE behavior OF comparador2bits_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT comparador2bits
    PORT(
         a : IN  std_logic_vector(1 downto 0);
         b : IN  std_logic_vector(1 downto 0);
         z : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal a : std_logic_vector(1 downto 0) := (others => '0');
   signal b : std_logic_vector(1 downto 0) := (others => '0');

 	--Outputs
   signal z : std_logic;
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: comparador2bits PORT MAP (
          a => a,
          b => b,
          z => z
        );

   -- Stimulus process
   stim_proc: process
   begin		
      for I_A in 0 to 3 loop
        a <= std_logic_vector(to_unsigned(I_A, 2));
        for I_B in 0 to 3 loop
            b <= std_logic_vector(to_unsigned(I_B, 2));
            wait for 10 ns;
        end loop;
      end loop;
      wait;
   end process;

END;
