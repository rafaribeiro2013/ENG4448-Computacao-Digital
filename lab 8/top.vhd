library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
port(
		clk : in STD_LOGIC;
		RESET : out STD_LOGIC;
		SPI_SCK, SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B : out STD_LOGIC;
		SPI_MOSI, DAC_CS : out STD_LOGIC
	);
end top;

architecture Behavioral of top is

	signal data : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal send_data : STD_LOGIC := '0';
	signal ready : STD_LOGIC;
	
begin

    DAC : entity work.DAC(Behavioral)
		port map(
			CLK => clk,
			RESET => RESET,
			SEND_DATA => send_data,
			DATA => data,
			READY => ready,
			SPI_MOSI => SPI_MOSI,
			DAC_CS => DAC_CS,
			SPI_SCK => SPI_SCK, 
			SPI_SS_B => SPI_SS_B,
			AMP_CS => AMP_CS,
			AD_CONV => AD_CONV,
			SF_CE0 => SF_CE0, 
			FPGA_INIT_B => FPGA_INIT_B			
		);

	process (clk)
    	variable is_rising : STD_LOGIC := '1';
	begin
		if (falling_edge(CLK)) then
			send_data <= '0';
			if (ready = '1') then
				if (unsigned(data) = 4095) then
					is_rising := '0';
				elsif (unsigned(data) = 0) then
					is_rising := '1';
				end if;

				if (is_rising = '1') then
					data <= std_logic_vector(unsigned(data) + 1);
				else
					data <= std_logic_vector(unsigned(data) - 1);
				end if;
				
				send_data <= '1';
			end if;
		end if;
	end process;
end Behavioral;