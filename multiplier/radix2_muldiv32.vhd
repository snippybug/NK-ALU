-- 32λ�˷���and������
-- date 2015.6.19


library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity radix2_muldiv32 is
	port(
		A, B: in std_logic_vector(31 downto 0);		-- �˷�������
		S : out std_logic_vector(63 downto 0);		-- �˷������
		Over : out std_logic;						-- ����ź�
		CLK : in std_logic;							-- ʱ���ź�
		CS : in std_logic;							-- Ƭѡ�ź�
		busy: out std_logic;						-- æµ�ź�
		sel : in std_logic;							-- �˳���ѡ���ź�
		RST: in std_logic;							-- �����ź�
		debug_addres: out std_logic_vector(31 downto 0);
		debug_addend2 : out std_logic_vector(31 downto 0)
	);
end entity;

architecture bahavior of radix2_muldiv32 is
signal product : std_logic_vector(64 downto 0);
signal multiplier : std_logic_vector(31 downto 0);
signal addend1 : std_logic_vector(31 downto 0);
signal addend2 : std_logic_vector(31 downto 0);
signal add_res : std_logic_vector(31 downto 0);
signal add_overflow : std_logic;
signal state : std_logic_vector(1 downto 0);		-- 00������У�01����˷���11�������
signal counter : integer range 0 to 31;
signal C0 : std_logic;
component adder32
	port(
		A, B : in std_logic_vector(31 downto 0);
		Cin : in std_logic;
		S : out std_logic_vector(31 downto 0);
		Cout : out std_logic
	);
end component;
begin

debug_addres <= add_res;
debug_addend2 <= addend2;

-- �����ӷ�����һ������/����
process(product(0),state,B)
begin
	case state is
	when "01" =>
		if product(0) = '1' then
			addend2 <= B;
		else
			addend2 <= conv_std_logic_vector('0', addend2'length);
		end if;
	when "11" =>
		addend2 <= conv_std_logic_vector((conv_signed(0, addend2'length) - signed(B)), addend2'length);	-- B�Ĳ���
	when others=>
		addend2 <= conv_std_logic_vector('0', addend2'length);
	end case;
end process;

addend1 <= product(63 downto 32) when state = "01" else
			product(62 downto 31) when state = "11" else
			conv_std_logic_vector('0', addend1'length);

adder:adder32 port map(A=>addend1, B=>addend2, Cin=>C0, S=>add_res, Cout=>add_overflow);

C0 <= '0';	-- ע�⣬��conv_signed��õ��ź��Ѿ��ǲ��룬����C0û������

S<=product(63 downto 0);

busy <= state(0);

-- ����Ĵ���(�˷����˻�����������λ����������λ����)
process(clk)
begin
	if rising_edge(clk) then			
		if rst = '1' then					-- ͬ����λ
			product <= conv_std_logic_vector('0', product'length);
		else
			if state(0) = '0' and cs = '1' then
				product(31 downto 0) <= A;
			else
				if state = "01" then		-- �˷�
						product(30 downto 0) <= product(31 downto 1);
						product(63 downto 31) <= product(64)& add_res;
						product(64) <= add_overflow;
				else
					if state = "11" then						-- ����
						if(add_res(31) = '0')	then		-- ���Ϊ��
							product(64) <= product(63);
							product(63 downto 32) <= add_res;
							product(31 downto 1) <= product(30 downto 0);
							product(0) <= '1';
						else							-- ���Ϊ��
							product(64 downto 1) <= product(63 downto 0);
							product(0) <= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
end process;

-- ����/�����Ĵ���
process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			multiplier <= conv_std_logic_vector('0', multiplier'length);
		else
			if state(0) = '0' and cs = '1' then
				multiplier <= B;
			end if;
		end if;
	end if;
end process;

-- ״̬�Ĵ���
process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			state <= "00";
		else
			if state(0) = '0' and cs = '1' then
				if sel = '0' then
					state <= "01";
				else
					state <= "11";
				end if;
			else
				if counter = 0 then
					state <= "00";
				end if;
			end if;
		end if;
	end if;
end process;

--�����Ĵ���
process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			counter <= counter'high;
		else
			if state(0) = '1' then
				if counter = 0 then
					counter <= counter'high;
				else
					counter <= counter - 1;
				end if;
			end if;
		end if;
	end if;
end process;

end architecture;