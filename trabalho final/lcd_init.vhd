library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_init is
    port(
        CLK           : in  STD_LOGIC;
        RESET         : in  STD_LOGIC;
        LCD_RS        : out STD_LOGIC;
        LCD_E         : out STD_LOGIC;
        DATA          : out STD_LOGIC_VECTOR(3 downto 0);
        LCD_INIT_DONE : out STD_LOGIC
    );
end lcd_init;

architecture Behavioral of lcd_init is

    type INIT_DATA_t is array (0 to 3) of std_logic_vector(3 downto 0);
    constant INIT_DATA : INIT_DATA_t := (
        0 => x"3",   
        1 => x"3",   
        2 => x"3",   
        3 => x"2"    
    );

    type CONF_DATA_t is array (0 to 7) of std_logic_vector(3 downto 0);
    constant CONF_DATA : CONF_DATA_t := (
        0 => x"2", 1 => x"8",   -- 0x28
        2 => x"0", 3 => x"6",   -- 0x06
        4 => x"0", 5 => x"F",   -- 0x0F
        6 => x"0", 7 => x"1"    -- 0x01
    );

    type TIME_DATA_t is array (0 to 24) of unsigned(19 downto 0);
    constant TIME_DATA : TIME_DATA_t := (
        -- INIT (índices 0..8)
        0  => to_unsigned(750000, 20),  -- espera inicial = 15 ms
        1  => to_unsigned(12,     20),  -- enable alto   = 230 ns
        2  => to_unsigned(205000, 20),  -- espera        = 4,1 ms
        3  => to_unsigned(12,     20),  -- enable alto
        4  => to_unsigned(5000,   20),  -- espera        = 100 µs
        5  => to_unsigned(12,     20),  -- enable alto
        6  => to_unsigned(2000,   20),  -- espera        = 40 µs
        7  => to_unsigned(12,     20),  -- enable alto (nibble 0x2)
        8  => to_unsigned(2000,   20),  -- espera        = 40 µs

        -- CONF - cada comando: E_alto(12), espera_nibble(50), E_alto(12), espera_cmd(2000)
        9  => to_unsigned(12,    20),
        10 => to_unsigned(50,    20),
        11 => to_unsigned(12,    20),
        12 => to_unsigned(2000,  20),

        13 => to_unsigned(12,    20),
        14 => to_unsigned(50,    20),
        15 => to_unsigned(12,    20),
        16 => to_unsigned(2000,  20),

        17 => to_unsigned(12,    20),
        18 => to_unsigned(50,    20),
        19 => to_unsigned(12,    20),
        20 => to_unsigned(2000,  20),

        21 => to_unsigned(12,    20),
        22 => to_unsigned(50,    20),
        23 => to_unsigned(12,    20),
        24 => to_unsigned(82000, 20)   -- = 1,64 ms após Clear
    );

    type FSM_t is (idle, init_a, init_b, conf_a, conf_b, done_st);
    signal state : FSM_t := idle;

    signal counter       : unsigned(19 downto 0) := (others => '0');
    signal counter_limit : unsigned(19 downto 0) := TIME_DATA(0);
    signal idx           : integer range 0 to 24  := 0;
    signal idx_data      : integer range 0 to 7   := 0;

begin

    LCD_RS <= '0';

    sync_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then
                state         <= idle;
                counter       <= (others => '0');
                idx           <= 0;
                idx_data      <= 0;
                LCD_E         <= '0';
                DATA          <= INIT_DATA(0);
                LCD_INIT_DONE <= '0';
                counter_limit <= TIME_DATA(0);
            else
                case state is
                    when idle =>
                        LCD_E        <= '0';
                        DATA         <= INIT_DATA(0);
                        LCD_INIT_DONE <= '0';
                        counter_limit <= TIME_DATA(0);

                        if counter = counter_limit then
                            state   <= init_a;
                            idx     <= 1;         
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when init_a =>
                        LCD_E         <= '1';
                        counter_limit <= TIME_DATA(idx);

                        if counter = counter_limit then
                            state   <= init_b;
                            idx     <= idx + 1;
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when init_b =>
                        LCD_E         <= '0';
                        counter_limit <= TIME_DATA(idx);

                        if counter = counter_limit then
                            counter  <= (others => '0');
                            idx      <= idx + 1;

                            if idx = 8 then
                                state    <= conf_a;
                                idx_data <= 0;
                                DATA     <= CONF_DATA(0);
                            else
                                idx_data <= idx_data + 1;
                                DATA     <= INIT_DATA(idx_data + 1);
                                state    <= init_a;
                            end if;
                        else
                            counter <= counter + 1;
                        end if;
                        
                    when conf_a =>
                        LCD_E         <= '1';
                        counter_limit <= TIME_DATA(idx);

                        if counter = counter_limit then
                            state   <= conf_b;
                            idx     <= idx + 1;
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;
                        
                    when conf_b =>
                        LCD_E         <= '0';
                        counter_limit <= TIME_DATA(idx);

                        if counter = counter_limit then
                            counter  <= (others => '0');
                            idx      <= idx + 1;

                            if idx = 24 then
                                state         <= done_st;
                                LCD_INIT_DONE <= '1';
                            else
                                idx_data <= idx_data + 1;
                                DATA     <= CONF_DATA(idx_data + 1);
                                state    <= conf_a;
                            end if;
                        else
                            counter <= counter + 1;
                        end if;

                    when done_st =>
                        LCD_E         <= '0';
                        LCD_INIT_DONE <= '1';

                    when others =>
                        state <= idle;

                end case;
            end if;
        end if;
    end process sync_proc;

end Behavioral;