LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY cpu_tb IS
END cpu_tb;
 
ARCHITECTURE behavior OF cpu_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT cpu
    PORT(
         CLK : IN  std_logic;
         RESET : IN  std_logic;
         RAM_DIN : OUT  std_logic_vector(7 downto 0);
         RAM_DOUT : IN  std_logic_vector(7 downto 0);
         RAM_ADDR : OUT  std_logic_vector(7 downto 0);
         RAM_WE : OUT  std_logic;
         LEDS_OUT : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    
   --Inputs
   signal CLK : std_logic := '0';
   signal RESET : std_logic := '0';
   signal RAM_DOUT : std_logic_vector(7 downto 0) := (others => '0');

    --Outputs
   signal RAM_DIN : std_logic_vector(7 downto 0);
   signal RAM_ADDR : std_logic_vector(7 downto 0);
   signal RAM_WE : std_logic;
   signal LEDS_OUT : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
   
   -----------------------------------------------------------------------------
   -- CRIAÇÃO DA MEMÓRIA RAM SIMULADA (256 bytes)
   -----------------------------------------------------------------------------
   type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
   signal memory : ram_type := (
        -- CÓDIGO DO PROGRAMA (Armazenado a partir da posição 0)
        0  => "10001111", -- ld R3, 0x--
        1  => "11111111", --    R3 = 255
        2  => "10000011", -- ld R0, 0x--
        3  => "00110010", --    R0 = 50
        4  => "10000111", -- ld R1, 0x--
        5  => "00010100", --    R1 = 20
        6  => "10001011", -- ld R2, 0x--
        7  => "00000101", --    R2 = 5
        8  => "00000001", -- add R0, R1 -> 70
        9  => "10100011", -- str R0, [R3] => MEM[255] = 70
        10 => "00010001", -- sub R0, R1 -> 50
        11 => "10100011", -- str R0, [R3] => MEM[255] = 50
        12 => "00100100", -- inc R1     -> 21
        13 => "10100111", -- str R1, [R3] => MEM[255] = 21
        14 => "00100001", -- dec R0     -> 49
        15 => "10100011", -- str R0, [R3] => MEM[255] = 49
        16 => "00110001", -- and R0, R1 -> 17
        17 => "10100011", -- str R0, [R3] => MEM[255] = 17
        18 => "01000001", -- or R0, R1  -> 21
        19 => "10100011", -- str R0, [R3] => MEM[255] = 21
        20 => "01010000", -- not R0     -> 234    11101010
        21 => "10100011", -- str R0, [R3] => MEM[255] = 234 
        22 => "01110001", -- ror R0     -> 117    01110101
        23 => "10100011", -- str R0, [R3] => MEM[255] = 117
        24 => "01100001", -- xor R0, R1 -> 96  01100000
        25 => "10100011", -- str R0, [R3] => MEM[255] = 96
        26 => "01110000", -- rol R0     -> 192  11000000
        27 => "10100011", -- str R0, [R3] => MEM[255] = 192
        28 => "01110010", -- lsl R0     -> 128  10000000
        29 => "10100011", -- str R0, [R3] => MEM[255] = 128
        30 => "01110011", -- lsr R0     -> 64 01000000
        31 => "10100011", -- str R0, [R3] => MEM[255] = 64
        others => x"00"
   );
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
   uut: cpu PORT MAP (
          CLK => CLK,
          RESET => RESET,
          RAM_DIN => RAM_DIN,
          RAM_DOUT => RAM_DOUT,
          RAM_ADDR => RAM_ADDR,
          RAM_WE => RAM_WE,
          LEDS_OUT => LEDS_OUT
        );

   -- Processo de geração de Clock
   CLK_process :process
   begin
        CLK <= '0';
        wait for CLK_period/2;
        CLK <= '1';
        wait for CLK_period/2;
   end process;
 
   -----------------------------------------------------------------------------
   -- COMPORTAMENTO DA MEMÓRIA RAM
   -----------------------------------------------------------------------------
   -- Leitura Contínua (O que estiver no RAM_ADDR sai no RAM_DOUT automaticamente)
   RAM_DOUT <= memory(to_integer(unsigned(RAM_ADDR)));
   
   -- Processo Síncrono de Escrita na Memória (Testa o seu RAM_WE e RAM_DIN)
   process(CLK)
   begin
       if rising_edge(CLK) then
           if RAM_WE = '1' then
               memory(to_integer(unsigned(RAM_ADDR))) <= RAM_DIN;
           end if;
       end if;
   end process;

   -----------------------------------------------------------------------------
   -- PROCESSO DE ESTÍMULOS (Controla o Computador)
   -----------------------------------------------------------------------------
   stim_proc: process
   begin        
      -- 1. Inicia segurando o RESET ativo para garantir o estado inicial (FETCH e PC=0)
      RESET <= '1';
      wait for 50 ns;    

      -- 2. Solta o RESET. A partir daqui, a FSM da CPU toma o controle!
      RESET <= '0';
      
      -- 3. Deixe o clock rodar tempo suficiente para o programa chegar no HALT.
      -- Cada instrução leva de 2 a 3 ciclos (Fetch, Decode, (Decode_2), Execute).
      -- Temos 5 instruções, 20 ciclos de clock (200ns) são mais que suficientes.
      wait for 300 ns;

      -- Finaliza a simulação
      wait;
   end process;

END;