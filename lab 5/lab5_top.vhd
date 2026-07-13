library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab5_top is
    Port (
        clk      : in  STD_LOGIC; 
        reset    : in  STD_LOGIC;
        ps2_clk  : in  STD_LOGIC;
        ps2_data : in  STD_LOGIC;
        parity_error   : out STD_LOGIC;
        sseg     : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC
    );
end lab5_top;

architecture Behavioral of lab5_top is

    signal key : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    component ps2
        port(
            clk_kbd : in STD_LOGIC;
            reset   : in STD_LOGIC;
            data    : in STD_LOGIC;
            key     : out STD_LOGIC_VECTOR(7 downto 0);
            parity_error   : out STD_LOGIC
        );
    end component;
    
    component decoder
        port(
           clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           hex0 : in STD_LOGIC_VECTOR(3 downto 0);
           hex1 : in STD_LOGIC_VECTOR(3 downto 0);
           an : out  STD_LOGIC;
           sseg : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

begin

    u_ps2 : ps2
        port map (
            clk_kbd => ps2_clk,
            reset   => reset,
            data    => ps2_data,
            key     => key,
            parity_error => parity_error
        );
    
    u_decoder : decoder
		port map(
			clk  => clk,
			reset => reset,
			hex0 => key(3 downto 0),
			hex1 => key(7 downto 4),
			an => an,
			sseg => sseg
		);

end Behavioral;