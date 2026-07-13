library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
entity VGA_CTRL is
	generic (
		h_pol : STD_LOGIC := '0'; --horizontal sync pulse polarity (1 = positive, 0 = negative)
		h_pixels : natural := 800; --horizontal display width in pixels
		h_fp : natural := 40; --horizontal front porch width in pixels
		h_pulse : natural := 128; --horizontal sync pulse width in pixels
		h_bp : natural := 88; --horizontal back porch width in pixels
        
		v_pol : STD_LOGIC := '0'; --vertical sync pulse polarity (1 = positive, 0 = negative)
		v_pixels : natural := 600; --vertical display width in rows
		v_fp : natural := 1; --vertical front porch width in rows
		v_pulse : natural := 4; --vertical sync pulse width in rows
		v_bp : natural := 23 --vertical back porch width in rows
	);
	port (
		pixel_clock : in STD_LOGIC; --pixel clock
		h_sync : out STD_LOGIC; --horizontal sync pulse
		v_sync : out STD_LOGIC; --vertical sync pulse
		display_on : out STD_LOGIC; --display enable ('1' = display time, '0' = blanking time)
		pixel_x : out natural; --horizontal pixel coordinate
		pixel_y : out natural --vertical pixel coordinate
	);
end VGA_CTRL;
architecture Behavioral of VGA_CTRL is
	constant h_period : natural := h_pulse + h_bp + h_pixels + h_fp; --total number of pixel clocks in a row
	constant v_period : natural := v_pulse + v_bp + v_pixels + v_fp; --total number of rows in column
	signal h_sync_reg : STD_LOGIC := '0';
	signal v_sync_reg : STD_LOGIC := '0';
	signal display_on_reg : STD_LOGIC := '0';
	signal pixel_x_reg : natural range 0 to h_pixels - 1 := 0;
	signal pixel_y_reg : natural range 0 to v_pixels - 1 := 0;
begin
	-- VGA process
	process (pixel_clock)
	variable h_counter : natural range 0 to h_period - 1 := 0;
	variable v_counter : natural range 0 to v_period - 1 := 0;
    begin
        if rising_edge(pixel_clock) then
            if (h_counter < h_period - 1) then
                h_counter := h_counter + 1;
            else
                h_counter := 0;
                if (v_counter < v_period - 1) then
                    v_counter := v_counter + 1;
                else
                    v_counter := 0;
                end if;
            end if;
            -- horizontal sync
            if ((h_counter < h_pixels + h_fp) or (h_counter >= h_pixels + h_fp + h_pulse)) then
                h_sync_reg <= not h_pol;
            else
                h_sync_reg <= h_pol;
            end if;
            -- vertical sync
            if ((v_counter < v_pixels + v_fp) or (v_counter >= v_pixels + v_fp + v_pulse)) then
                v_sync_reg <= not v_pol;
            else
                v_sync_reg <= v_pol;
            end if;
            -- inside display area?
            if ((h_counter < h_pixels) and (v_counter < v_pixels)) then
                display_on_reg <= '1';
            else
                display_on_reg <= '0';
            end if;
            -- update pixel_x and pixel_y
            if (h_counter < h_pixels) then
                pixel_x_reg <= h_counter;
            end if;
            if (v_counter < v_pixels) then
                pixel_y_reg <= v_counter;
            end if;
        end if;
    end process;
    h_sync <= h_sync_reg;
    v_sync <= v_sync_reg;
    display_on <= display_on_reg;
    pixel_x <= pixel_x_reg;
    pixel_y <= pixel_y_reg;
end Behavioral;