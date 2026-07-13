library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAIN is
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        row   : in  STD_LOGIC_VECTOR(3 downto 0); -- ROW4..ROW1  (entradas)
        col   : out STD_LOGIC_VECTOR(3 downto 0); -- COL4..COL1  (saídas de varredura)
        an    : out STD_LOGIC;                     -- seleção do display (0 = direito, 1 = esquerdo)
        sseg  : out STD_LOGIC_VECTOR(6 downto 0)  -- segmentos A-G
    );
end MAIN;

architecture Behavioral of MAIN is

    -- Código da última tecla pressionada e pulso de detecção
    signal key_code    : STD_LOGIC_VECTOR(3 downto 0);
    signal key_pressed : STD_LOGIC := '0';
    
    signal hex0 : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal hex1 : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

    u_keyboard : entity work.keyboard(Behavioral)
        port map (
            clk         => clk,
            reset       => reset,
            row         => row,
            col         => col,
            key_code    => key_code,
            key_pressed => key_pressed
        );

    u_decoder : entity work.decoder(Behavioral)
        port map (
            clk   => clk,
            reset => reset,
            hex0  => hex0,   -- display direito  (dígito atual)
            hex1  => hex1,   -- display esquerdo (dígito anterior)
            an    => an,
            sseg  => sseg
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                hex0 <= (others => '0');
                hex1 <= (others => '0');
            elsif (key_pressed = '1') then
                hex1 <= hex0;
				hex0 <= key_code;
            end if;
        end if;
    end process;
end Behavioral;
