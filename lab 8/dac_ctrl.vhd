library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DAC is
	port(
		CLK : in STD_LOGIC;
		RESET : out STD_LOGIC;
		--SPI_MISO : in STD_LOGIC; 
		SPI_MOSI, DAC_CS : out STD_LOGIC;
		SPI_SCK, SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B : out STD_LOGIC;
		DATA : in STD_LOGIC_VECTOR(11 downto 0);
		SEND_DATA: in STD_LOGIC;
		READY : out STD_LOGIC
	);
end DAC;

architecture Behavioral of DAC is

	signal counter : integer := 0;
	constant command : std_logic_vector(3 downto 0) := "0011";
	constant address : std_logic_vector(3 downto 0) := "1111";
	
	signal SPI_MOSI_REG : STD_LOGIC := '1';
	signal DAC_CS_REG   : STD_LOGIC := '0'; 
	
	type fsm_t is (idle, start_dontcare, command_state, address_state, tx_data, end_dontcare);
	signal state : fsm_t := idle;
	
begin	

	-- Disable other devices
	SPI_SS_B <= '1';
	AMP_CS <= '1';
	AD_CONV <= '0';
	SF_CE0 <= '1';
	FPGA_INIT_B <= '0';
	RESET <= '1'; -- reset active-low
	
	SPI_SCK <= CLK; -- 50 MHz

	sync_proc: process(CLK)
	begin
		if (falling_edge(CLK)) then
			case state is			
				when idle =>
					READY <= '1';
					DAC_CS_REG <= '1';
					if (SEND_DATA = '1') then
						state <= start_dontcare;
					end if;

				when start_dontcare => 			-- wait for the first 8 dont care bits
					READY <= '0';
					DAC_CS_REG <= '0';
					counter <= counter + 1;
					SPI_MOSI_REG <= '0';
					if (counter = 7) then
						state <= command_state;
						counter <= 0;
					end if;		
				
				when command_state =>
					SPI_MOSI_REG <= command(3-counter);
					counter <= counter + 1;
					if (counter = 3) then
						state <= address_state;
						counter <= 0;
					end if;
				
				when address_state =>
					SPI_MOSI_REG <= address(3-counter);
					counter <= counter + 1;
					if (counter = 3) then
						state <= tx_data;
						counter <= 0;
					end if;
				
				when tx_data =>					-- wait for the last 4 dont care bits
					SPI_MOSI_REG <= data(11-counter);
					counter <= counter + 1;
					if (counter = 11) then
						state <= end_dontcare;
						counter <= 0;
					end if;
				
				when end_dontcare =>
					counter <= counter + 1;
					SPI_MOSI_REG <= '0';
					if (counter = 3) then
						state <= idle;
						counter <= 0;
					end if;
									
				when others => 
					state <= idle;					
			end case;
			
		end if;
	end process sync_proc;
	
	SPI_MOSI <= SPI_MOSI_REG;
	DAC_CS   <= DAC_CS_REG;
	
end Behavioral;

