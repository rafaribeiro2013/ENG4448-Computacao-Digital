library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    port (
        A        : in  unsigned(7 downto 0);
        B        : in  unsigned(7 downto 0);
        COMANDO  : in  std_logic_vector(3 downto 0);
        R        : out unsigned(7 downto 0);
        ZERO     : out std_logic;
        SINAL    : out std_logic;
        OVERFLOW : out std_logic;
        EQUAL    : out std_logic;
        GREATER  : out std_logic;
        SMALLER  : out std_logic
    );
end alu;

architecture Behavioral of alu is
    -- signals
    signal temp_R : unsigned(7 downto 0);
    signal temp_overflow : std_logic;

begin

    process (A, B, COMANDO)
        variable add_sub : unsigned(8 downto 0); -- 9 bits p/ ADD/SUB
        begin
        
        temp_R        <= (others => '0');
        temp_overflow <= '0';

        case COMANDO is
            -- Operadores aritméticos
            when "0000" => -- ADD
                add_sub       := unsigned('0' & A) + unsigned('0' & B);
                temp_R        <= add_sub(7 downto 0);
                temp_overflow <= add_sub(8);

            when "0001" => -- SUB
                add_sub       := unsigned('0' & A) - unsigned('0' & B);
                temp_R        <= add_sub(7 downto 0);
                temp_overflow <= add_sub(8);

            when "0010" => -- INC
                add_sub       := unsigned('0' & A) + 1;
                temp_R        <= add_sub(7 downto 0);
                temp_overflow <= add_sub(8);

            when "1010" => -- DEC
                add_sub       := unsigned('0' & A) - 1;
                temp_R        <= add_sub(7 downto 0);
                temp_overflow <= add_sub(8);

            -- Operadores lógicos
            when "0011" => -- AND
                temp_R <= A and B;

            when "0100" => -- OR
                temp_R <= A or B;

            when "0101" => -- NOT
                temp_R <= not A;

            when "0110" => -- XOR
                temp_R <= A xor B;

            when "0111" => --ROL
                temp_R <= A(6 downto 0) & A(7);
                
            when "1000" => --ROR 
                temp_R <= A(0) & A(7 downto 1);

            when "1001" => --LSL 
                temp_R <= A(6 downto 0) & '0';
                
            when "1011" => --LSR
                temp_R <= '0' & A(7 downto 1);

            when others =>
                temp_R        <= (others => '0');
                temp_overflow <= '0';
        end case;
    end process;

	R        <= temp_R;
    ZERO     <= '1' when (A = 0) else '0';
    SINAL    <= temp_R(7);
    GREATER  <= '1' when (A > B) else '0';
	SMALLER  <= '1' when (A < B) else '0';
	EQUAL    <= '1' when (A = B) else '0';

    OVERFLOW <= temp_overflow;

end Behavioral;