library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_v1 is
    port(
        clk, reset : in  STD_LOGIC;
        sw         : in  STD_LOGIC;
        db         : out STD_LOGIC;
        tick       : out STD_LOGIC
    );
end debounce_v1;

architecture Behavioral of debounce_v1 is

    -- 50 MHz * 2 ms = 100000 (necessita de 17 bits)
    signal counter     : unsigned (16 downto 0) := (others => '0');
    constant counter_1 : unsigned (16 downto 0) := to_unsigned (50_000_000 * 2 / 1000, 17);
    
    signal dff         : std_logic_vector (1 downto 0) := (others => '0');
    signal counter_set : std_logic := '0';
    signal result      : std_logic := '0';
    signal tick_reg    : std_logic := '0';
    
    type state_machine is (zero, one);
    signal state       : state_machine := zero;

begin

    counter_set <= dff(0) xor dff(1);

    process (clk, reset)
    begin
        if reset = '1' then
            dff <= (others => '0');
            counter <= (others => '0');
            result <= '0';
        elsif rising_edge(clk) then
            dff(0) <= sw;
            dff(1) <= dff(0);
            
            if (counter_set = '1') then
                counter <= (others => '0');
            elsif (counter < counter_1) then
                counter <= counter + 1;
            else
                result <= dff(1);
            end if;
        end if;
    end process;

    tick_proc: process(clk, reset)
    begin
        if reset = '1' then
            state <= zero;
            tick_reg <= '0';
        elsif rising_edge(clk) then
            tick_reg <= '0';
            case state is
                when zero =>
                    if (result = '1') then
                        tick_reg <= '1';
                        state <= one;
                    end if;
                when one =>
                    if (result = '0') then
                        state <= zero;
                    end if;
                when others =>
                    state <= zero;
            end case;
        end if;
    end process;

    db <= result;
    tick <= tick_reg;

end Behavioral;
