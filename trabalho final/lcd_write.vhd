library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_write is
    port(
        CLK           : in  STD_LOGIC;
        RESET         : in  STD_LOGIC;
        LCD_INIT_DONE : in  STD_LOGIC;
        LCD_RS        : out STD_LOGIC;
        LCD_E         : out STD_LOGIC;
        DATA          : out STD_LOGIC_VECTOR(3 downto 0);
        IR_DATA       : in std_logic_vector(7 downto 0);
        MEMORY        : in std_logic_vector(7 downto 0)
    );
end lcd_write;

architecture Behavioral of lcd_write is

    -- =========================================================================
    -- 1. TIPOS, FUNÇÕES E CONSTANTES FORNECIDAS
    -- =========================================================================

    TYPE rom_str IS ARRAY(0 TO 31) OF std_logic_vector(3 DOWNTO 0); -- linha com 16 chars / 32bits

    FUNCTION to_std_logic_vector(a : STRING) RETURN rom_str IS
        VARIABLE chr2slv               : std_logic_vector(7 DOWNTO 0);
        VARIABLE ret                   : rom_str;
    BEGIN
        FOR i IN a'RANGE LOOP
            chr2slv              := std_logic_vector(to_unsigned(CHARACTER'pos(a(i)), 8));
            ret(2 * (i - 1) + 0) := chr2slv(7 DOWNTO 4);
            ret(2 * (i - 1) + 1) := chr2slv(3 DOWNTO 0);
        END LOOP;
        RETURN ret;
    END FUNCTION to_std_logic_vector;

    CONSTANT STR_ADD  : rom_str := to_std_logic_vector("add Rx, Ry      ");
    CONSTANT STR_SUB  : rom_str := to_std_logic_vector("sub Rx, Ry      ");
    CONSTANT STR_INC  : rom_str := to_std_logic_vector("inc Rx          ");
    CONSTANT STR_DEC  : rom_str := to_std_logic_vector("dec Rx          ");
    CONSTANT STR_AND  : rom_str := to_std_logic_vector("AND Rx, Ry      ");
    CONSTANT STR_OR   : rom_str := to_std_logic_vector("OR Rx, Ry       ");
    CONSTANT STR_NOT  : rom_str := to_std_logic_vector("NOT Rx          ");
    CONSTANT STR_XOR  : rom_str := to_std_logic_vector("XOR Rx, Ry      ");
    CONSTANT STR_ROL  : rom_str := to_std_logic_vector("ROL Rx          ");
    CONSTANT STR_ROR  : rom_str := to_std_logic_vector("ROR Rx          ");
    CONSTANT STR_LSL  : rom_str := to_std_logic_vector("lsl Rx          ");
    CONSTANT STR_LSR  : rom_str := to_std_logic_vector("lsr Rx          ");
    CONSTANT STR_PUSH : rom_str := to_std_logic_vector("push Rx         ");
    CONSTANT STR_POP  : rom_str := to_std_logic_vector("pop Rx          ");
    CONSTANT STR_LD   : rom_str := to_std_logic_vector("ld Rx, 0x--     ");
    CONSTANT STR_LDR  : rom_str := to_std_logic_vector("ldr Rx, [Ry]    ");
    CONSTANT STR_STR  : rom_str := to_std_logic_vector("str Rx, [Ry]    ");
    CONSTANT STR_JMP  : rom_str := to_std_logic_vector("jmp 0x--        ");
    CONSTANT STR_JMPR : rom_str := to_std_logic_vector("jmpr Rx         ");
    CONSTANT STR_BZ   : rom_str := to_std_logic_vector("bz Rx           ");
    CONSTANT STR_BNZ  : rom_str := to_std_logic_vector("bnz Rx          ");
    CONSTANT STR_BCS  : rom_str := to_std_logic_vector("bcs Rx          ");
    CONSTANT STR_BCC  : rom_str := to_std_logic_vector("bcc Rx          ");
    CONSTANT STR_BEQ  : rom_str := to_std_logic_vector("beq Rx          ");
    CONSTANT STR_BNEQ : rom_str := to_std_logic_vector("bneq Rx         ");
    CONSTANT STR_BGT  : rom_str := to_std_logic_vector("bgt Rx          ");
    CONSTANT STR_BLT  : rom_str := to_std_logic_vector("blt Rx          ");
    CONSTANT STR_HALT : rom_str := to_std_logic_vector("halt            ");
    CONSTANT STR_MOV  : rom_str := to_std_logic_vector("mov Rx, Ry      ");
    CONSTANT STR_UNKN : rom_str := to_std_logic_vector("invalid instr.  ");

    -- Função de BCD fornecida (com DIGITS travado em 3 para um unsigned de 8-bits)
    FUNCTION to_bcd(Binary : unsigned) RETURN unsigned IS
        VARIABLE b             : unsigned(Binary'LENGTH - 1 DOWNTO 0) := Binary;
        CONSTANT DIGITS        : NATURAL := 3; 
        VARIABLE bcd           : unsigned(DIGITS * 4 - 1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        FOR i IN b'RANGE LOOP
            -- iterate over each group of 4 bits that comprise a digit
            FOR d IN 0 TO DIGITS - 1 LOOP
                IF bcd(d * 4 + 3 DOWNTO d * 4) >= 5 THEN 
                    bcd(d * 4 + 3 DOWNTO d * 4) := bcd(d * 4 + 3 DOWNTO d * 4) + 3;
                END IF;
            END LOOP;
            -- shift left -> multiply by 2
            bcd := bcd(bcd'LEFT - 1 DOWNTO 0) & b(b'left);
            b   := b(b'LEFT - 1 DOWNTO 0) & '0';
        END LOOP; 
        RETURN bcd;
    END FUNCTION;

    -- =========================================================================
    -- 2. SINAIS PARA OPERAÇÃO DO LCD
    -- =========================================================================

    signal current_ir_str  : rom_str;
    signal current_mem_str : rom_str;

    type lcd_op_t is record
        rs   : std_logic;
        data : std_logic_vector(3 downto 0);
    end record;
    type lcd_seq_t is array (0 to 67) of lcd_op_t;
    signal refresh_seq : lcd_seq_t;

    constant E_HIGH_CYCLES : unsigned(19 downto 0) := to_unsigned(12,   20);
    constant E_LOW_CYCLES  : unsigned(19 downto 0) := to_unsigned(2000, 20);
    constant WAIT_CYCLES   : unsigned(19 downto 0) := to_unsigned(500000, 20); 

    type FSM_t is (idle, write_a, write_b, wait_refresh);
    signal state    : FSM_t := idle;
    signal counter  : unsigned(19 downto 0) := (others => '0');
    signal idx_data : integer range 0 to 68 := 0;

begin

    -- =========================================================================
    -- 3. DECODIFICADOR DE IR -> STRING
    -- =========================================================================
    process(IR_DATA)
    begin
        if IR_DATA = x"FF" then
            current_ir_str <= STR_HALT;
        elsif IR_DATA(7) = '0' then
            case IR_DATA(6 downto 4) is
                when "000" => current_ir_str <= STR_ADD;
                when "001" => current_ir_str <= STR_SUB;
                when "010" => 
                    if IR_DATA(1 downto 0) = "00" then current_ir_str <= STR_INC;
                    else current_ir_str <= STR_DEC; end if;
                when "011" => current_ir_str <= STR_AND;
                when "100" => current_ir_str <= STR_OR;
                when "101" => current_ir_str <= STR_NOT;
                when "110" => current_ir_str <= STR_XOR;
                when "111" => 
                    if IR_DATA(1 downto 0) = "00" then current_ir_str <= STR_ROL;
                    elsif IR_DATA(1 downto 0) = "01" then current_ir_str <= STR_ROR;
                    elsif IR_DATA(1 downto 0) = "10" then current_ir_str <= STR_LSL;
                    else current_ir_str <= STR_LSR; end if;
                when others => current_ir_str <= STR_UNKN;
            end case;
        else
            case IR_DATA(6 downto 4) is
                when "000" => 
                    if IR_DATA(1 downto 0) = "00" then current_ir_str <= STR_PUSH;
                    elsif IR_DATA(1 downto 0) = "01" then current_ir_str <= STR_POP;
                    elsif IR_DATA(1 downto 0) = "10" then current_ir_str <= to_std_logic_vector("st Rx, 0x--     ");
                    else current_ir_str <= STR_LD; end if;
                when "001" => current_ir_str <= STR_LDR;
                when "010" => current_ir_str <= STR_STR;
                when "011" => current_ir_str <= STR_MOV;
                when "100" => 
                    if IR_DATA(1 downto 0) = "00" then current_ir_str <= STR_JMP;
                    elsif IR_DATA(1 downto 0) = "01" then current_ir_str <= STR_JMPR;
                    elsif IR_DATA(1 downto 0) = "10" then current_ir_str <= STR_BZ;
                    else current_ir_str <= STR_BNZ; end if;
                when "101" =>
                    if IR_DATA(1 downto 0) = "00" then current_ir_str <= STR_BCS;
                    elsif IR_DATA(1 downto 0) = "01" then current_ir_str <= STR_BCC;
                    elsif IR_DATA(1 downto 0) = "10" then current_ir_str <= STR_BEQ;
                    else current_ir_str <= STR_BNEQ; end if;
                when "110" => 
                    if IR_DATA(1 downto 0) = "00" then current_ir_str <= STR_BGT;
                    else current_ir_str <= STR_BLT; end if;
                when others => current_ir_str <= STR_UNKN;
            end case;
        end if;
    end process;

    -- =========================================================================
    -- 4. VALOR DA MEMÓRIA PARA BCD E INSERÇÃO NA STRING
    -- =========================================================================
    process(MEMORY)
        variable bcd_val  : unsigned(11 downto 0);
        variable base_str : rom_str := to_std_logic_vector("MEM[255] =      ");
    begin
        bcd_val := to_bcd(unsigned(MEMORY));
        
        -- Inserindo os valores BCD convertidos para ASCII (0x30 a 0x39)
        base_str(22) := x"3"; base_str(23) := std_logic_vector(bcd_val(11 downto 8));
        base_str(24) := x"3"; base_str(25) := std_logic_vector(bcd_val(7 downto 4));
        base_str(26) := x"3"; base_str(27) := std_logic_vector(bcd_val(3 downto 0));

        current_mem_str <= base_str;
    end process;

    -- =========================================================================
    -- 5. CONSTRUÇÃO DO PACOTE DE DADOS PARA O DISPLAY
    -- =========================================================================
    process(current_ir_str, current_mem_str)
    begin
        -- Posiciona cursor (Linha 1)
        refresh_seq(0) <= (rs => '0', data => x"8");
        refresh_seq(1) <= (rs => '0', data => x"0");
        
        -- Preenche Linha 1
        for i in 0 to 31 loop
            refresh_seq(2 + i) <= (rs => '1', data => current_ir_str(i));
        end loop;
        
        -- Posiciona cursor (Linha 2)
        refresh_seq(34) <= (rs => '0', data => x"C");
        refresh_seq(35) <= (rs => '0', data => x"0");
        
        -- Preenche Linha 2
        for i in 0 to 31 loop
            refresh_seq(36 + i) <= (rs => '1', data => current_mem_str(i));
        end loop;
    end process;

    -- =========================================================================
    -- 6. MÁQUINA DE ESTADOS DE ESCRITA NO LCD
    -- =========================================================================
    sync_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then
                state    <= idle;
                counter  <= (others => '0');
                idx_data <= 0;
                LCD_E    <= '0';
                LCD_RS   <= '0';
                DATA     <= (others => '0');
            else
                case state is
                    when idle =>
                        LCD_E  <= '0'; LCD_RS <= '0';
                        DATA   <= (others => '0');
                        if LCD_INIT_DONE = '1' then
                            state    <= write_a;
                            idx_data <= 0;
                            counter  <= (others => '0');
                        end if;

                    when write_a =>
                        LCD_RS <= refresh_seq(idx_data).rs;
                        LCD_E  <= '1';
                        DATA   <= refresh_seq(idx_data).data;

                        if counter = E_HIGH_CYCLES then
                            state   <= write_b;
                            counter <= (others => '0');
                        else
                            counter <= counter + 1;
                        end if;

                    when write_b =>
                        LCD_RS <= refresh_seq(idx_data).rs;
                        LCD_E  <= '0';

                        if counter = E_LOW_CYCLES then
                            counter <= (others => '0');
                            if idx_data = 67 then
                                state <= wait_refresh;
                            else
                                idx_data <= idx_data + 1;
                                state    <= write_a;
                            end if;
                        else
                            counter <= counter + 1;
                        end if;

                    when wait_refresh =>
                        if counter = WAIT_CYCLES then
                            counter  <= (others => '0');
                            idx_data <= 0;
                            state    <= write_a;
                        else
                            counter <= counter + 1;
                        end if;

                    when others => state <= idle;
                end case;
            end if;
        end if;
    end process sync_proc;

end Behavioral;