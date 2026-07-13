library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port(
        CLK    : in  STD_LOGIC;
        LCD_RS : out STD_LOGIC;
        LCD_RW : out STD_LOGIC;
        LCD_E  : out STD_LOGIC;
        SF_CE0 : out STD_LOGIC;
        DATA   : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top;

architecture Behavioral of top is

    signal lcd_init_done : STD_LOGIC := '0';

    signal init_rs   : STD_LOGIC;
    signal init_e    : STD_LOGIC;
    signal init_data : STD_LOGIC_VECTOR(3 downto 0);

    signal write_rs   : STD_LOGIC;
    signal write_e    : STD_LOGIC;
    signal write_data : STD_LOGIC_VECTOR(3 downto 0);

    component lcd_init is
        port(
            CLK           : in  STD_LOGIC;
            LCD_RS        : out STD_LOGIC;
            LCD_E         : out STD_LOGIC;
            DATA          : out STD_LOGIC_VECTOR(3 downto 0);
            LCD_INIT_DONE : out STD_LOGIC
        );
    end component;

    component lcd_write is
        port(
            CLK           : in  STD_LOGIC;
            LCD_INIT_DONE : in  STD_LOGIC;
            LCD_RS        : out STD_LOGIC;
            LCD_E         : out STD_LOGIC;
            DATA          : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin

    -- Strata Flash deve ficar desabilitada durante uso do LCD
    SF_CE0 <= '1';
    -- Operação sempre de escrita
    LCD_RW <= '0';

    U_INIT : lcd_init
        port map(
            CLK           => CLK,
            LCD_RS        => init_rs,
            LCD_E         => init_e,
            DATA          => init_data,
            LCD_INIT_DONE => lcd_init_done
        );

    U_WRITE : lcd_write
        port map(
            CLK           => CLK,
            LCD_INIT_DONE => lcd_init_done,
            LCD_RS        => write_rs,
            LCD_E         => write_e,
            DATA          => write_data
        );

    LCD_RS <= init_rs  when lcd_init_done = '0' else write_rs;
    LCD_E  <= init_e   when lcd_init_done = '0' else write_e;
    DATA   <= init_data when lcd_init_done = '0' else write_data;

end Behavioral;