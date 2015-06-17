library ieee;

use ieee.std_logic_1164.all;

entity full_adder is
	port(
		a, b, c0 : in std_logic;
		c1, s : out std_logic
	);
end entity;

architecture behavior of full_adder is
begin

c1 <= (b and c0) or (a and b) or (a and c0);
s <= a xor b xor c0;

end architecture;