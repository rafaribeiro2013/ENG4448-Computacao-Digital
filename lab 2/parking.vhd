library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity parking is
    Port ( a : in  STD_LOGIC;
           b : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           z : out  STD_LOGIC_VECTOR(7 downto 0));
end parking;

architecture Behavioral of parking is

    type state_type is (idle,e1,e2,e3,s1,s2,s3);
    signal state_reg, state_next : state_type := idle;
    
    signal qtdVeiculos : integer range 0 to 8 := 0;
    signal z_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin

    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= idle;
        elsif (clk'event and clk = '1') then
            state_reg <= state_next;
        end if;
    end process;
    
    -- next state
    process(state_reg, a, b, reset)
    begin
        state_next <= state_reg;
        
        case state_reg is
            when idle =>
                if a = '1' then
                    state_next <= e1;
                elsif b = '1' then
                    state_next <= s1;
                end if;
            when e1 =>
                if a = '0' then
                    state_next <= idle;
                elsif b = '1' then
                    state_next <= e2;
                end if;
            when e2 =>
                if b = '0' then
                    state_next <= e1;
                elsif a = '0' then
                    state_next <= e3;
                end if;
            when e3 =>
                if a = '1' then
                    state_next <= e2;
                elsif b = '0' then
                    state_next <= idle;
                end if;                
            when s1 =>
                if b = '0' then
                    state_next <= idle;
                elsif a = '1' then
                    state_next <= s2;
                end if;
            when s2 =>
                if a = '0' then
                    state_next <= s1;
                elsif b = '0' then
                    state_next <= s3;
                end if;
            when s3 =>
                if a = '0' then
                    state_next <= idle;
                elsif b = '1' then
                    state_next <= s2;
                end if;
            when others =>
                state_next <= idle;
        end case;
    end process;
    
    --output logic
    output_logic: process(clk, reset)
    begin
        if reset = '1' then
            z_reg <= (others => '0');
            qtdVeiculos <= 0;
        elsif rising_edge(clk) then
            if (state_reg = e3 and state_next = idle) then
                if qtdVeiculos < 8 then
                    z_reg(qtdVeiculos) <= '1';
                    qtdVeiculos <= qtdVeiculos + 1;
                end if;
            elsif (state_reg = s3) and (state_next = idle) then
                if qtdVeiculos > 0 then
                    z_reg(qtdVeiculos - 1) <= '0'; 
                    qtdVeiculos <= qtdVeiculos - 1;
                end if;
            end if;
        end if;
    end process;
    
    z <= z_reg;


end Behavioral;

