-- 32λ�����ȸ������ӷ�
-- Author: Wang Zonglei
-- Date: 2015.6.12
-- �ο�<<Computer Organization and Design: The Hardware/Software Interface 5th>> Figure 3.15
-- 32λ�����ȸ������Ļ�������Ϊ1+8+23.1�Ƿ���λ��8��ָ��(������)���������ʾ��ƫ����=127��23��С������ȥ��ǰ��1
-- ��ˣ�����ö����Ʊ�ʾ1.0*2^(-1)�����Ϊ0 01111110 00000000000000000000

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity singleprecision_adder32 is
	port(
		A, B: in std_logic_vector(31 downto 0);			-- ����
		S : out std_logic_vector(31 downto 0);			-- ���
		debug_expdiff : out std_logic_vector(7 downto 0);
		debug_add1 : out std_logic_vector(27 downto 0);
		debug_add2 : out std_logic_vector(27 downto 0);
		debug_align_yes : out std_logic_vector(24 downto 0);
		debug_align_no : out std_logic_vector(24 downto 0);
		debug_add_out : out std_logic_vector(27 downto 0);
		debug_exp_1 : out std_logic_vector(7 downto 0);
		debug_normal_1 : out std_logic_vector(27 downto 0);
		debug_leading_count : out std_logic_vector(4 downto 0);
		debug_exp_2 : out std_logic_vector(7 downto 0);
		debug_normal_2 : out std_logic_vector(24 downto 0);
		debug_need_complement : out std_logic_vector(1 downto 0);
		debug_after_round : out std_logic_vector(25 downto 0);
		debug_after_complement : out std_logic_vector(27 downto 0);
		debug : out std_logic;
		debug_same_sign : out std_logic
	);
end entity;

architecture behavior of singleprecision_adder32 is

component adder32
	port(
		A, B : in std_logic_vector(31 downto 0);
		Cin : in std_logic;
		S : out std_logic_vector(31 downto 0);
		Cout : out std_logic
	);
end component;

