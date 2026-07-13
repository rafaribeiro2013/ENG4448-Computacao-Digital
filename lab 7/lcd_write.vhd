library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_write is
    port(
        CLK           : in  STD_LOGIC;
        LCD_INIT_DONE : in  STD_LOGIC;
        LCD_RS        : out STD_LOGIC;
        LCD_E         : out STD_LOGIC;
        DATA          : out STD_LOGIC_VECTOR(3 downto 0)
    );
end lcd_write;

architecture Behavioral of lcd_write is

    type WRITE_DATA_t is array (0 to 27) of std_logic_vector(3 downto 0);
    constant WRITE_DATA : WRITE_DATA_t := (
        0  => x"5", 1  => x"2",  -- 'R' 
        2  => x"6", 3  => x"1",  -- 'a' 
        4  => x"6", 5  => x"6",  -- 'f' 
        6  => x"6", 7  => x"1",  -- 'a' 
        8  => x"6", 9  => x"5",  -- 'e' 
        10 => x"6", 11 => x"c",  -- 'l' 
        12 => x"2", 13 => x"0",  -- ' ' 
        14 => x"6", 15 => x"5",  -- 'e' 
        16 => x"2", 17 => x"0",  -- ' ' 
        18 => x"4", 19 => x"c",  -- 'L' 
        20 => x"7", 21 => x"5",  -- 'u' 
        22 => x"6", 23 => x"9",  -- 'i' 
        24 => x"7", 25 => x"3",  -- 's' 
        26 => x"6", 27 => x"1"   -- 'a' 
    );

    --   write_a (E=1): 12 ciclos  (~240 ns @ 50 MHz)
    --   write_b (E=0): 2000 ciclos (~40 µs  @ 50 MHz)
    constant E_HIGH_CYCLES : unsigned(19 downto 0) := to_unsigned(12,   20);
    constant E_LOW_CYCLES  : unsigned(19 downto 0) := to_unsigned(2000, 20);

    type FSM_t is (idle, write_a, write_b, finish);
    signal state : FSM_t := idle;

    signal counter  : unsigned(19 downto 0) := (others => '0');
    signal idx_data : integer range 0 to 28 := 0;

begin

    sync_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            case state is
                when idle =>
                    LCD_E  <= '0';
                    LCD_RS <= '0';
                    DATA   <= WRITE_DATA(0);

                    if LCD_INIT_DONE = '1' then
                        state    <= write_a;
                        idx_data <= 0;
                        counter  <= (others => '0');
                    end if;

                when write_a =>
                    LCD_RS <= '1';
                    LCD_E  <= '1';
                    DATA   <= WRITE_DATA(idx_data);

                    if counter = E_HIGH_CYCLES then
                        state   <= write_b;
                        counter <= (others => '0');
                    else
                        counter <= counter + 1;
                    end if;

                when write_b =>
                    LCD_RS <= '1';
                    LCD_E  <= '0';

                    if counter = E_LOW_CYCLES then
                        counter <= (others => '0');

                        if idx_data = 27 then
                            state <= finish;
                        else
                            idx_data <= idx_data + 1;
                            state    <= write_a;
                        end if;
                    else
                        counter <= counter + 1;
                    end if;

                when finish =>
                    LCD_E  <= '0';
                    LCD_RS <= '0';

                when others =>
                    state <= idle;

            end case;
        end if;
    end process sync_proc;

end Behavioral;