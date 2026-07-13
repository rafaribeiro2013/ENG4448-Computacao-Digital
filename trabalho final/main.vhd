library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is
    port (
        CLK         : in  std_logic;
        RESET       : in  std_logic;
        LEDS_OUT    : out std_logic_vector(7 downto 0);
        LCD_E, LCD_RS, LCD_RW 	: out STD_LOGIC;
		SF_CE0 		: out STD_LOGIC;
        LCD_DATA	: out STD_LOGIC_VECTOR(3 downto 0)
    );
end main;

architecture Behavioral of main is

    signal leds_out_r : std_logic_vector(7 downto 0);

    -- Fios internos para interconectar a CPU e LCD
    signal opcode_s   : std_logic_vector(7 downto 0);
    
    -- Fios internos para interconectar a CPU e a Memória
    signal ram_din_s  : std_logic_vector(7 downto 0);
    signal ram_dout_s : std_logic_vector(7 downto 0);
    signal ram_addr_s : std_logic_vector(7 downto 0);
    signal ram_we_s   : std_logic;
    
    --Fios para o LCD
    signal lcd_rs_s: STD_LOGIC;
    signal lcd_rw_s: STD_LOGIC;
    signal lcd_e_s: STD_LOGIC;
    signal lcd_data_s: STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal sf_ce0_s: STD_LOGIC;
    
    -- Fio para a posição 255 da memória (caso queira usar para algo)
    signal pos_255_s  : std_logic_vector(7 downto 0);
    
    signal clk_slow : std_logic := '0';
    signal div_cnt   : unsigned(26 downto 0) := (others => '0'); 

begin

    process (CLK, RESET)
    begin
        if RESET = '1' then
            div_cnt   <= (others => '0');
            clk_slow <= '0';
        elsif rising_edge(CLK) then             -- CLK = 50 MHz
--          if div_cnt = 24_999_999 then        -- 2 s / 20 ns - 1
            if div_cnt = 1_999_999 then        -- 2 s / 20 ns - 1
                div_cnt   <= (others => '0');   -- reinicia
                clk_slow <= not clk_slow;     -- alterna (T = 2 s)
            else
                div_cnt <= div_cnt + 1;
            end if;
        end if;
    end process;

--    clk_slow <= clk;

    -- Instanciação da CPU
    u_cpu: entity work.cpu(Behavioral)
        port map (
            CLK      => clk_slow,       
            RESET    => RESET,      
            RAM_DIN  => ram_din_s, 
            RAM_DOUT => ram_dout_s, 
            RAM_ADDR => ram_addr_s, 
            RAM_WE   => ram_we_s,  
            OPCODE   => opcode_s,
            LEDS_OUT => leds_out_r
        );

    -- Instanciação da Memória
    u_memory: entity work.memory(rtl)
        port map (
            CLK     => clk_slow,
            DIN     => ram_din_s,
            ADDR    => ram_addr_s,
            WE      => ram_we_s,
            DOUT    => ram_dout_s,
            POS_255 => pos_255_s
        );
        
     u_lcd : entity work.lcd
        port map(
            CLK => CLK,
            RESET => RESET,
            LCD_RS => lcd_rs_s,
            LCD_RW => lcd_rw_s,
            LCD_E => lcd_e_s,
            DATA => lcd_data_s,
            SF_CE0 => sf_ce0_s,
            IR_DATA => opcode_s,
            MEMORY => pos_255_s      
        ); 
       
    LCD_E     <= lcd_e_s;
    LCD_RS    <= lcd_rs_s;
    LCD_RW    <= lcd_rw_s;
    SF_CE0    <= sf_ce0_s;
    LCD_DATA  <= lcd_data_s; 
    LEDS_OUT  <= leds_out_r;

end Behavioral;