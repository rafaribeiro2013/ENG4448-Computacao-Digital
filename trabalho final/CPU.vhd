library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu is
    port (
        CLK            : in     STD_LOGIC;
        RESET          : in     STD_LOGIC;
        -- CPU / RAM
        RAM_DIN         : out std_logic_vector(7 downto 0);
        RAM_DOUT        : in  std_logic_vector(7 downto 0);
        RAM_ADDR        : out std_logic_vector(7 downto 0);
        RAM_WE          : out std_logic;
        -- CPU / LCD
        OPCODE          : out std_logic_vector(7 downto 0);
        -- LEDS
        LEDS_OUT        : OUT STD_LOGIC_VECTOR(7 downto 0) 
        
    );
end cpu;

architecture Behavioral of cpu is        
    
    -- registradores
    signal SP : UNSIGNED(7 downto 0) := to_unsigned(254, 8);
    signal PC, IR, MAR : unsigned(7 downto 0) := (others => '0');
    
    type reg_t is array (0 to 3) of STD_LOGIC_VECTOR(7 downto 0);
    signal REG : reg_t := ( -- 4 regs (REG A,B,C,D)
        0 => "00000000",
		1 => "00000001",
		2 => "00000010",
		3 => "00000011"      
    );
    
    -- FSM para as operacoes da cpu
    type FSM_CPU is (FETCH, DECODE_1, DECODE_2, EXECUTE);
    signal STATE : FSM_CPU := FETCH;

    signal ALU_A        : unsigned(7 downto 0) := x"00";
    signal ALU_B        : unsigned(7 downto 0) := x"00";
    signal ALU_R        : unsigned(7 downto 0) := x"00";
    signal ALU_ZERO     : STD_LOGIC := '0';
    signal ALU_SINAL    : STD_LOGIC := '0';
    signal ALU_EQUAL    : STD_LOGIC := '0';
    signal ALU_GREATER  : STD_LOGIC := '0';
    signal ALU_SMALLER  : STD_LOGIC := '0';
    signal ALU_CMD      : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal ALU_CIN      : STD_LOGIC := '0';
    signal ALU_COUT     : STD_LOGIC := '0';


