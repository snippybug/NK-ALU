-- ²âÊÔcomponent

library ieee;

use ieee.std_logic_1164.all;

entity adder_2 is
	port(
		a0, b0, a1, b1, c0 : in std_logic;
		s0, s1, c1 : out std_logic
	);
end entity;

architecture behavior of adder_2 is
component full_adder
	port(
		a, b, c0: in std_logic;
		s, c1 : out std_logic
	);
end component;
signal x : std_logic;
begin

ins0:full_adder port map(a=>a0, b=>b0, c0=>c0, s=>s0, c1=>x);
ins1:full_adder port map(a=>a1, b=>b1, c0=>x, s=>s1, c1=>c1);

end architecture;