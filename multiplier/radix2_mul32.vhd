-- 32位简单的乘法器
-- date:2015.6.18

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity radix2_mul32 is
	port(
		A, B: in std_logic_vector(31 downto 0);		-- 乘法器输入
		S : out std_logic_vector(63 downto 0);		-- 乘法器输出
		Over : out std_logic;						-- 溢出信号
		CLK : in std_logic;							-- 时钟信号
		CS : in std_logic;							-- 片选信号
		busy: out std_logic;						-- 忙碌信号
		RST: in std_logic							-- 重置信号
	);
end entity;

architecture bahavior of radix2_mul32 is
signal product : std_logic_vector(64 downto 0);
signal multiplier : std_logic_vector(31 downto 0);
signal addend : std_logic_vector(31 downto 0);
signal add_res : std_logic_vector(31 downto 0);
signal add_overflow : std_logic;
signal state : std_logic;
signal counter : integer range 0 to 31;
component adder32
	port(
		A, B : in std_logic_vector(31 downto 0);
		Cin : in std_logic;
		S : out std_logic_vector(31 downto 0);
		Cout : out std_logic
	);
end component;
begin

addend <= B when product(0) = '1' else
		  conv_std_logic_vector('0', addend'length);

adder:adder32 port map(A=>addend, B=>product(63 downto 32), Cin=>'0', S=>add_res, Cout=>add_overflow);

S<=product(63 downto 0);

busy <= state;

-- 结果寄存器
process(clk)
begin
	if rising_edge(clk) then			
		if rst = '1' then					-- 同步复位
			product <= conv_std_logic_vector('0', product'length);
		else
			if state = '0' and cs = '1' then
				product(31 downto 0) <= A;
			else
				if state = '1' then
					product(30 downto 0) <= product(31 downto 1);
					product(63 downto 31) <= product(64)& add_res;
					product(64) <= add_overflow;
				end if;
			end if;
		end if;
	end if;
end process;

-- 乘数寄存器
process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			multiplier <= conv_std_logic_vector('0', multiplier'length);
		else
			if state = '0' and cs = '1' then
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
			state <= '0';
		else
			if state = '0' and cs = '1' then
				state <= '1';
			else
				if counter = 0 then
					state <= '0';
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
			if state = '1' then
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