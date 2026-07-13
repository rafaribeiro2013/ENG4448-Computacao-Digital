--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--
--entity ps2 is
--	port(
--		clk_kbd, reset : in STD_LOGIC;
--		data : in STD_LOGIC;
--		key : out STD_LOGIC_VECTOR(7 downto 0)
--	);
--end ps2;
--
--architecture Behavioral of ps2 is
--
--	signal key_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
--	signal counter_reg : unsigned(3 downto 0) := "0000";
--	
--	type fsm_t is (idle, rx_kbd_data, send_key);
--	signal state : fsm_t := idle;
--	
--begin	
--	key <= key_reg;
--
--	sync_proc: process(clk_kbd, reset)
--	begin
--		if (reset = '1') then
--			key_reg <= "00000000";
--			
--		elsif (falling_edge(clk_kbd)) then
--			case state is			
--				when idle =>
--					if (data = '0') then
--						state <= rx_kbd_data;
--					end if;
--
--				when rx_kbd_data =>
--					if(counter_reg(3) /= '1') then
--						key_reg <= data & key_reg(7 downto 1);
--						counter_reg <= counter_reg + 1;
--					else
--						counter_reg <= "0000";
--						state <= send_key;
--					end if;
--					
--				when send_key =>
--					state <= idle;
--									
--				when others => 
--					state <= idle;					
--			end case;
--		end if;
--	end process sync_proc;
--end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ps2 is
    port(
        clk_kbd, reset : in  STD_LOGIC;
        data           : in  STD_LOGIC;
        key            : out STD_LOGIC_VECTOR(7 downto 0);
        parity_error   : out STD_LOGIC  
    );
end ps2;

architecture Behavioral of ps2 is

    signal key_reg      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal key_reg_out  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal counter_reg  : unsigned(3 downto 0)          := "0000";
    signal parity_reg   : STD_LOGIC                     := '0'; -- acumula XOR dos bits
    signal parity_err_r : STD_LOGIC                     := '0';

    type fsm_t is (idle, rx_kbd_data, rx_parity, rx_stop, send_key, error_state);
    signal state : fsm_t := idle;

begin
    key          <= key_reg_out;
    parity_error <= parity_err_r;

    sync_proc : process(clk_kbd, reset)
    begin
        if reset = '1' then
            key_reg      <= (others => '0');
            counter_reg  <= "0000";
            parity_reg   <= '0';
            parity_err_r <= '0';
            state        <= idle;

        elsif falling_edge(clk_kbd) then
            case state is
               
                when idle =>
                    parity_reg <= '0';
                    if data = '0' then          
                        parity_err_r <= '0';
                        state <= rx_kbd_data;
                    end if;

                
                when rx_kbd_data =>
                    key_reg    <= data & key_reg(7 downto 1); 
                    parity_reg <= parity_reg xor data;        
                    if counter_reg = "0111" then              
                        counter_reg <= "0000";
                        state       <= rx_parity;
                    else
                        counter_reg <= counter_reg + 1;
                    end if;

                
                when rx_parity =>
                    key_reg_out <= key_reg;
                    if (parity_reg xor data) = '1' then
                        parity_err_r <= '0';
                        state        <= rx_stop;
                    else
                        parity_err_r <= '1';
                        state        <= rx_stop;
                    end if;
                    
                when rx_stop =>
                    if data = '1' then
                        state <= idle;
                    else
                        parity_err_r <= '1';   
                        state        <= idle;
                    end if;

                when others =>
                    state <= idle;

            end case;
        end if;
    end process sync_proc;

end Behavioral;
