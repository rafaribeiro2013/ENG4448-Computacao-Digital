library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc_module is
	port ( 
		CLK : in STD_LOGIC;
		RESET : in STD_LOGIC;
		SPI_MISO : in STD_LOGIC;
		AD_CONV : out STD_LOGIC;
		LEDS : out STD_LOGIC_VECTOR(7 downto 0);
		SPI_MOSI, AMP_CS, SPI_SCK : out STD_LOGIC;
		SPI_SS_B, SF_CE0, FPGA_INIT_B, DAC_CS : out STD_LOGIC
	);
end adc_module;

architecture Behavioral of adc_module is

	signal counter : integer := 0;
	type fsm_t is (idle, conf_amp, receive_data, activate_ADC);
	signal state : fsm_t := idle;
	
	signal conf_amp_bits: STD_LOGIC_VECTOR(7 downto 0) := "00010001";
	signal clk_120ns : STD_LOGIC := '0';
	signal SPI_MOSI_REG : STD_LOGIC := '0';
	
	signal ADC_DATA : STD_LOGIC_VECTOR(13 downto 0) := (others => '0');
	signal ADC_DATA_SIGNED : signed(13 downto 0) := (others => '0');
	signal ADC_DATA_REG : STD_LOGIC_VECTOR(13 downto 0) := (others => '0');
	signal boundary : integer := 2048;
	signal offset : integer := 8192;
	
begin
	
	SPI_MOSI <= SPI_MOSI_REG;
	SPI_SCK <= clk_120ns;	
	ADC_DATA_SIGNED <= signed(ADC_DATA);

	-- Disabled other devices
	
	SPI_SS_B <= '1';
	DAC_CS <= '1';
	SF_CE0 <= '1';
	FPGA_INIT_B <= '0';

	process (CLK)
		variable counter_clk : natural range 0 to 3;
	begin
		if (rising_edge(CLK)) then
			counter_clk := counter_clk + 1;
			if counter_clk = 3 then
				clk_120ns <= not clk_120ns;
				counter_clk := 0;
			end if;
		end if;
	end process;

	process (clk_120ns)
	begin
		if (rising_edge(clk_120ns)) then	
			if (RESET = '1') then
				state <= idle;
			else 
				case state is
				
					when idle =>
						AD_CONV <= '0';
						AMP_CS <= '1';
						counter <= counter + 1;
						
						if (counter = 10) then
							state <= conf_amp;
							counter <= 0;
						end if;
				
					when conf_amp =>
						AMP_CS <= '0';
						counter <= counter + 1;
						if (counter <= 7) then
							SPI_MOSI_REG <= conf_amp_bits(7 - counter);
						else
							state <= receive_data;
							counter <= 0;
							AMP_CS <= '1'; 
							AD_CONV <= '1'; 
						end if;			
						
					when receive_data => 
					-- Lembrar dos bits de alta impedancia ao receber os dados dos canais
						AD_CONV <= '0';
						counter <= counter + 1;
						
						if (counter >= 2 and counter <= 15) then
							ADC_DATA_REG <= ADC_DATA_REG(12 downto 0) & SPI_MISO;
						
						elsif (counter = 33) then
							state <= activate_ADC;
							ADC_DATA <= ADC_DATA_REG;
							counter <= 0;
							AD_CONV <= '1';

						end if;
						
					when activate_ADC =>
						AD_CONV <= '0';
						state <= receive_data;					
						
					when others =>
						state <= conf_amp;
				end case;
	
			end if;
		end if;
	end process;

    LEDS <= "11111111" when (ADC_DATA_SIGNED <= -6368) else -- 2.62 V a 2.90 V
            "11111110" when (ADC_DATA_SIGNED <= -4548) else -- 2.34 V a 2.62 V
            "11111100" when (ADC_DATA_SIGNED <= -2728) else -- 2.06 V a 2.34 V
            "11111000" when (ADC_DATA_SIGNED <=  -908) else -- 1.78 V a 2.06 V
            "11110000" when (ADC_DATA_SIGNED <=   912) else -- 1.51 V a 1.78 V  OBS: 1.65V -> ADC_DATA_SIGNED = 0
            "11100000" when (ADC_DATA_SIGNED <=  2732) else -- 1.23 V a 1.51 V
            "11000000" when (ADC_DATA_SIGNED <=  4552) else -- 0.95 V a 1.23 V
            "10000000" when (ADC_DATA_SIGNED <=  6372) else -- 0.67 V a 0.95 V
            "00000000";                                     -- 0.40 V a 0.67 V 

end Behavioral;