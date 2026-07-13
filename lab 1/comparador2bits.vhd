library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity comparador2bits is
    Port ( a : in  STD_LOGIC_VECTOR(1 downto 0);
           b : in  STD_LOGIC_VECTOR(1 downto 0);
           z : out  STD_LOGIC);
end comparador2bits;

architecture Behavioral of comparador2bits is

    signal comp : STD_LOGIC_VECTOR(1 downto 0);

begin
     comparador_primeiro_bit : entity work.comparador(Behavioral)
     port map(
         a => a(0),
         b => b(0),
         z => comp(0)
     );
     
     comparador_segundo_bit : entity work.comparador(Behavioral)
     port map(
         a => a(1),
         b => b(1),
         z => comp(1)
     );

    z <= comp(0) and comp(1);

end Behavioral;

