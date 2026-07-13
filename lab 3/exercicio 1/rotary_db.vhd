library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rotary_db is
    Port ( 
        clk    : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        rot_a  : in  STD_LOGIC;
        rot_b  : in  STD_LOGIC;
        rot_c  : in  STD_LOGIC;
        leds   : out STD_LOGIC_VECTOR (7 downto 0)
    );
end rotary_db;

architecture Behavioral of rotary_db is

    component debounce_v1 is
        Port ( 
            clk   : in  STD_LOGIC;
            reset : in  STD_LOGIC;
            sw    : in  STD_LOGIC;
            db    : out STD_LOGIC;
            tick  : out STD_LOGIC
        );
    end component;

    signal rot_a_db, rot_b_db, rot_c_db     : STD_LOGIC;
    signal rot_a_tick, rot_b_tick, rot_c_tick : STD_LOGIC;
	signal leds_reg : STD_LOGIC_VECTOR (7 downto 0) := "00000001";
    
    type state_type is (S0, S1, S2, S3, S4, S5, S6);
    signal state_reg, state_next : state_type := S0;

begin

    debouncer_a: debounce_v1 port map (clk => clk, reset => reset, sw => rot_a, db => rot_a_db, tick => rot_a_tick);
    debouncer_b: debounce_v1 port map (clk => clk, reset => reset, sw => rot_b, db => rot_b_db, tick => rot_b_tick);
    debouncer_c: debounce_v1 port map (clk => clk, reset => reset, sw => rot_c, db => rot_c_db, tick => rot_c_tick);

    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= S0;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    process(state_reg, rot_a_db, rot_b_db)
    begin
        state_next <= state_reg;

        case state_reg is
            when S0 =>
               if rot_a_db = '1' and rot_b_db = '0' then
						state_next <= S1;
               elsif rot_a_db = '0' and rot_b_db = '1' then
                    state_next <= S4;
               end if;
					
            when S1 =>
                if rot_a_db = '1' and rot_b_db = '1' then
                  state_next <= S2;
                elsif rot_a_db = '0' and rot_b_db = '0' then
						state_next <= S0;
					 end if;

            when S2 =>
                if rot_a_db = '0' and rot_b_db = '1' then
                  state_next <= S3;
                elsif rot_a_db = '1' and rot_b_db = '0'  then
						state_next <= S1;
					 end if;

            when S3 =>
                if rot_a_db = '1' and rot_b_db = '1'  then
                  state_next <= S2;
                elsif rot_b_db = '0' and rot_a_db = '0'  then
					   --virou pra esquerda 
						state_next <= S0;
					 end if;

            when S4 =>
                if rot_b_db = '0' and rot_a_db = '0'  then
                  state_next <= S0;
                elsif rot_a_db = '1' and rot_b_db = '1'  then
						state_next <= S5;
					 end if;

            when S5 =>
                if rot_b_db = '0' and rot_a_db = '1'  then
                  state_next <= S6;
                elsif rot_a_db = '0' and rot_b_db = '1'  then
						state_next <= S4;
					 end if;

            when S6 =>
                if rot_a_db = '0' and rot_b_db = '0'  then
						--virou pra direita
						state_next <= S0;
                        
                elsif rot_b_db = '1' and rot_a_db = '1'  then
                  state_next <= S5;
					 end if;

            when others =>
                state_next <= S0;
        end case;
    end process;
	 
	 --output logic
    output_logic: process(clk, reset)
    begin
        if reset = '1' then
            leds_reg <= "00000001";
        elsif rising_edge(clk) then
            if rot_c_tick = '1' then
                leds_reg <= not leds_reg;
            elsif (state_reg = s3 and state_next = s0) then
					leds_reg <= leds_reg(6 downto 0) & leds_reg(7);
            elsif (state_reg = s6) and (state_next = s0) then
					leds_reg <= leds_reg(0) & leds_reg(7 downto 1);
            end if;
        end if;
    end process;
    
    leds <= leds_reg;

end Behavioral;