function to_sign_magnitude(a : std_logic_vector)	-- ����ת��Ϊԭ��
	return std_logic_vector is
	variable b : std_logic_vector(a'length-1 downto 0);
begin
	if a(a'left) = '0' then		-- ����
		b := a;
	else						-- ����
		b := conv_std_logic_vector(0-signed('0'&a(a'length-2 downto 0)), b'length);
	end if;
	return b;
end;

function choose8_1(a : std_logic_vector; b : std_logic_vector)
	return std_logic is
	variable c : std_logic;
	variable va : std_logic_vector(a'length-1 downto 0) := a;
	variable vb : std_logic_vector(b'length-1 downto 0) := b;
begin
	case vb(2 downto 0) is
		when "000" =>
			c := va(0);
		when "001" =>
			c := va(1);
		when "010" =>
			c := va(2);
		when "011" =>
			c := va(3);
		when "100" =>
			c := va(4);
		when "101" =>
			c := va(5);
		when "110" =>
			c := va(6);
		when others =>
			c := va(7);
	end case;
	return c;
end;

function choose4_1(a : std_logic_vector; b : std_logic_vector)
	return std_logic is
	variable c : std_logic;
	variable va : std_logic_vector(a'length-1 downto 0) := a;
	variable vb : std_logic_vector(b'length-1 downto 0) := b;
begin
	case vb(1 downto 0) is
		when "00" =>
			c := va(0);
		when "01" =>
			c := va(1);
		when "10" =>
			c := va(2);
		when others =>
			c := va(3);
	end case;
	return c;
end;

function reverse(a : std_logic_vector)
	return std_logic_vector is
	variable va : std_logic_vector(0 to a'length-1) := a;
	variable b : std_logic_vector(a'length-1 downto 0);
begin
	for i in va'range loop
		b(i) := va(i);
	end loop;
	return b;
end;

signal exp_diff : std_logic_vector(7 downto 0);		-- ������ָ�����ֵĲһ��Ϊ��
signal exp_flag : std_logic;						-- ָ����С�źţ�0����a��1����b��
signal exp_sel : std_logic_vector(7 downto 0);		-- ѡ���ָ��
signal add1, add2 : std_logic_vector(27 downto 0);			-- �ӷ����Ĳ�����
signal align_yes, align_no : std_logic_vector(24 downto 0);		-- ������λ���Ĳ�����
signal add_out : std_logic_vector(27 downto 0);				-- �ӷ������
signal add_over : std_logic;								-- �ӷ�������ź�
signal same_sign : std_logic;								-- �Ƿ�ͬ��
signal leading_count : std_logic_vector(4 downto 0);		-- add_out��ǰ��������1��0�ĸ���(����������λ)
signal normal_1 : std_logic_vector(27 downto 0);			-- ��һ�ι�񻯺��С������
signal exp_1 : std_logic_vector(7 downto 0);				-- ��һ�ι�񻯺��ָ������
signal normal_2 : std_logic_vector(24 downto 0);			-- �ڶ��ι�񻯺��С������
signal exp_2 : std_logic_vector(7 downto 0);				-- �ڶ��ι�񻯺��ָ������
signal after_round : std_logic_vector(25 downto 0);			-- ��ȥβ����Ľ�������λ�����λ
signal need_complement : std_logic_vector(1 downto 0);		-- �Ƿ���Ҫ�����ս��ȡ������
signal after_complement : std_logic_vector(27 downto 0);
begin

debug_expdiff <= exp_diff;
debug_add1 <= add1;
debug_add2 <= add2;
debug_align_yes <= align_yes;
debug_align_no <= align_no;
debug_add_out <= add_out;
debug_normal_1 <= normal_1;
debug_exp_1 <= exp_1;
debug_leading_count <= leading_count;
debug_normal_2 <= normal_2;
debug_exp_2 <= exp_2;
debug_need_complement <= need_complement;
debug_after_round <= after_round;
debug_after_complement <= after_complement;
debug_same_sign <= same_sign;

same_sign <= '1' when A(A'left) = B(B'left) else
			'0';

diff_exp: process(a, b)
variable c1, c2 : unsigned(7 downto 0);
begin
	c1 := unsigned(a(30 downto 23));
	c2 := unsigned(b(30 downto 23));
	if c1 > c2 then							-- ָ����ģ�С�����ֲ���Ҫ��λ
		exp_diff <= conv_std_logic_vector(c1 - c2, c1'length);
		exp_flag <= '0';
		exp_sel <= conv_std_logic_vector(c1, exp_sel'length);
	else
		exp_diff <= conv_std_logic_vector(c2 - c1, c2'length);
		exp_flag <= '1';
		exp_sel <= conv_std_logic_vector(c2, exp_sel'length);
	end if;
end process;

choose_addend: process(exp_flag, a, b, same_sign)		-- ��Ҫ��λ�����ŵ�align_yes, ��һ���ŵ�align_no
											-- ���⣬����������ķ��Ų�һ�£���align_no����ȡ������
variable a_ex : std_logic_vector(23 downto 0);
variable b_ex : std_logic_vector(23 downto 0);
begin
	a_ex := '1' & a(22 downto 0);		-- ��׼��ʡ�Ե�'1'
	b_ex := '1' & b(22 downto 0);		-- ��׼��ʡ�Ե�'1'
	if exp_flag = '0' then			-- a��ָ����
		-- ��a��b����Ҷ������󷴣���Ҫ�Խ����
		if same_sign = '0' then
			if a(a'left) = '1' then
				need_complement <= "01";		--����ֻ��
			else
				need_complement <= "10";		--������Ҫ���෴��
			end if;
		else
			need_complement <= "00";
		end if;
		align_yes <= '0' & b_ex;			-- ǿ��Ϊ����
		if same_sign = '1' then		-- a��bͬ��
			align_no <= '0' & a_ex;			-- ǿ��Ϊ����
		else											-- a��b���
			align_no <= conv_std_logic_vector(0-signed('0' & a_ex), align_no'length);	-- ��b���������󷴣�һ��Ϊ��
		end if;
	else							-- b��ָ����
		-- ��a��b����Ҷ������󷴣���Ҫ�Խ����
		if same_sign = '0' then
			if b(b'left) = '1' then
				need_complement <= "01";
			else
				need_complement <= "10";
			end if;
		else
			need_complement <= "00";
		end if;
		
		align_yes <= '0' & a_ex;			-- ǿ��Ϊ����
		if same_sign = '1' then		-- a��bͬ��
			align_no <= '0' & b_ex;			-- ǿ��Ϊ����
		else											-- a��b���
			align_no <= conv_std_logic_vector(0-signed('0' & b_ex), align_no'length);	-- ��b����������
			-- ��a��b����Ҷ������󷴣���Ҫ�Խ����
		end if;
	end if;
end process;

align_significands:process(exp_diff, align_yes, align_no)

function or32_1(a : std_logic_vector; b : std_logic_vector)
	return std_logic is
	variable c : std_logic;
	variable va : std_logic_vector(a'length-1 downto 0) := a;
	variable vb : std_logic_vector(b'length-1 downto 0) := b;
begin
	case vb(4 downto 0) is
		-- ��C��������
		when "00000" =>
			c := va(0);
		when "00001" =>
			c := va(0) or va(1);
		when "00010" =>
			c := va(0) or va(1) or va(2);
		when "00011" =>
			c := va(0) or va(1) or va(2) or va(3);
		when "00100" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4);
		when "00101" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5);
		when "00110" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6);
		when "00111" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7);
		when "01000" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8);
		when "01001" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9);
		when "01010" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10);
		when "01011" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11);
		when "01100" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12);
		when "01101" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13);
		when "01110" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14);
		when "01111" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15);
		when "10000" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16);
		when "10001" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17);
		when "10010" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18);
		when "10011" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19);
		when "10100" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20);
		when "10101" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21);
		when "10110" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22);
		when "10111" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23);
		when "11000" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24);
		when "11001" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25);
		when "11010" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25) or va(26);
		when "11011" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25) or va(26) or va(27);
		when "11100" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25) or va(26) or va(27) or va(28);
		when "11101" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25) or va(26) or va(27) or va(28) or va(29);
		when "11110" =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25) or va(26) or va(27) or va(28) or va(29) or va(30);
		when others =>
			c := va(0) or va(1) or va(2) or va(3) or va(4) or va(5) or va(6) or va(7) or va(8) or va(9) or va(10) or va(11) or va(12) or va(13) or va(14) or va(15) or va(16) or va(17) or va(18) or va(19) or va(20) or va(21) or va(22) or va(23) or va(24) or va(25) or va(26) or va(27) or va(28) or va(29) or va(30) or va(31);
	end case;
	return c;
