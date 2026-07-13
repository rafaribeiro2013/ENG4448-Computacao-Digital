library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
	generic(
		h_pixels : NATURAL := 800; --horizontal display width in pixels
		v_pixels : NATURAL := 600 --vertical display width in rows
	);
	
	port (
		CLK, RST : in std_logic;
		VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC : out std_logic;
		LEDS : out std_logic_vector(7 downto 0)
	);
end top;

architecture Behavioral of top is
    
    COMPONENT pixel_clk_gen
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic;
		STATUS_OUT : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	signal pixel_clock_reg : std_logic := '0';
	signal display_on_reg : std_logic := '0';
	signal pixel_x_reg : NATURAL;
	signal pixel_y_reg : NATURAL;
	signal aux_status : std_logic_vector(7 downto 0) := (others => '0');
	signal LOCKED_OUT : std_logic := '0';
	
begin

	LEDS <= LOCKED_OUT & "0000" & aux_status(2 DOWNTO 0);

	Inst_pixel_clk_gen: pixel_clk_gen PORT MAP(
		CLKIN_IN => clk,
		RST_IN => rst,
		CLKFX_OUT => pixel_clock_reg,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		LOCKED_OUT => LOCKED_OUT,
		STATUS_OUT => aux_status
	);

	vga : entity work.VGA_CTRL(Behavioral)
		PORT MAP (
			pixel_clock => pixel_clock_reg,
			display_on => display_on_reg,
			pixel_x => pixel_x_reg,
			pixel_y => pixel_y_reg,
			h_sync => VGA_HSYNC,
			v_sync => VGA_VSYNC
		); 
	
	pixel : entity work.PIXEL_CTRL(Behavioral)
		PORT MAP (
			pixel_clock => pixel_clock_reg,
			display_on => display_on_reg,
			pixel_x => pixel_x_reg,
			pixel_y => pixel_y_reg,
			red => VGA_RED,
			green => VGA_GREEN,
			blue => VGA_BLUE
		);
		
end Behavioral;
