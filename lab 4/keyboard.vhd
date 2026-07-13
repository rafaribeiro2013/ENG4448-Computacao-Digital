library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Layout físico do teclado:
--         COL1  COL2  COL3  COL4
-- ROW1  [  1  ][  2  ][  3  ][ A ]
-- ROW2  [  4  ][  5  ][  6  ][ B ]
-- ROW3  [  7  ][  8  ][  9  ][ C ]
-- ROW4  [  0  ][  F  ][  E  ][ D ]
--
-- Correção: índices de row e col estão espelhados no hardware.
-- row(3) = ROW1 físico, row(0) = ROW4 físico.
-- col(3) = COL1 físico, col(0) = COL4 físico.

entity keyboard is
    port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        row         : in  STD_LOGIC_VECTOR(3 downto 0);
        col         : out STD_LOGIC_VECTOR(3 downto 0);
        key_code    : out STD_LOGIC_VECTOR(3 downto 0);
        key_pressed : out STD_LOGIC
    );
end keyboard;

architecture Behavioral of keyboard is

    type state_type is (SCAN_COL1, SCAN_COL2, SCAN_COL3, SCAN_COL4, KEY_DETECTED);
    signal state, next_state : state_type := SCAN_COL1;

    constant SCAN_DELAY : integer := 250_000;
    signal scan_counter : integer range 0 to SCAN_DELAY := 0;
    signal scan_tick    : STD_LOGIC := '0';

    signal row_debounced         : STD_LOGIC_VECTOR(3 downto 0);
    signal col_reg               : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    signal key_detected_flag     : STD_LOGIC := '0';
    signal key_detected_flag_reg : STD_LOGIC := '0';
    signal key_detected_flag_reg2: STD_LOGIC := '0';
    signal current_key           : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal current_key_reg       : STD_LOGIC_VECTOR(3 downto 0) := "0000";

begin

    -- Debounce para cada linha (ROW)
    debounce_row1 : entity work.debounce(Behavioral)
        port map(clk => clk, reset => reset, sw => row(0), db => row_debounced(0), tick => open);
    debounce_row2 : entity work.debounce(Behavioral)
        port map(clk => clk, reset => reset, sw => row(1), db => row_debounced(1), tick => open);
    debounce_row3 : entity work.debounce(Behavioral)
        port map(clk => clk, reset => reset, sw => row(2), db => row_debounced(2), tick => open);
    debounce_row4 : entity work.debounce(Behavioral)
        port map(clk => clk, reset => reset, sw => row(3), db => row_debounced(3), tick => open);

    -- Gerador de tick de varredura
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                scan_counter <= 0;
                scan_tick    <= '0';
            else
                if scan_counter = SCAN_DELAY - 1 then
                    scan_counter <= 0;
                    scan_tick    <= '1';
                else
                    scan_counter <= scan_counter + 1;
                    scan_tick    <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Registrador de estado
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state                 <= SCAN_COL1;
                key_detected_flag_reg <= '0';
                key_detected_flag_reg2<= '0';
                current_key_reg       <= (others => '0');
            else
                state                 <= next_state;
                key_detected_flag_reg <= key_detected_flag;
                key_detected_flag_reg2<=key_detected_flag_reg;
                -- key_detected_flag_reg  ____------------------------------------------------_______________
                -- key_detected_flag_reg2 _____------------------------------------------------______________
                --                        ____-______________________________________________________________
                --                            key_detected_flag_reg and not key_detected_flag_reg2
                if key_detected_flag = '1' then
                    current_key_reg <= current_key;
                end if;
            end if;
        end if;
    end process;


    process(state, scan_tick, row_debounced)
    begin
        next_state        <= state;
        col_reg           <= "1111";
        key_detected_flag <= key_detected_flag_reg;
        current_key       <= "0000";

        case state is

            when SCAN_COL1 =>               -- ativa col(3) = COL1 físico
                col_reg <= "0111";
                if scan_tick = '1' then
                    if    row_debounced(3) = '0' then -- ROW1+COL1 = '1'
                        current_key <= "0001"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(2) = '0' then -- ROW2+COL1 = '4'
                        current_key <= "0100"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(1) = '0' then -- ROW3+COL1 = '7'
                        current_key <= "0111"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(0) = '0' then -- ROW4+COL1 = '0'
                        current_key <= "0000"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    else
                        next_state <= SCAN_COL2;
                        key_detected_flag <= '0';
                    end if;
                end if;

            when SCAN_COL2 =>               -- ativa col(2) = COL2 físico
                col_reg <= "1011";
                if scan_tick = '1' then
                    if    row_debounced(3) = '0' then -- ROW1+COL2 = '2'
                        current_key <= "0010"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(2) = '0' then -- ROW2+COL2 = '5'
                        current_key <= "0101"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(1) = '0' then -- ROW3+COL2 = '8'
                        current_key <= "1000"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(0) = '0' then -- ROW4+COL2 = 'F'
                        current_key <= "1111"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    else
                        next_state <= SCAN_COL3;
                        key_detected_flag <= '0';
                    end if;
                end if;

            when SCAN_COL3 =>               -- ativa col(1) = COL3 físico
                col_reg <= "1101";
                if scan_tick = '1' then
                    if    row_debounced(3) = '0' then -- ROW1+COL3 = '3'
                        current_key <= "0011"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(2) = '0' then -- ROW2+COL3 = '6'
                        current_key <= "0110"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(1) = '0' then -- ROW3+COL3 = '9'
                        current_key <= "1001"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(0) = '0' then -- ROW4+COL3 = 'E'
                        current_key <= "1110"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    else
                        next_state <= SCAN_COL4;
                        key_detected_flag <= '0';
                    end if;
                end if;

            when SCAN_COL4 =>               -- ativa col(0) = COL4 físico
                col_reg <= "1110";
                if scan_tick = '1' then
                    if    row_debounced(3) = '0' then -- ROW1+COL4 = 'A'
                        current_key <= "1010"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(2) = '0' then -- ROW2+COL4 = 'B'
                        current_key <= "1011"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(1) = '0' then -- ROW3+COL4 = 'C'
                        current_key <= "1100"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    elsif row_debounced(0) = '0' then -- ROW4+COL4 = 'D'
                        current_key <= "1101"; key_detected_flag <= '1'; --next_state <= KEY_DETECTED;
                    else
                        next_state <= SCAN_COL1;
                        key_detected_flag <= '0';
                    end if;
                end if;

            when KEY_DETECTED =>
                key_detected_flag <= '1';
                if row_debounced = "1111" then
                    next_state <= SCAN_COL1;
                end if;

        end case;
    end process;

    col         <= col_reg;
    key_code    <= current_key_reg;
    key_pressed <= key_detected_flag_reg and not key_detected_flag_reg2;

end Behavioral;