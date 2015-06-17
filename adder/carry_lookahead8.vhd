-- 8位超前进位加法器

library ieee;
use ieee.std_logic_1164.all;

entity carry_lookahead8 is
	port(
		A, B : in std_logic_vector (7 downto 0);
		C0 : in std_logic;
		S: out std_logic_vector (7 downto 0);
		P, G : out std_logic
	);
end entity;

architecture behavior of carry_lookahead8 is
signal C_in: std_logic_vector (7 downto 0);
signal G_in: std_logic_vector (7 downto 0);
signal P_in: std_logic_vector (7 downto 0);
begin

S <= A xor B xor C_in;

P <= P_in(0) and P_in(1) and P_in(2) and P_in(3) and
	 P_in(4) and P_in(5) and P_in(6) and P_in(7);

G <= G_in(7)
	or (G_in(6) and P_in(7))
	or (G_in(5) and P_in(7) and P_in(6)) 
	or (G_in(4) and P_in(7) and P_in(6) and P_in(5)) 
	or (G_in(3) and P_in(7) and P_in(6) and P_in(5) and P_in(4)) 
	or (G_in(2) and P_in(7) and P_in(6) and P_in(5) and P_in(4) and P_in(3)) 
	or (G_in(1) and P_in(7) and P_in(6) and P_in(5) and P_in(4) and P_in(3) and P_in(2)) 
	or (G_in(0) and P_in(7) and P_in(6) and P_in(5) and P_in(4) and P_in(3) and P_in(2) and P_in(1));

G_in <= A and B;
P_in <= A or B;

C_in(0) <= C0;
C_in(1) <= G_in(0) 
			or (C0 and P_in(0));
C_in(2) <= G_in(1) 
			or (G_in(0) and P_in(1)) 
			or (C0 and P_in(1) and P_in(0));
C_in(3) <= G_in(2) 
			or (G_in(1) and P_in(2)) 
			or (G_in(0) and P_in(2) and P_in(1)) 
			or (C0 and P_in(2) and P_in(1) and P_in(0));
C_in(4) <= G_in(3) 
			or (G_in(2) and P_in(3)) 
			or (G_in(1) and P_in(3) and P_in(2)) 
			or (G_in(0) and P_in(3) and P_in(2) and P_in(1)) 
			or (C0 and P_in(3) and P_in(2) and P_in(1) and P_in(0));
C_in(5) <= G_in(4) 
			or (G_in(3) and P_in(4)) 
			or (G_in(2) and P_in(4) and P_in(3)) 
			or (G_in(1) and P_in(4) and P_in(3) and P_in(2)) 
			or (G_in(0) and P_in(4) and P_in(3) and P_in(2) and P_in(1) and P_in(0)) 
			or (C0 and P_in(4) and P_in(3) and P_in(4) and P_in(2) and P_in(1) and P_in(0));
C_in(6) <= G_in(5) 
			or (G_in(4) and P_in(5)) 
			or (G_in(3) and P_in(5) and P_in(4)) 
			or (G_in(2) and P_in(5) and P_in(4) and P_in(3)) 
			or (G_in(1) and P_in(5) and P_in(4) and P_in(3) and P_in(2)) 
			or (G_in(0) and P_in(5) and P_in(4) and P_in(3) and P_in(2) and P_in(1)) 
			or (C0 and P_in(5) and P_in(4) and P_in(3) and P_in(2) and P_in(1) and P_in(0));
C_in(7) <= G_in(6) 
			or (G_in(5) and P_in(6)) 
			or (G_in(4) and P_in(6) and P_in(5)) 
			or (G_in(3) and P_in(6) and P_in(5) and P_in(4)) 
			or (G_in(2) and P_in(6) and P_in(5) and P_in(4) and P_in(3)) 
			or (G_in(1) and P_in(6) and P_in(5) and P_in(4) and P_in(3) and P_in(2)) 
			or (G_in(0) and P_in(6) and P_in(5) and P_in(4) and P_in(3) and P_in(2) and P_in(1)) 
			or (C0 and P_in(6) and P_in(5) and P_in(4) and P_in(3) and P_in(2) and P_in(1) and P_in(0));

end architecture;