begin

    u_alu : entity work.alu(Behavioral)
        port map (
            A         => ALU_A,
            B         => ALU_B,
            COMANDO   => ALU_CMD,
            R         => ALU_R,
            ZERO      => ALU_ZERO,
            SINAL     => ALU_SINAL,
            OVERFLOW  => ALU_COUT,
            EQUAL     => ALU_EQUAL,
            GREATER   => ALU_GREATER,
            SMALLER   => ALU_SMALLER
        );
    
    p_fsm_cycle : process(CLK)
    begin
        if rising_edge(CLK) then
            if (RESET = '1') then
                -- registradores
                REG(0)       <= x"00";
                REG(1)       <= x"00";
                REG(2)       <= x"00";
                REG(3)       <= x"00";
                -- IR, PC, MAR, MBR
                IR           <= x"00";
                PC           <= x"00";
                MAR          <= x"00";   
                -- SP = 254
                SP           <= x"FE";
                STATE        <= FETCH;
            else
                case STATE is
                    -- FETCH instruction from ram
                    when FETCH =>
                        IR <= unsigned(RAM_DOUT);
                        OPCODE <= std_logic_vector(unsigned(RAM_DOUT));
                        RAM_WE <= '0';
                        STATE <= DECODE_1;
                    
                    -- DECODE fetched opcode
                    when DECODE_1 =>
								STATE <= EXECUTE;
                        if IR(7) = '0' then -- instrues de ALU
                            ALU_A <= unsigned(REG(to_integer(unsigned(IR(3 downto 2)))));
                            ALU_B <= unsigned(REG(to_integer(unsigned(IR(1 downto 0)))));
                            if IR(6 downto 4) = "000" then -- add
                                ALU_CMD <= "0000";
                            elsif IR(6 downto 4) = "001" then -- sub
                                ALU_CMD <= "0001"; 
                            elsif IR(6 downto 4) = "010" and IR(1 downto 0) = "00" then -- inc
                                ALU_CMD <= "0010";
                            elsif IR(6 downto 4) = "010" and IR(1 downto 0) = "01" then -- dec
                                ALU_CMD <= "1010";
                            elsif IR(6 downto 4) = "011" then -- and
                                ALU_CMD <= "0011";
                            elsif IR(6 downto 4) = "100" then -- or
                                ALU_CMD <= "0100";
                            elsif IR(6 downto 4) = "101" then -- not
                                ALU_CMD <= "0101";
                            elsif IR(6 downto 4) = "110" then -- xor
                                ALU_CMD <= "0110";
                            elsif IR(6 downto 4) = "111" and IR(1 downto 0) = "00" then -- rol
                                ALU_CMD <= "0111";
                            elsif IR(6 downto 4) = "111" and IR(1 downto 0) = "01" then -- ror
                                ALU_CMD <= "1000";
                            elsif IR(6 downto 4) = "111" and IR(1 downto 0) = "10" then -- lsl
                                ALU_CMD <= "1001";
                            elsif IR(6 downto 4) = "111" and IR(1 downto 0) = "11" then -- lsr
                                ALU_CMD <= "1011";
                            end if;
                        else -- IR(7) = "1"
                            if IR(6 downto 4) = "000" and IR(1 downto 0) = "00" then -- push
                                MAR      <= SP;            -- endereo da pilha
										  RAM_WE <= '1';
								RAM_DIN  <= std_logic_vector(REG(to_integer(unsigned(IR(3 DOWNTO 2)))));
                            elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "01" then -- pop
                                MAR      <= SP + 1;        -- SP + 1 primeiro
                            elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "10" then -- st
                                MAR      <= PC + 1;        -- l ADDR no prximo byte
                                state    <= DECODE_2;
                            elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "11" then -- ld
                                MAR      <= PC + 1;        -- l ADDR
										  state    <= DECODE_2;
                            elsif IR(6 downto 4) = "001" then -- ldr
                                MAR      <= unsigned(REG(to_integer(IR(1 downto 0))));
                            elsif IR(6 downto 4) = "010" then -- str
                                MAR      <= unsigned(REG(to_integer(IR(1 downto 0))));
                                RAM_DIN  <= std_logic_vector(REG(to_integer(IR(3 downto 2))));
										  RAM_WE <= '1';
                            elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "00" then -- jmp
                                MAR <= PC + 1;
                                state    <= DECODE_2;
                            elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "01" then -- jmpr
                                MAR <= unsigned(REG(to_integer(IR(3 downto 2))));
                            elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "10" then -- bz
                                MAR <= unsigned(REG(to_integer(IR(3 downto 2))));
                            elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "11" then -- bnz
                                MAR <= unsigned(REG(to_integer(IR(3 downto 2))));
                            elsif IR(6 downto 4) = "101" then -- bcs, bcc, beq, bneq
                                MAR <= unsigned(REG(to_integer(IR(3 downto 2))));
                            elsif IR(6 downto 4) = "110" then -- bgt, blt
                                MAR <= unsigned(REG(to_integer(IR(3 downto 2))));
                            end if;
                        end if;

                    -- DECODE fetched opcode 
                    when DECODE_2 =>
                        if IR(6 downto 4) = "000" and IR(1 downto 0) = "10" then -- st 
                            MAR <= unsigned(RAM_DOUT);
                            RAM_DIN <= std_logic_vector(REG(to_integer(IR(3 downto 2))));
									 RAM_WE <= '1';
                            STATE <= EXECUTE;
                            
                        elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "11" then -- ld 
                            STATE <= EXECUTE;
									 
								elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "00" then -- jmp
                            STATE <= EXECUTE;
                        end if;

                    -- EXECUTE instruction
                    when EXECUTE =>
                        if IR = "11111111" then -- halt
                            state <= EXECUTE;
                        else
                            if IR(7) = '0' then -- instrues de ALU
                                REG(to_integer(unsigned(IR(3 downto 2)))) <= std_logic_vector(ALU_R);
                                --verificar sinais da ALU
                                PC  <= PC + 1;
                                MAR <= PC + 1;
                            else
                                if IR(6 downto 4) = "000" and IR(1 downto 0) = "00" then -- push
                                    RAM_WE <= '0';
                                    SP     <= SP - 1;
                                    PC     <= PC + 1;
                                    MAR    <= PC + 1;
                                elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "01" then -- pop
                                    REG(to_integer(IR(3 downto 2))) <= RAM_DOUT;
                                    SP  <= SP + 1;
                                    PC  <= PC + 1;
                                    MAR <= PC + 1;
                                elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "10" then -- st
                                    RAM_WE <= '0';
                                    PC     <= PC + 2;
                                    MAR    <= PC + 2;
                                elsif IR(6 downto 4) = "000" and IR(1 downto 0) = "11" then -- ld
                                    REG(to_integer(IR(3 downto 2))) <= RAM_DOUT;
                                    PC     <= PC + 2;
                                    MAR    <= PC + 2;
                                elsif IR(6 downto 4) = "001" then -- ldr
                                    REG(to_integer(IR(3 downto 2))) <= RAM_DOUT;
                                    PC     <= PC + 1;
                                    MAR    <= PC + 1;
                                elsif IR(6 downto 4) = "010" then -- str
                                    RAM_WE <= '0';
                                    PC     <= PC + 1;
                                    MAR    <= PC + 1;
                                elsif IR(6 downto 4) = "011" then -- mov
                                    REG(to_integer(IR(3 downto 2))) <= REG(to_integer(IR(1 downto 0)));
                                    PC <= PC + 1;
                                    MAR <= PC + 1;
                                elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "00" then -- jmp
                                    PC <= unsigned(RAM_DOUT);
												MAR <= unsigned(RAM_DOUT);
                                elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "01" then -- jmpr
                                    PC <= MAR;
                                elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "10" then -- bz
                                    if (ALU_ZERO = '1') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "100" and IR(1 downto 0) = "11" then -- bnz
                                    if (ALU_ZERO = '0') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "101" and IR(1 downto 0) = "00" then -- bcs
                                    if (ALU_COUT = '1') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "101" and IR(1 downto 0) = "01" then -- bcc
                                    if (ALU_COUT = '0') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "101" and IR(1 downto 0) = "10" then -- beq
                                    if (ALU_EQUAL = '1') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "101" and IR(1 downto 0) = "11" then -- bneq
                                    if (ALU_EQUAL = '0') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "110" and IR(1 downto 0) = "00" then -- bgt
                                    if (ALU_GREATER = '1') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                elsif IR(6 downto 4) = "110" and IR(1 downto 0) = "01" then -- blt
                                    if (ALU_SMALLER = '1') then
                                        PC  <= MAR;
                                    else
                                        PC  <= PC + 1;
                                        MAR <= PC + 1;
                                    end if;
                                end if;
                            end if;
                            STATE <= FETCH;
                        end if;
                    when others =>
                        STATE <= FETCH;     
                end case;
            end if;
        end if;
    end process;
    
    RAM_ADDR <= std_logic_vector(MAR);
    LEDS_OUT <= ( 
    0 => ALU_COUT,
    1 => ALU_ZERO,
	2 => ALU_SMALLER,
	3 => ALU_GREATER,
	4 => ALU_EQUAL,
    5 => ALU_SINAL,
    6 => '0',
    7 => clk);
    
end Behavioral;
