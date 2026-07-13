library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab6_top is
	port(
		clk, reset  : in STD_LOGIC;
		data 		: in STD_LOGIC;
		an 		    : out STD_LOGIC;
		sseg 		: out STD_LOGIC_VECTOR(6 downto 0)
	
	);
	
end lab6_top;

architecture Behavioral of lab6_top is
	signal key : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin
	
	u_uart : entity work.uart(Behavioral)
		port map(
			clk => clk,
			reset => reset,
			rx => data,
			rx_data => key
		);

	u_display : entity work.decoder(Behavioral)
		port map(
			clk => clk,
			reset => reset,
			hex0 => key(3 downto 0),
			hex1 => key(7 downto 4),
			an => an,
			sseg => sseg
		);

end Behavioral;

