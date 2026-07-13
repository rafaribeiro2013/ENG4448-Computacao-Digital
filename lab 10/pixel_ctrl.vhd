library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity PIXEL_CTRL is
	generic (
		h_pixels : natural := 800; --horizontal display width in pixels
		v_pixels : natural := 600 --vertical display width in rows
	);
	port (
		pixel_clock : in STD_LOGIC; --pixel clock
		display_on : in STD_LOGIC; --display enable ('1' = display time, '0' = blanking time)
		pixel_x : in natural; --horizontal pixel coordinate
		pixel_y : in natural; --vertical pixel coordinate
		red : out STD_LOGIC;
		green : out STD_LOGIC;
		blue : out STD_LOGIC
	);
end PIXEL_CTRL;
architecture Behavioral of PIXEL_CTRL is
    -- CÓDIGO DA PRIMEIRA PARTE
    
	-- constant pixel_x_cols : natural := natural(ceil(real(h_pixels)/7.0));
	-- constant pixel_y_rows : natural := natural(ceil(real(v_pixels) * 0.8));
	-- signal red_reg : STD_LOGIC := '0';
	-- signal green_reg : STD_LOGIC := '0';
	-- signal blue_reg : STD_LOGIC := '0';
	--begin
	-- process (pixel_clock)
	-- begin
	-- if rising_edge(pixel_clock) then
	-- if (pixel_x + pixel_y < 600) then
	-- red_reg <= '0';
	-- green_reg <= '1';
	-- blue_reg <= '0';
	-- 
	-- elsif (pixel_x + pixel_y > 800) then
	-- red_reg <= '1';
	-- green_reg <= '0';
	-- blue_reg <= '0';
	-- 
	-- else
	-- red_reg <= '1';
	-- green_reg <= '1';
	-- blue_reg <= '0';
	-- end if;
	-- end if;
	-- end process;
	-- -- if display_on = '0' then RGB <= "000"; (blanking time)
	-- red <= red_reg when display_on = '1' else '0';
	-- green <= green_reg when display_on = '1' else '0';
	-- blue <= blue_reg when display_on = '1' else '0';

    -- DESAFIO
	constant SPEED : natural := 1;
	constant BALL_SIZE : natural := 16;
	type rom_type is array(0 to BALL_SIZE - 1) of std_logic_vector(0 to BALL_SIZE - 1);
	constant BALL_ROM : rom_type := (
        "0000011111100000",
		"0001111111111000",
		"0011111111111100",
		"0111111111111110",
		"0111111111111110",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"1111111111111111",
		"0111111111111110",
		"0111111111111110",
		"0011111111111100",
		"0001111111111000",
		"0000011111100000"
	);
	type color_type is array(0 to 7) of std_logic_vector(2 downto 0);
	constant BALL_COLOR : color_type:= (
		"011", -- 0: Cyan
		"101", -- 1: Pink/Magenta
		"010", -- 2: Green
		"110", -- 3: Yellow/Orange
		"101", -- 4: Purple
		"011", -- 5: Cyan
		"100", -- 6: Red
		"111" -- 7: White
	); 
	signal rom_addr, rom_col : natural range 0 to BALL_SIZE - 1 := 0;
	signal rom_data : std_logic_vector(0 to BALL_SIZE - 1) := (others => '0');
	signal rom_bit : std_logic := '0';

	signal color_idx : natural range 0 to 7 := 0;
	signal dir_x : std_logic := '1';
	signal dir_y : std_logic := '1';
	signal ball_rgb : std_logic_vector(2 downto 0);
    signal prev_y : natural := 0;

	signal ball_x : natural range 0 to h_pixels - 1 := 0;
	signal ball_y : natural range 0 to v_pixels - 1 := 0;
	signal ball_x_right, ball_x_left : natural range 0 to h_pixels - 1 := 0;
	signal ball_y_top, ball_y_bottom : natural range 0 to v_pixels - 1 := 0;
	signal print_ball : std_logic := '0';
 
begin
	ball_x_left <= ball_x;
	ball_x_right <= ball_x + BALL_SIZE - 1;
	ball_y_top <= ball_y;
	ball_y_bottom <= ball_y + BALL_SIZE - 1;
 
	print_ball <= '1' when (pixel_x >= ball_x_left) and (pixel_x <= ball_x_right) and
	              (pixel_y >= ball_y_top) and (pixel_y <= ball_y_bottom) else '0';
 
	rom_addr <= abs(pixel_y - ball_y_top) mod BALL_SIZE;
	rom_col <= abs(pixel_x - ball_x_left) mod BALL_SIZE;
    
	rom_data <= BALL_ROM(rom_addr);
	rom_bit <= rom_data(rom_col);
 
	ball_rgb <= BALL_COLOR(color_idx);
	red <= ball_rgb(2) when (print_ball = '1' and rom_bit = '1' and display_on = '1') else '0';
	green <= ball_rgb(1) when (print_ball = '1' and rom_bit = '1' and display_on = '1') else '0';
	blue <= ball_rgb(0) when (print_ball = '1' and rom_bit = '1' and display_on = '1') else '0';

	-- update ball_pos
	process (pixel_clock)
        variable hit_edge : boolean := false;
	begin
		if rising_edge(pixel_clock) then
            prev_y <= pixel_y;
			if (pixel_y = 0 and prev_y /= pixel_y) then
				hit_edge := false;
				-- Lógica do Eixo X
				if dir_x = '1' then
					if (ball_x + BALL_SIZE + SPEED) >= h_pixels then
						dir_x <= '0';
						ball_x <= h_pixels - BALL_SIZE;
						hit_edge := true;
					else
						ball_x <= ball_x + SPEED;
					end if;
				else
					if ball_x <= SPEED then
						dir_x <= '1';
						ball_x <= 0;
						hit_edge := true;
					else
						ball_x <= ball_x - SPEED;
					end if;
				end if;

				-- Lógica do Eixo Y
				if dir_y = '1' then
					if (ball_y + BALL_SIZE + SPEED) >= v_pixels then
						dir_y <= '0';
						ball_y <= v_pixels - BALL_SIZE;
						hit_edge := true;
					else
						ball_y <= ball_y + SPEED;
					end if;
				else
					if ball_y <= SPEED then
						dir_y <= '1';
						ball_y <= 0;
						hit_edge := true;
					else
						ball_y <= ball_y - SPEED;
					end if;
				end if;

				-- Muda a cor se bateu em alguma borda
				if hit_edge then
					if color_idx = 7 then
						color_idx <= 0;
					else
						color_idx <= color_idx + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;