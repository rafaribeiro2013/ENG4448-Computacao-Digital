library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity comparador is
    Port ( a : in  STD_LOGIC;
           b : in  STD_LOGIC;
           z : out  STD_LOGIC);
end comparador;

architecture Behavioral of comparador is

begin
    Z <= (A and B) or (not(A) and not(B));

end Behavioral;

