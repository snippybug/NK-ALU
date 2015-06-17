-- 32位加法器，基于8位的超前进位加法器

library ieee;
use ieee.std_logic_1164.all;

entity adder32 is
	port(
	A, B : in std_logic_vector(31 downto 0);
	Cin : in std_logic;
	S : out std_logic_vector(31 downto 0);
	Cout : out std_logic
	);
end entity;

architecture behavior of adder32 is
signal P,G: std_logic_vector(3 downto 0);
signal C_in : std_logic_vector(3 downto 1);
component carry_lookahead8
	port(
		A, B : in std_logic_vector (7 downto 0);
		C0 : in std_logic;
		S: out std_logic_vector (7 downto 0);
		P, G : out std_logic
	);
end component;
begin

ins0:carry_lookahead8 port map(A=>A(7 downto 0), B=>B(7 downto 0), C0=>Cin, S=>S(7 downto 0), P=>P(0), G=>G(0));
ins1:carry_lookahead8 port map(A=>A(15 downto 8), B=>B(15 downto 8), C0=>C_in(1), S=>S(15 downto 8), P=>P(1), G=>G(1));
ins2:carry_lookahead8 port map(A=>A(23 downto 16), B=>B(23 downto 16), C0=>C_in(2), S=>S(23 downto 16), P=>P(2), G=>G(2));
ins3:carry_lookahead8 port map(A=>A(31 downto 24), B=>B(31 downto 24), C0=>C_in(3), S=>S(31 downto 24), P=>P(3), G=>G(3));

C_in(1) <= G(0)
		or (Cin and P(0));
C_in(2) <= G(1)
		or (G(0) and P(1))
		or (Cin and P(1) and P(0));
C_in(3) <= G(2)
		or (G(1) and P(2))
		or (G(0) and P(2) and P(1))
		or (Cin and P(2) and P(1) and P(0));
Cout <= G(3)
		or (G(2) and P(3))
		or (G(1) and P(3) and P(2))
		or (G(0) and P(3) and P(2) and P(1))
		or (Cin and P(3) and P(2) and P(1) and P(0));

end architecture;