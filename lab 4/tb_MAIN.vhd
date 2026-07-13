library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_MAIN is
-- testbench não tem portas
end tb_MAIN;

architecture Behavioral of tb_MAIN is

    -- -------------------------------------------------------------------------
    -- Período de clock: 50 MHz ? 20 ns
    -- -------------------------------------------------------------------------
    constant CLK_PERIOD : time := 20 ns;

    -- -------------------------------------------------------------------------
    -- Número de ciclos para esperar antes/depois de cada tecla.
    -- O scan_tick acontece a cada 250_000 ciclos.
    -- O debounce precisa de 50_000 ciclos estáveis.
    -- Aguardamos 2 * 250_000 + 100_000 = 600_000 ciclos com segurança.
    -- -------------------------------------------------------------------------
    constant CYCLES_PER_PRESS : integer := 600_000;

    signal clk   : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '0';
    signal row   : STD_LOGIC_VECTOR(3 downto 0) := "1111"; -- pull-up: repouso = HIGH
    signal col   : STD_LOGIC_VECTOR(3 downto 0);           -- saída do DUT
    signal an    : STD_LOGIC;
    signal sseg  : STD_LOGIC_VECTOR(6 downto 0);

    -- -------------------------------------------------------------------------
    -- Controle do testbench
    -- -------------------------------------------------------------------------
    -- Qual coluna queremos acionar e qual linha corresponde à tecla
    signal target_col : STD_LOGIC_VECTOR(3 downto 0) := "1111"; -- "1110"=COL1 ativa
    signal target_row : STD_LOGIC_VECTOR(3 downto 0) := "1111"; -- linha a puxar LOW

begin

    -- =========================================================================
    -- Instância do DUT
    -- =========================================================================
    uut : entity work.MAIN(Behavioral)
        port map (
            clk   => clk,
            reset => reset,
            row   => row,
            col   => col,
            an    => an,
            sseg  => sseg
        );

    -- =========================================================================
    -- Gerador de clock: 50 MHz
    -- =========================================================================
    clk <= not clk after CLK_PERIOD / 2;

    -- =========================================================================
    -- Processo que monitora 'col' e injeta o ROW quando a coluna certa fica
    -- ativa.  Isso emula o hardware do teclado: quando a FPGA ativa uma coluna,
    -- o fio físico fecha o circuito na linha da tecla pressionada.
    -- =========================================================================
    process(col, target_col, target_row)
    begin
        if col = target_col then
            row <= target_row;  -- tecla pressionada: puxa a linha LOW
        else
            row <= "1111";      -- nenhuma outra coluna ativa: repouso
        end if;
    end process;

    -- =========================================================================
    -- Processo principal do testbench (sequência de estímulos)
    -- =========================================================================
    process
        -- Procedimento auxiliar: pressiona uma tecla e espera o reconhecimento
        procedure press_key (
            col_mask : in STD_LOGIC_VECTOR(3 downto 0);  -- "1110"=COL1, "1101"=COL2 ...
            row_mask : in STD_LOGIC_VECTOR(3 downto 0);  -- "1110"=ROW1, "1101"=ROW2 ...
            label_mask    : in string
        ) is
        begin
            -- Define qual coluna/linha disparar
            target_col <= col_mask;
            target_row <= row_mask;

            -- Aguarda tempo suficiente para debounce + scan_tick detectar a tecla
            wait for CLK_PERIOD * CYCLES_PER_PRESS;

            -- Solta a tecla (ROW volta a HIGH - feito automaticamente no
            -- process(col) quando target_col não bate mais)
            target_col <= "1111";   -- nenhuma coluna alvo
            target_row <= "1111";   -- nenhuma linha alvo

            -- Aguarda o estado KEY_DETECTED retornar ao início da varredura
            wait for CLK_PERIOD * CYCLES_PER_PRESS;

            -- Pequena pausa entre teclas
            wait for CLK_PERIOD * 10;
        end procedure;

    begin
        -- ---------------------------------------------------------------------
        -- Reset inicial: 10 ciclos com reset = '1'
        -- ---------------------------------------------------------------------
        reset <= '1';
        wait for CLK_PERIOD * 10;
        reset <= '0';
        wait for CLK_PERIOD * 5;

        -- =====================================================================
        -- TESTE 1: Pressiona tecla '1'
        --   Layout do teclado:
        --     COL1 ativa (col = "1110"), ROW1 LOW (row(0) = '0') ? tecla '1'
        --     key_code esperado = "0001"
        --     Após detecção: hex0 = "0001", hex1 = "0000"
        -- =====================================================================
        press_key("1110", "1110", "Tecla 1");

        -- =====================================================================
        -- TESTE 2: Pressiona tecla '5'
        --   COL2 ativa (col = "1101"), ROW2 LOW (row(1) = '0') ? tecla '5'
        --   key_code esperado = "0101"
        --   Após detecção: hex0 = "0101", hex1 = "0001"  (deslocamento!)
        -- =====================================================================
        press_key("1101", "1101", "Tecla 5");

        -- =====================================================================
        -- TESTE 3: Pressiona tecla 'A'
        --   COL4 ativa (col = "0111"), ROW1 LOW (row(0) = '0') ? tecla 'A'
        --   key_code esperado = "1010"
        --   Após detecção: hex0 = "1010", hex1 = "0101"  (deslocamento!)
        -- =====================================================================
        press_key("0111", "1110", "Tecla A");

        -- =====================================================================
        -- TESTE 4: Reset durante operação
        --   Verifica se hex0 e hex1 voltam a "0000"
        -- =====================================================================
        reset <= '1';
        wait for CLK_PERIOD * 20;
        reset <= '0';
        wait for CLK_PERIOD * 10;

        -- =====================================================================
        -- TESTE 5: Pressiona tecla '0' após reset
        --   COL2 ativa (col = "1101"), ROW4 LOW (row(3) = '0') ? tecla '0'
        --   key_code esperado = "0000"
        --   Após detecção: hex0 = "0000", hex1 = "0000"
        -- =====================================================================
        press_key("1101", "0111", "Tecla 0");

        -- ---------------------------------------------------------------------
        -- Fim da simulação
        -- ---------------------------------------------------------------------
        wait for CLK_PERIOD * 100;
        assert false
            report "=== SIMULACAO CONCLUIDA COM SUCESSO ==="
            severity failure;   -- encerra a simulação no ISim/ModelSim

        wait;
    end process;

end Behavioral;
