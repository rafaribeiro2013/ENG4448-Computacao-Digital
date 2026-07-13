library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rotary_db is
    Port ( 
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        rot_a  : in  STD_LOGIC;
        rot_b  : in  STD_LOGIC;
        rot_c  : in  STD_LOGIC;
        leds   : out STD_LOGIC_VECTOR (7 downto 0)
    );
end rotary_db;

architecture Behavioral of rotary_db is

    -- Internal filtered signals (output of Xilinx rotary filter)
    signal rotary_in       : STD_LOGIC_VECTOR(1 downto 0);
    signal rotary_q1       : STD_LOGIC := '0';
    signal rotary_q2       : STD_LOGIC := '0';

    -- Direction detection signals
    signal delay_rotary_q1 : STD_LOGIC := '0';
    signal rotary_event    : STD_LOGIC := '0';
    signal rotary_left     : STD_LOGIC := '0';

    -- LED shift register
    signal leds_reg        : STD_LOGIC_VECTOR(7 downto 0) := "10000000";


    -- Push-button (rot_c) debounce via Xilinx-style filter
    -- We use a simple synchronous edge detector for rot_c
    signal rot_c_sync1     : STD_LOGIC := '0';
    signal rot_c_sync2     : STD_LOGIC := '0';
    signal rot_c_prev      : STD_LOGIC := '0';
    signal rot_c_event     : STD_LOGIC := '0';

begin

    -- =========================================================
    -- ROTARY CONTACT FILTER (Xilinx algorithm, pages 7-8)
    -- rotary_q1: XNOR behaviour
    --   Set   ('1') when A=High and B=High
    --   Reset ('0') when A=Low  and B=Low
    --   Hold  otherwise
    -- rotary_q2: XOR behaviour
    --   Set   ('1') when A=Low  and B=High
    --   Reset ('0') when A=High and B=Low
    --   Hold  otherwise
    -- =========================================================
    rotary_filter: process(clk)
    begin
        if rising_edge(clk) then
            rotary_in <= rot_b & rot_a;   -- concatenate: MSB=B, LSB=A

            case rotary_in is
                when "00" =>
                    rotary_q1 <= '0';
                    rotary_q2 <= rotary_q2;   -- hold
                when "01" =>
                    rotary_q1 <= rotary_q1;   -- hold
                    rotary_q2 <= '0';
                when "10" =>
                    rotary_q1 <= rotary_q1;   -- hold
                    rotary_q2 <= '1';
                when "11" =>
                    rotary_q1 <= '1';
                    rotary_q2 <= rotary_q2;   -- hold
                when others =>
                    rotary_q1 <= rotary_q1;
                    rotary_q2 <= rotary_q2;
            end case;
        end if;
    end process rotary_filter;

    -- =========================================================
    -- DIRECTION AND EVENT DETECTION (page 8)
    -- Detect rising edge of rotary_q1 ? one rotation click
    -- rotary_q2 value at that moment indicates direction
    -- =========================================================
    direction: process(clk)
    begin
        if rising_edge(clk) then
            delay_rotary_q1 <= rotary_q1;

            if rotary_q1 = '1' and delay_rotary_q1 = '0' then
                rotary_event <= '1';
                rotary_left  <= rotary_q2;   -- '1' = left, '0' = right
            else
                rotary_event <= '0';
                rotary_left  <= rotary_left;  -- hold
            end if;
        end if;
    end process direction;

    -- =========================================================
    -- PUSH-BUTTON (ROT_C) DEBOUNCE
    -- rot_c on the Spartan-3E board is active-high (connected
    -- to 3.3 V; IOB pull-down used for '0' at rest).
    -- We synchronise the input and detect a rising edge,
    -- identical in style to the rotary filter above.
    -- =========================================================
    pushbutton_filter: process(clk)
    begin
        if rising_edge(clk) then
            -- Two-stage synchroniser to avoid metastability
            rot_c_sync1 <= rot_c;
            rot_c_sync2 <= rot_c_sync1;

            -- Edge detection: fire once on rising edge
            rot_c_prev  <= rot_c_sync2;
            if rot_c_sync2 = '1' and rot_c_prev = '0' then
                rot_c_event <= '1';
            else
                rot_c_event <= '0';
            end if;
        end if;
    end process pushbutton_filter;

    -- =========================================================
    -- LED SHIFT REGISTER (page 9)
    -- rotary_event enables the shift; rotary_left picks direction
    -- rot_c_event inverts all LEDs
    -- =========================================================
    led_drive: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                leds_reg <= "10000000";
            elsif rot_c_event = '1' then
                leds_reg <= not leds_reg;
            elsif rotary_event = '1' then
                if rotary_left = '1' then
                    -- Shift left (towards LD7)
                    leds_reg <= leds_reg(6 downto 0) & leds_reg(7);
                else
                    -- Shift right (towards LD0)
                    leds_reg <= leds_reg(0) & leds_reg(7 downto 1);
                end if;
            end if;
        end if;
    end process led_drive;

    leds <= leds_reg;

end Behavioral;
