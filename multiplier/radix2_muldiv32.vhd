-- 32位乘法器and除法器
-- date 2015.6.19


library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity radix2_muldiv32 is
	port(
		A, B: in std_logic_vector(31 downto 0);		-- 乘法器输入
		S : out std_logic_vector(63 downto 0);		-- 乘法器输出
		Over : out std_logic;						-- 溢出信号
		CLK : in std_logic;							-- 时钟信号
		CS : in std_logic;							-- 片选信号
		busy: out std_logic;						-- 忙碌信号
		sel : in std_logic;							-- 乘除法选择信号
		RST: in std_logic;							-- 重置信号
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
signal state : std_logic_vector(1 downto 0);		-- 00代表空闲，01代表乘法，11代表除法
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

-- 产生加法器的一个加数/减数
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
		addend2 <= conv_std_logic_vector((conv_signed(0, addend2'length) - signed(B)), addend2'length);	-- B的补码
	when others=>
		addend2 <= conv_std_logic_vector('0', addend2'length);
	end case;
end process;

addend1 <= product(63 downto 32) when state = "01" else
			product(62 downto 31) when state = "11" else
			conv_std_logic_vector('0', addend1'length);

adder:adder32 port map(A=>addend1, B=>addend2, Cin=>C0, S=>add_res, Cout=>add_overflow);

C0 <= '0';	-- 注意，用conv_signed求得的信号已经是补码，所以C0没有作用

S<=product(63 downto 0);

busy <= state(0);

-- 结果寄存器(乘法：乘积；除法：高位是余数，低位是商)
process(clk)
begin
	if rising_edge(clk) then			
		if rst = '1' then					-- 同步复位
			product <= conv_std_logic_vector('0', product'length);
		else
			if state(0) = '0' and cs = '1' then
				product(31 downto 0) <= A;
			else
				if state = "01" then		-- 乘法
						product(30 downto 0) <= product(31 downto 1);
						product(63 downto 31) <= product(64)& add_res;
						product(64) <= add_overflow;
				else
					if state = "11" then						-- 除法
						if(add_res(31) = '0')	then		-- 结果为正
							product(64) <= product(63);
							product(63 downto 32) <= add_res;
							product(31 downto 1) <= product(30 downto 0);
							product(0) <= '1';
						else							-- 结果为负
							product(64 downto 1) <= product(63 downto 0);
							product(0) <= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
end process;

-- 乘数/除数寄存器
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

-- 状态寄存器
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

--计数寄存器
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