end;

variable low3 : std_logic_vector(2 downto 0);
variable high2 : std_logic_vector(1 downto 0);
variable valign_yes : std_logic_vector(31 downto 0);	
begin
	add1 <= align_no & "000";		-- add1����Ҫ��λ
	low3 := exp_diff(2 downto 0);
	high2 := exp_diff(4 downto 3);
	valign_yes := "0000" & align_yes & "000";		--�ճ�32λ
	if unsigned(exp_diff) > 31 then
		add2 <= conv_std_logic_vector(0, add2'length);
	else
		-- add2�Ĵ�����C��������(����add2(0))
		add2(0) <= or32_1(valign_yes, exp_diff);
		add2(1) <= choose4_1(
			choose8_1('0' & valign_yes(31 downto 25), low3) &
			choose8_1(valign_yes(24 downto 17), low3) &
			choose8_1(valign_yes(16 downto 9), low3) &
			choose8_1(valign_yes(8 downto 1), low3), high2);
		add2(2) <= choose4_1(
			choose8_1("00" & valign_yes(31 downto 26), low3) &
			choose8_1(valign_yes(25 downto 18), low3) &
			choose8_1(valign_yes(17 downto 10), low3) &
			choose8_1(valign_yes(9 downto 2), low3), high2);
		add2(3) <= choose4_1(
			choose8_1("000" & valign_yes(31 downto 27), low3) &
			choose8_1(valign_yes(26 downto 19), low3) &
			choose8_1(valign_yes(18 downto 11), low3) &
			choose8_1(valign_yes(10 downto 3), low3), high2);
		add2(4) <= choose4_1(
			choose8_1("0000" & valign_yes(31 downto 28), low3) &
			choose8_1(valign_yes(27 downto 20), low3) &
			choose8_1(valign_yes(19 downto 12), low3) &
			choose8_1(valign_yes(11 downto 4), low3), high2);
		add2(5) <= choose4_1(
			choose8_1("00000" & valign_yes(31 downto 29), low3) &
			choose8_1(valign_yes(28 downto 21), low3) &
			choose8_1(valign_yes(20 downto 13), low3) &
			choose8_1(valign_yes(12 downto 5), low3), high2);
		add2(6) <= choose4_1(
			choose8_1("000000" & valign_yes(31 downto 30), low3) &
			choose8_1(valign_yes(29 downto 22), low3) &
			choose8_1(valign_yes(21 downto 14), low3) &
			choose8_1(valign_yes(13 downto 6), low3), high2);
		add2(7) <= choose4_1(
			choose8_1("0000000" & valign_yes(31), low3) &
			choose8_1(valign_yes(30 downto 23), low3) &
			choose8_1(valign_yes(22 downto 15), low3) &
			choose8_1(valign_yes(14 downto 7), low3), high2);
		add2(8) <= choose4_1(
			'0' &
			choose8_1(valign_yes(31 downto 24), low3) &
			choose8_1(valign_yes(23 downto 16), low3) &
			choose8_1(valign_yes(15 downto 8), low3), high2);
		add2(9) <= choose4_1(
			'0' &
			choose8_1('0' & valign_yes(31 downto 25), low3) &
			choose8_1(valign_yes(24 downto 17), low3) &
			choose8_1(valign_yes(16 downto 9), low3), high2);
		add2(10) <= choose4_1(
			'0' &
			choose8_1("00" & valign_yes(31 downto 26), low3) &
			choose8_1(valign_yes(25 downto 18), low3) &
			choose8_1(valign_yes(17 downto 10), low3), high2);
		add2(11) <= choose4_1(
			'0' &
			choose8_1("000" & valign_yes(31 downto 27), low3) &
			choose8_1(valign_yes(26 downto 19), low3) &
			choose8_1(valign_yes(18 downto 11), low3), high2);
		add2(12) <= choose4_1(
			'0' &
			choose8_1("0000" & valign_yes(31 downto 28), low3) &
			choose8_1(valign_yes(27 downto 20), low3) &
			choose8_1(valign_yes(19 downto 12), low3), high2);
		add2(13) <= choose4_1(
			'0' &
			choose8_1("00000" & valign_yes(31 downto 29), low3) &
			choose8_1(valign_yes(28 downto 21), low3) &
			choose8_1(valign_yes(20 downto 13), low3), high2);
		add2(14) <= choose4_1(
			'0' &
			choose8_1("000000" & valign_yes(31 downto 30), low3) &
			choose8_1(valign_yes(29 downto 22), low3) &
			choose8_1(valign_yes(21 downto 14), low3), high2);
		add2(15) <= choose4_1(
			'0' &
			choose8_1("0000000" & valign_yes(31), low3) &
			choose8_1(valign_yes(30 downto 23), low3) &
			choose8_1(valign_yes(22 downto 15), low3), high2);
		add2(16) <= choose4_1(
			'0' &
			'0' &
			choose8_1(valign_yes(31 downto 24), low3) &
			choose8_1(valign_yes(23 downto 16), low3), high2);
		add2(17) <= choose4_1(
			'0' &
			'0' &
			choose8_1('0' & valign_yes(31 downto 25), low3) &
			choose8_1(valign_yes(24 downto 17), low3), high2);
		add2(18) <= choose4_1(
			'0' &
			'0' &
			choose8_1("00" & valign_yes(31 downto 26), low3) &
			choose8_1(valign_yes(25 downto 18), low3), high2);
		add2(19) <= choose4_1(
			'0' &
			'0' &
			choose8_1("000" & valign_yes(31 downto 27), low3) &
			choose8_1(valign_yes(26 downto 19), low3), high2);
		add2(20) <= choose4_1(
			'0' &
			'0' &
			choose8_1("0000" & valign_yes(31 downto 28), low3) &
			choose8_1(valign_yes(27 downto 20), low3), high2);
		add2(21) <= choose4_1(
			'0' &
			'0' &
			choose8_1("00000" & valign_yes(31 downto 29), low3) &
			choose8_1(valign_yes(28 downto 21), low3), high2);
		add2(22) <= choose4_1(
			'0' &
			'0' &
			choose8_1("000000" & valign_yes(31 downto 30), low3) &
			choose8_1(valign_yes(29 downto 22), low3), high2);
		add2(23) <= choose4_1(
			'0' &
			'0' &
			choose8_1("0000000" & valign_yes(31), low3) &
			choose8_1(valign_yes(30 downto 23), low3), high2);
		add2(24) <= choose4_1(
			'0' &
			'0' &
			'0' &
			choose8_1(valign_yes(31 downto 24), low3), high2);
		add2(25) <= choose4_1(
			'0' &
			'0' &
			'0' &
			choose8_1('0' & valign_yes(31 downto 25), low3), high2);
		add2(26) <= choose4_1(
			'0' &
			'0' &
			'0' &
			choose8_1("00" & valign_yes(31 downto 26), low3), high2);
		add2(27) <= align_yes(align_yes'left);
	end if;
end process;

add_out <= conv_std_logic_vector(signed(add1)+signed(add2), add_out'length);

selective_complement:process(add_out, need_complement)
begin
	case need_complement is
		when "01" =>
			after_complement <= conv_std_logic_vector(0-signed(add_out), after_complement'length);
			after_complement(after_complement'left) <= add_out(add_out'left);
		when "10" =>
			after_complement <= conv_std_logic_vector(0-signed(add_out), after_complement'length);
		when others =>
			after_complement <= add_out;
	end case;
end process;


counter_leading:process(after_complement, same_sign)
function count(a : std_logic_vector ; b : std_logic)
	return std_logic_vector is
	variable count : unsigned(4 downto 0);
begin
	count := "00000";
	if b = '0' then		-- ͳ��0�ĸ���
		for i in a'range loop
			if a(i) = '0' then
				count := count + 1;
			else
				exit;
			end if;
		end loop;
	else				-- ͳ��1�ĸ���
		for j in a'range loop
			if a(j) = '1' then
				count := count + 1;
			else
				exit;
			end if;
		end loop;
	end if;
	return conv_std_logic_vector(count, count'length);
end;

begin
	if same_sign = '1' then			-- ���ͬ��
		if after_complement(after_complement'left) = '1' then		-- ����λΪ1˵���������
			leading_count <= "00000";			-- ֻ��Ҫ���
		else
			leading_count <= count(after_complement(after_complement'left-1 downto 0), '0');	-- ͳ��0�ĸ���
		end if;
	else							-- ������
		if after_complement(after_complement'left) = '1' then		-- ����λΪ1˵�����Ϊ��
			leading_count <= count(after_complement(after_complement'left-1 downto 0), '1');	-- ͳ��1�ĸ���
		else
			leading_count <= count(after_complement(after_complement'left-1 downto 0), '0');	-- ͳ��0�ĸ���
		end if;
	end if;
end process;


first_normalize:process(after_complement, leading_count, same_sign)	
variable no_sign : std_logic_vector(26 downto 0) := after_complement(after_complement'left-1 downto 0);		-- ȥ������λ��after_complement
variable no_sign_rev : std_logic_vector(31 downto 0);	-- ��after_complementȡ��Ȼ��ƴ�ӳ�32λ
variable shift_rev : std_logic_vector(26 downto 0);
variable low3 : std_logic_vector(2 downto 0) := leading_count(2 downto 0);
variable high2 : std_logic_vector(1 downto 0) := leading_count(4 downto 3);
begin
	no_sign_rev := "00000" & reverse(after_complement(after_complement'left-1 downto 0));
	if same_sign = '1' and after_complement(after_complement'left) = '1' then	-- ֻ��ͬ������ӣ��ſ��ܻ�����
		normal_1(normal_1'left) <= '0';
		normal_1(normal_1'left-1 downto 1) <= after_complement(after_complement'left downto 2);
		normal_1(0) <= after_complement(0) or after_complement(1);
	else
		-- ���źŵ�ת�������ƣ��ٵ�ת
		-- ��C����
		shift_rev(0) := choose4_1(
			choose8_1(no_sign_rev(31 downto 24), low3) &
			choose8_1(no_sign_rev(23 downto 16), low3) &
			choose8_1(no_sign_rev(15 downto 8), low3) &
			choose8_1(no_sign_rev(7 downto 0), low3), high2);
		shift_rev(1) := choose4_1(
			choose8_1('0' & no_sign_rev(31 downto 25), low3) &
			choose8_1(no_sign_rev(24 downto 17), low3) &
			choose8_1(no_sign_rev(16 downto 9), low3) &
			choose8_1(no_sign_rev(8 downto 1), low3), high2);
		shift_rev(2) := choose4_1(
			choose8_1("00" & no_sign_rev(31 downto 26), low3) &
			choose8_1(no_sign_rev(25 downto 18), low3) &
			choose8_1(no_sign_rev(17 downto 10), low3) &
			choose8_1(no_sign_rev(9 downto 2), low3), high2);
		shift_rev(3) := choose4_1(
			choose8_1("000" & no_sign_rev(31 downto 27), low3) &
			choose8_1(no_sign_rev(26 downto 19), low3) &
			choose8_1(no_sign_rev(18 downto 11), low3) &
			choose8_1(no_sign_rev(10 downto 3), low3), high2);
		shift_rev(4) := choose4_1(
			choose8_1("0000" & no_sign_rev(31 downto 28), low3) &
			choose8_1(no_sign_rev(27 downto 20), low3) &
			choose8_1(no_sign_rev(19 downto 12), low3) &
			choose8_1(no_sign_rev(11 downto 4), low3), high2);
		shift_rev(5) := choose4_1(
			choose8_1("00000" & no_sign_rev(31 downto 29), low3) &
			choose8_1(no_sign_rev(28 downto 21), low3) &
			choose8_1(no_sign_rev(20 downto 13), low3) &
			choose8_1(no_sign_rev(12 downto 5), low3), high2);
		shift_rev(6) := choose4_1(
			choose8_1("000000" & no_sign_rev(31 downto 30), low3) &
			choose8_1(no_sign_rev(29 downto 22), low3) &
			choose8_1(no_sign_rev(21 downto 14), low3) &
			choose8_1(no_sign_rev(13 downto 6), low3), high2);
		shift_rev(7) := choose4_1(
			choose8_1("0000000" & no_sign_rev(31), low3) &
			choose8_1(no_sign_rev(30 downto 23), low3) &
			choose8_1(no_sign_rev(22 downto 15), low3) &
			choose8_1(no_sign_rev(14 downto 7), low3), high2);
		shift_rev(8) := choose4_1(
			'0' &
			choose8_1(no_sign_rev(31 downto 24), low3) &
			choose8_1(no_sign_rev(23 downto 16), low3) &
			choose8_1(no_sign_rev(15 downto 8), low3), high2);
		shift_rev(9) := choose4_1(
			'0' &
			choose8_1('0' & no_sign_rev(31 downto 25), low3) &
			choose8_1(no_sign_rev(24 downto 17), low3) &
			choose8_1(no_sign_rev(16 downto 9), low3), high2);
		shift_rev(10) := choose4_1(
			'0' &
			choose8_1("00" & no_sign_rev(31 downto 26), low3) &
			choose8_1(no_sign_rev(25 downto 18), low3) &
			choose8_1(no_sign_rev(17 downto 10), low3), high2);
		shift_rev(11) := choose4_1(
			'0' &
			choose8_1("000" & no_sign_rev(31 downto 27), low3) &
			choose8_1(no_sign_rev(26 downto 19), low3) &
			choose8_1(no_sign_rev(18 downto 11), low3), high2);
		shift_rev(12) := choose4_1(
			'0' &
			choose8_1("0000" & no_sign_rev(31 downto 28), low3) &
			choose8_1(no_sign_rev(27 downto 20), low3) &
			choose8_1(no_sign_rev(19 downto 12), low3), high2);
		shift_rev(13) := choose4_1(
			'0' &
			choose8_1("00000" & no_sign_rev(31 downto 29), low3) &
			choose8_1(no_sign_rev(28 downto 21), low3) &
			choose8_1(no_sign_rev(20 downto 13), low3), high2);
		shift_rev(14) := choose4_1(
			'0' &
			choose8_1("000000" & no_sign_rev(31 downto 30), low3) &
			choose8_1(no_sign_rev(29 downto 22), low3) &
			choose8_1(no_sign_rev(21 downto 14), low3), high2);
		shift_rev(15) := choose4_1(
			'0' &
			choose8_1("0000000" & no_sign_rev(31), low3) &
			choose8_1(no_sign_rev(30 downto 23), low3) &
			choose8_1(no_sign_rev(22 downto 15), low3), high2);
		shift_rev(16) := choose4_1(
			'0' &
			'0' &
			choose8_1(no_sign_rev(31 downto 24), low3) &
			choose8_1(no_sign_rev(23 downto 16), low3), high2);
		shift_rev(17) := choose4_1(
			'0' &
			'0' &
			choose8_1('0' & no_sign_rev(31 downto 25), low3) &
			choose8_1(no_sign_rev(24 downto 17), low3), high2);
		shift_rev(18) := choose4_1(
			'0' &
			'0' &
			choose8_1("00" & no_sign_rev(31 downto 26), low3) &
			choose8_1(no_sign_rev(25 downto 18), low3), high2);
		shift_rev(19) := choose4_1(
			'0' &
			'0' &
			choose8_1("000" & no_sign_rev(31 downto 27), low3) &
			choose8_1(no_sign_rev(26 downto 19), low3), high2);
		shift_rev(20) := choose4_1(
			'0' &
			'0' &
			choose8_1("0000" & no_sign_rev(31 downto 28), low3) &
			choose8_1(no_sign_rev(27 downto 20), low3), high2);
		shift_rev(21) := choose4_1(
			'0' &
			'0' &
			choose8_1("00000" & no_sign_rev(31 downto 29), low3) &
			choose8_1(no_sign_rev(28 downto 21), low3), high2);
		shift_rev(22) := choose4_1(
			'0' &
			'0' &
			choose8_1("000000" & no_sign_rev(31 downto 30), low3) &
			choose8_1(no_sign_rev(29 downto 22), low3), high2);
		shift_rev(23) := choose4_1(
			'0' &
			'0' &
			choose8_1("0000000" & no_sign_rev(31), low3) &
			choose8_1(no_sign_rev(30 downto 23), low3), high2);
		shift_rev(24) := choose4_1(
			'0' &
			'0' &
			'0' &
			choose8_1(no_sign_rev(31 downto 24), low3), high2);
		shift_rev(25) := choose4_1(
			'0' &
			'0' &
			'0' &
			choose8_1('0' & no_sign_rev(31 downto 25), low3), high2);
		shift_rev(26) := choose4_1(
			'0' &
			'0' &
			'0' &
			choose8_1("00" & no_sign_rev(31 downto 26), low3), high2);

		normal_1(normal_1'left) <= after_complement(after_complement'left);
		normal_1(normal_1'left-1 downto 0) <= reverse(shift_rev);
	end if;
end process;

first_adjust_exp:process(exp_sel, leading_count, same_sign, after_complement(after_complement'left))
begin
	if same_sign = '1' and after_complement(after_complement'left) = '0' then
		exp_1 <= conv_std_logic_vector(unsigned(exp_sel) + 1, exp_1'length);
	else
		exp_1 <= conv_std_logic_vector(unsigned(exp_sel) - unsigned(leading_count), exp_1'length);
	end if;
end process;

round:process(normal_1)
begin
	if normal_1(2 downto 0) /= "000" then
		after_round <= conv_std_logic_vector(unsigned('0' & normal_1(normal_1'left downto normal_1'left - 24))+1, after_round'length);
	else
		after_round <= '0' & normal_1(normal_1'left downto normal_1'left - 24);
	end if;
end process;

second_normalize:process(after_round, normal_1(normal_1'left), exp_1)
begin
	if after_round(after_round'left - 1) /= normal_1(normal_1'left) then	-- ����λ��һ��˵�����������
		exp_2 <= conv_std_logic_vector(unsigned(exp_1)+1, exp_2'length);
		normal_2 <= after_round(after_round'left downto after_round'left - 24);
	else
		exp_2 <= exp_1;
		normal_2 <= after_round(after_round'left - 1 downto 0);
	end if;
end process;

pack:process(same_sign, exp_2, normal_2, A(A'left))
begin
	if same_sign = '1' then				-- ���������ͬ��Ӧ��ȡ����ķ���
		S(S'left) <= A(A'left);
	else								-- ����ȡ�������ķ���
		S(S'left) <= normal_2(normal_2'left);
	end if;
	S(30 downto 23) <= exp_2;
	S(22 downto 0) <= normal_2(22 downto 0);
end process;

end architecture;