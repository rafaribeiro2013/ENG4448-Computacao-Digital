library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is
    port (
        clk   : in STD_LOGIC;
        reset : in STD_LOGIC; 
        rx    : in STD_LOGIC; --entrada serial de dados
        rx_data: out STD_LOGIC_VECTOR(7 DOWNTO 0) --palavra de 8 bits recebida
    );
end uart;

architecture Behavioral of uart is

    -- 2^9 = 512
    constant BAUD_RATE : STD_LOGIC_VECTOR(8 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(434, 9)); -- 50_000_000 Hz / 115_200 Hz divisor para gerar a taxa de transmissão
    SIGNAL COUNTER : UNSIGNED(8 DOWNTO 0) := (OTHERS => '0'); --Contador para gerar o tempo de amostragem baseado no baud rate

	SIGNAL SHIFT_FLAG : STD_LOGIC := '0'; --Pulso que indica quando amostrar o próximo bit
	SIGNAL RECEIVING : STD_LOGIC := '0'; 
	SIGNAL BAUD_RATE_R1 : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '1');
	SIGNAL BIT_COUNTER : UNSIGNED(3 DOWNTO 0) := (OTHERS => '0'); --Conta quantos bits já foram recebidos (0 a 9)
	CONSTANT BIT_LIMIT : UNSIGNED(3 DOWNTO 0) := to_unsigned(9, BIT_COUNTER'length);
	SIGNAL MESSAGE : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '1'); --Registrador de deslocamento de 10 bits (start + 8 dados + stop)
	SIGNAL WORD_OUT_REG : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL FINISH_FLAG : STD_LOGIC := '0';
    
    TYPE fsm_t IS (idle, startbit, rxing, done);
    SIGNAL STATE : fsm_t := idle;
BEGIN
	PROCESS (clk)
	BEGIN
		IF (clk'EVENT AND clk = '1') THEN
			IF (RECEIVING = '1') THEN
				IF (SHIFT_FLAG = '1') THEN
					COUNTER <= (OTHERS => '0');
				ELSE
					COUNTER <= COUNTER + 1;
				END IF;
			ELSE
				COUNTER <= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS;
	SHIFT_FLAG <= '1' WHEN COUNTER = (unsigned(BAUD_RATE_R1) - 1) ELSE '0';
	BAUD_RATE_R1 <= '0' & BAUD_RATE(8 DOWNTO 1) WHEN BIT_COUNTER = "0000" ELSE BAUD_RATE;
    
    
    process (clk)
    begin
        if (clk'EVENT and clk = '1') then
            case state is
                --Aguarda detecção do bit de start (rx  = '0')
                --Quando detecta, vai para STARTBIT
                when idle => 
                    BIT_COUNTER <= (others => '0');
                    if (rx = '0') then -- START bit
                        RECEIVING <= '1';
                        state <= startbit;
                    end if;
                --Aguarda meio período do baud rate (BAUD_RATE/2)
                --Amostra o primeiro bit no meio do período
                --Vai para RXING
                when startbit => 
                    if (SHIFT_FLAG = '1') then -- BAUD RATE/2
                        BIT_COUNTER <= BIT_COUNTER + 1;
                        MESSAGE <= rx & MESSAGE(9 downto 1);
                        state <= rxing;
                    end if;
                --Amostra os próximos bits a cada período completo do baud rate
                --Desloca os bits recebidos para dentro de MESSAGE
                --Continua até receber 10 bits no total (BIT_COUNTER = 9)
                when rxing => 
                    if (SHIFT_FLAG = '1') then -- BAUD RATE
                        BIT_COUNTER <= BIT_COUNTER + 1;
                        MESSAGE <= rx & MESSAGE(9 downto 1);
                        if (FINISH_FLAG = '1') then
                            BIT_COUNTER <= (others => '0');
                            state <= done;
                        end if;
                    end if;
                --Extrai os 8 bits de dados: MESSAGE(8 downto 1) (ignora start e stop)
                --Sinaliza conclusão com RX_DONE = '1
                --Retorna para IDLE
                when done =>
                    if (MESSAGE(8 downto 1) /= x"0D" and MESSAGE(8 downto 1) /= x"0A") then 
                        WORD_OUT_REG <= MESSAGE(8 downto 1);
                    end if;
                    RECEIVING <= '0';
                    state <= idle;
                when others => 
                    state <= idle;
            end case;
        end if;
    end process;
    
    FINISH_FLAG <= '1' when BIT_COUNTER = BIT_LIMIT else '0';
    rx_data <= WORD_OUT_REG;
end Behavioral;
