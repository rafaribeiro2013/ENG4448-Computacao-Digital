library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ps2 is
end tb_ps2;

architecture Behavioral of tb_ps2 is

    -- UUT
    component ps2
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            ps2_clk  : in  STD_LOGIC;
            ps2_data : in  STD_LOGIC;
            rx_done  : out STD_LOGIC;
            rx_data  : out STD_LOGIC_VECTOR(7 downto 0);
            led_erro : out STD_LOGIC
        );
    end component;

    -- Clock do sistema: 50 MHz -> período = 20 ns
    constant CLK_PERIOD  : time := 20 ns;
    -- Clock PS/2: ~25 kHz -> período = 40 µs -> half = 20 µs
    constant PS2_HALF    : time := 20 us;

    signal clk_tb      : STD_LOGIC := '0';
    signal reset_tb    : STD_LOGIC := '1';
    signal ps2_clk_tb  : STD_LOGIC := '1';
    signal ps2_data_tb : STD_LOGIC := '1';
    signal rx_done_tb  : STD_LOGIC;
    signal rx_data_tb  : STD_LOGIC_VECTOR(7 downto 0);
    signal led_erro_tb : STD_LOGIC;

    -- Envia um quadro PS/2 de 11 bits:
    --   frame(0)   = start (deve ser '0')
    --   frame(8:1) = dados (LSB primeiro)
    --   frame(9)   = paridade ímpar
    --   frame(10)  = stop  (deve ser '1')
    procedure send_ps2_frame (
        signal ps2c : out STD_LOGIC;
        signal ps2d : out STD_LOGIC;
        data        : in  STD_LOGIC_VECTOR(7 downto 0);
        bad_parity  : in  BOOLEAN
    ) is
        variable frame   : STD_LOGIC_VECTOR(10 downto 0);
        variable parity  : STD_LOGIC;
    begin
        -- Calcula paridade ímpar: XOR de todos os bits de dados
        parity := data(0) xor data(1) xor data(2) xor data(3) xor
                  data(4) xor data(5) xor data(6) xor data(7);
        parity := not parity;  -- ímpar -> complementa para garantir XOR total = 1

        -- Inverte se deve testar erro
        if bad_parity then
            parity := not parity;
        end if;

        -- Monta frame: [0]=start, [8:1]=dados, [9]=paridade, [10]=stop
        frame(0)          := '0';        -- start
        frame(8 downto 1) := data;       -- dados LSB first
        frame(9)          := parity;     -- paridade
        frame(10)         := '1';        -- stop

        -- Envia cada bit na borda de descida do PS2_CLK
        for i in 0 to 10 loop
            ps2d <= frame(i);
            wait for PS2_HALF;
            ps2c <= '0';          -- borda de descida: host lê aqui
            wait for PS2_HALF;
            ps2c <= '1';          -- borda de subida
        end loop;

        -- Pausa entre quadros (linha ociosa)
        wait for 5 * PS2_HALF;
    end procedure;

begin

    -- Instancia DUT
    DUT: ps2
        port map (
            clk      => clk_tb,
            reset    => reset_tb,
            ps2_clk  => ps2_clk_tb,
            ps2_data => ps2_data_tb,
            rx_done  => rx_done_tb,
            rx_data  => rx_data_tb,
            led_erro => led_erro_tb
        );

    -- Clock do sistema (50 MHz)
    clk_tb <= not clk_tb after CLK_PERIOD / 2;

    -- Estímulos
    process
    begin
        -- Reset inicial
        reset_tb <= '1';
        wait for 200 ns;
        reset_tb <= '0';
        wait for 100 ns;

        -- ------------------------------------------------
        -- Quadro 1: tecla 'A' (scan code 0x1C) - paridade OK
        -- Esperado: rx_done='1', rx_data=0x1C, led_erro='0'
        -- ------------------------------------------------
        report "Enviando scan code 0x1C (tecla A) - paridade correta";
        send_ps2_frame(ps2_clk_tb, ps2_data_tb, X"1C", false);
        wait for 10 * CLK_PERIOD;

        -- ------------------------------------------------
        -- Quadro 2: tecla 'A' (scan code 0x1C) - paridade ERRADA
        -- Esperado: rx_done='0', led_erro='1'
        -- ------------------------------------------------
        report "Enviando scan code 0x1C - paridade ERRADA";
        send_ps2_frame(ps2_clk_tb, ps2_data_tb, X"1C", true);
        wait for 10 * CLK_PERIOD;

        -- ------------------------------------------------
        -- Quadro 3: tecla Shift esquerdo (scan code 0x12)
        -- ------------------------------------------------
        report "Enviando scan code 0x12 (Shift esq.) - paridade correta";
        send_ps2_frame(ps2_clk_tb, ps2_data_tb, X"12", false);
        wait for 10 * CLK_PERIOD;

        -- ------------------------------------------------
        -- Quadro 4: key-up code 0xF0 (tecla solta)
        -- ------------------------------------------------
        report "Enviando key-up code 0xF0";
        send_ps2_frame(ps2_clk_tb, ps2_data_tb, X"F0", false);
        wait for 10 * CLK_PERIOD;

        report "Simulacao concluida.";
        wait;
    end process;

end Behavioral;