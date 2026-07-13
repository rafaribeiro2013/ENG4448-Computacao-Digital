LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY keyboard_tb IS
END keyboard_tb;

ARCHITECTURE behavior OF keyboard_tb IS

    COMPONENT keyboard
    PORT(
         clk        : IN  std_logic;
         reset      : IN  std_logic;
         row        : IN  std_logic_vector(3 downto 0);
         col        : OUT std_logic_vector(3 downto 0);
         key_code   : OUT std_logic_vector(3 downto 0);
         key_pressed: OUT std_logic
        );
    END COMPONENT;

    -- Inputs
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0';
    signal row        : std_logic_vector(3 downto 0) := (others => '1');

    -- Outputs
    signal col         : std_logic_vector(3 downto 0);
    signal key_code    : std_logic_vector(3 downto 0);
    signal key_pressed : std_logic;

    -- Clock period: 10 ns = 100 MHz
    constant clk_period : time := 10 ns;

    constant SCAN_DELAY_TIME : time := 250_000 * clk_period;

    constant DEBOUNCE_SETTLE : time := 3 * SCAN_DELAY_TIME;

BEGIN

    uut: keyboard PORT MAP (
          clk         => clk,
          reset       => reset,
          row         => row,
          col         => col,
          key_code    => key_code,
          key_pressed => key_pressed
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
    begin
    
        reset <= '1';
        wait for 10 * clk_period;
        reset <= '0';
        wait for 5 * clk_period;


        wait until col = "1110";
        wait for clk_period;

        row <= "1110";
        wait for DEBOUNCE_SETTLE;

       
        row <= "1111";
        wait for DEBOUNCE_SETTLE;
        

        wait until col = "1101";
        wait for clk_period;

        row <= "1101";
        wait for DEBOUNCE_SETTLE;

        

        row <= "1111";
        wait for DEBOUNCE_SETTLE;


        wait until col = "1011";
        wait for clk_period;

        row <= "1011";
        wait for DEBOUNCE_SETTLE;

        row <= "1111";
        wait for DEBOUNCE_SETTLE;

        wait until col = "0111";
        wait for clk_period;

        row <= "0111";
        wait for DEBOUNCE_SETTLE;


        row <= "1111";
        wait for DEBOUNCE_SETTLE;


        wait until col = "1110";
        wait for clk_period;

        row <= "0111";
        wait for DEBOUNCE_SETTLE;


        row <= "1111";
        wait for DEBOUNCE_SETTLE;

        wait until col = "1011";
        wait for clk_period;

        row <= "0111";
        wait for DEBOUNCE_SETTLE;
        
        row <= "1111";
        wait for DEBOUNCE_SETTLE;

        row <= "1111";
        wait for 2 * SCAN_DELAY_TIME;

        wait until col = "1110";
        wait for clk_period;

        row <= "1110";
        wait for DEBOUNCE_SETTLE / 2;

        reset <= '1';
        wait for 5 * clk_period;
        reset <= '0';
        row   <= "1111";
        wait for 5 * clk_period;

        wait until col = "1101";
        wait for clk_period;

        row <= "0111";
        wait for DEBOUNCE_SETTLE;


        row <= "1111";
        wait for DEBOUNCE_SETTLE;

        wait;

    end process;

END behavior;