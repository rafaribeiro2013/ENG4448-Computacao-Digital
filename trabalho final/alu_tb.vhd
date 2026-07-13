LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY alu_tb IS
END alu_tb;
 
ARCHITECTURE behavior OF alu_tb IS 
 
    COMPONENT alu
    PORT(
         A        : IN  unsigned(7 downto 0);
         B        : IN  unsigned(7 downto 0);
         COMANDO  : IN  std_logic_vector(3 downto 0);
         R        : OUT unsigned(7 downto 0);
         ZERO     : OUT std_logic;
         SINAL    : OUT std_logic;
         OVERFLOW : OUT std_logic;
         EQUAL    : OUT std_logic;
         GREATER  : OUT std_logic;
         SMALLER  : OUT std_logic
        );
    END COMPONENT;
    
   signal A       : unsigned(7 downto 0) := (others => '0');
   signal B       : unsigned(7 downto 0) := (others => '0');
   signal COMANDO : std_logic_vector(3 downto 0) := (others => '0');

   signal R        : unsigned(7 downto 0);
   signal ZERO     : std_logic;
   signal SINAL    : std_logic;
   signal OVERFLOW : std_logic;
   signal EQUAL    : std_logic;
   signal GREATER  : std_logic;
   signal SMALLER  : std_logic;
 
   constant clock_period : time := 10 ns;
 
BEGIN

   uut: alu PORT MAP (
          A => A,
          B => B,
          COMANDO => COMANDO,
          R => R,
          ZERO => ZERO,
          SINAL => SINAL,
          OVERFLOW => OVERFLOW,
          EQUAL => EQUAL,
          GREATER => GREATER,
          SMALLER => SMALLER
        );

   -- Processo de estímulos
   stim_proc: process
   begin        
      wait for 100 ns;    

      -- Teste EQUAL e ZERO
      A <= to_unsigned(0, 8); 
      B <= to_unsigned(0, 8);
      COMANDO <= "0000"; -- ADD
      wait for 100 ns;
      -- NOTA: Aqui ZERO deve ser '1' (pois A=0) e EQUAL deve ser '1' (A=B)

      -- Teste GREATER
      A <= to_unsigned(50, 8);
      B <= to_unsigned(20, 8);
      wait for 100 ns;

      -- Teste SMALLER
      A <= to_unsigned(10, 8);
      B <= to_unsigned(100, 8);
      wait for 100 ns;

      -- ADD (Soma Normal)
      A <= to_unsigned(10, 8);
      B <= to_unsigned(15, 8);
      COMANDO <= "0000"; 
      wait for 100 ns; -- R deve ser 25

      -- ADD (Com Overflow)
      A <= to_unsigned(200, 8);
      B <= to_unsigned(100, 8);
      COMANDO <= "0000"; 
      wait for 100 ns; -- R deve perder dados, OVERFLOW deve ser '1'

      -- SUB (Subtração Normal)
      A <= to_unsigned(50, 8);
      B <= to_unsigned(20, 8);
      COMANDO <= "0001"; 
      wait for 100 ns; -- R deve ser 30

      -- SUB (Com Underflow)
      A <= to_unsigned(10, 8);
      B <= to_unsigned(20, 8);
      COMANDO <= "0001"; 
      wait for 100 ns; -- OVERFLOW deve ser '1', SINAL deve ser '1' (pois < 0)

      -- INC (Incremento)
      A <= to_unsigned(5, 8);
      COMANDO <= "0010"; 
      wait for 100 ns; -- R deve ser 6

      -- DEC (Decremento)
      A <= to_unsigned(5, 8);
      COMANDO <= "1010"; 
      wait for 100 ns; -- R deve ser 4

      A <= "10101010";
      B <= "11001100";
      
      -- AND
      COMANDO <= "0011"; 
      wait for 100 ns; -- R deve ser "10001000"

      -- OR
      COMANDO <= "0100"; 
      wait for 100 ns; -- R deve ser "11101110"

      -- NOT
      COMANDO <= "0101"; 
      wait for 100 ns; -- R deve ser "01010101"

      -- XOR
      COMANDO <= "0110"; 
      wait for 100 ns; -- R deve ser "01100110"

      A <= "10000001";
      
      -- ROL (Rotate Left)
      COMANDO <= "0111"; 
      wait for 100 ns; -- R deve ser "00000011"

      -- ROR (Rotate Right)
      COMANDO <= "1000"; 
      wait for 100 ns; -- R deve ser "11000000"

      -- LSL (Logical Shift Left)
      COMANDO <= "1001"; 
      wait for 100 ns; -- R deve ser "00000010"

      -- LSR (Logical Shift Right)
      COMANDO <= "1011"; 
      wait for 100 ns; -- R deve ser "01000000"
      
      -- Fim da simulação
      wait;
   end process;

END;