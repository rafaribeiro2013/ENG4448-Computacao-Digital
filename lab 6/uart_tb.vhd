LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY uart_tb IS
END uart_tb;
 
ARCHITECTURE behavior OF uart_tb IS 

 
    COMPONENT uart
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         rx : IN  std_logic;
         rx_data : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal rx : std_logic := '1';

 	--Outputs
   signal rx_data : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns; --- 50 MHz
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: uart PORT MAP (
          clk => clk,
          reset => reset,
          rx => rx,
          rx_data => rx_data
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
-- Stimulus process
stim_proc: process
    constant bit_period : time := 2*4340 ns; -- 434 clocks * 20ns
begin		
    -- Reset inicial
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    wait for clk_period*10;
    
    -- IDLE
    rx <= '1';
    wait for bit_period * 2; -- Garante que está em idle
    
    -- START bit
    rx <= '0';
    wait for bit_period;
    
    -- Byte 0x56 ('V') - LSB primeiro
    rx <= '0'; -- bit 0
    wait for bit_period;
    rx <= '1'; -- bit 1
    wait for bit_period;
    rx <= '1'; -- bit 2
    wait for bit_period;
    rx <= '0'; -- bit 3
    wait for bit_period;
    rx <= '1'; -- bit 4
    wait for bit_period;
    rx <= '0'; -- bit 5
    wait for bit_period;
    rx <= '1'; -- bit 6
    wait for bit_period;
    rx <= '0'; -- bit 7
    wait for bit_period;
    
    -- STOP bit
    rx <= '1';
    wait for bit_period * 2;
    
    -- START bit
    rx <= '0';
    wait for bit_period;
    
    -- Byte 0x48 ('H') - LSB primeiro
    rx <= '0'; -- bit 0
    wait for bit_period;
    rx <= '0'; -- bit 1
    wait for bit_period;
    rx <= '0'; -- bit 2
    wait for bit_period;
    rx <= '1'; -- bit 3
    wait for bit_period;
    rx <= '0'; -- bit 4
    wait for bit_period;
    rx <= '0'; -- bit 5
    wait for bit_period;
    rx <= '1'; -- bit 6
    wait for bit_period;
    rx <= '0'; -- bit 7
    wait for bit_period;
    
    -- STOP bit
    rx <= '1';
    wait for bit_period * 2;
    
    -- START bit
    rx <= '0';
    wait for bit_period;
    
    -- Byte 0x44 ('D') - LSB primeiro
    rx <= '0'; -- bit 0
    wait for bit_period;
    rx <= '0'; -- bit 1
    wait for bit_period;
    rx <= '1'; -- bit 2
    wait for bit_period;
    rx <= '0'; -- bit 3
    wait for bit_period;
    rx <= '0'; -- bit 4
    wait for bit_period;
    rx <= '0'; -- bit 5
    wait for bit_period;
    rx <= '1'; -- bit 6
    wait for bit_period;
    rx <= '0'; -- bit 7
    wait for bit_period;
    
    -- STOP bit
    rx <= '1';
    wait for bit_period * 2;
    
    -- START bit
    rx <= '0';
    wait for bit_period;
    
    -- Byte 0x4C ('L') - LSB primeiro
    rx <= '0'; -- bit 0
    wait for bit_period;
    rx <= '0'; -- bit 1
    wait for bit_period;
    rx <= '1'; -- bit 2
    wait for bit_period;
    rx <= '1'; -- bit 3
    wait for bit_period;
    rx <= '0'; -- bit 4
    wait for bit_period;
    rx <= '0'; -- bit 5
    wait for bit_period;
    rx <= '1'; -- bit 6
    wait for bit_period;
    rx <= '0'; -- bit 7
    wait for bit_period;
    
    -- STOP bit
    rx <= '1';
    wait for bit_period * 2;
    
    -- START bit
    rx <= '0';
    wait for bit_period;
    
    -- Byte 0x0A ('\n') - LSB primeiro
    rx <= '0'; -- bit 0
    wait for bit_period;
    rx <= '1'; -- bit 1
    wait for bit_period;
    rx <= '0'; -- bit 2
    wait for bit_period;
    rx <= '1'; -- bit 3
    wait for bit_period;
    rx <= '0'; -- bit 4
    wait for bit_period;
    rx <= '0'; -- bit 5
    wait for bit_period;
    rx <= '0'; -- bit 6
    wait for bit_period;
    rx <= '0'; -- bit 7
    wait for bit_period;
    
    -- STOP bit
    rx <= '1';
    wait for bit_period * 2;
    
    -- Verifica se rx_data = 0x48
    assert rx_data = x"48" 
        report "Erro: Dado recebido incorreto!" 
        severity error;
    
    wait;
end process;

END;
