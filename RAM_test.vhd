LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY RAM_test IS
END RAM_test;
 
ARCHITECTURE behavior OF RAM_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 COMPONENT RAM
	 GENERIC ( RegWidth: integer := 8;
				  AddressWidth : integer := 3);
    PORT ( 
			  RST : in  STD_LOGIC;
			  WR : in  STD_LOGIC; -- write or read operation; if '1' then try to write to register and output nothing; else output value
			  CE : in STD_LOGIC; -- write enable
           Addr : in  STD_LOGIC_VECTOR (AddressWidth-1 downto 0);
           Din : in  std_logic_vector(RegWidth-1 downto 0);
           Dout : out  std_logic_vector(RegWidth-1 downto 0) );
    END COMPONENT;
   
	constant regW : integer := 8;
	constant addrW : integer := 3;
	
   --Inputs
   signal RST : std_logic := '0';
   signal WR : std_logic := '0';
   signal CE : std_logic := '0';
   signal Addr : std_logic_vector(addrW-1 downto 0) := (others => '0');
   signal Din : std_logic_vector(regW-1 downto 0) := (others => '0');

 	--Outputs
   signal Dout : std_logic_vector(regW-1 downto 0);
	constant outputZ : std_logic_vector(regW-1 downto 0) := (others => 'Z');
   
   constant CLK_period : time := 1 ns;
	signal iterAddr, iterReg: integer;
	signal addrV : std_logic_vector(addrW-1 downto 0);
	signal regV : std_logic_vector(regW-1 downto 0);
	signal regV_noCEwrite : std_logic_vector(regW-1 downto 0);
 
BEGIN
 
	uut: RAM 
	GENERIC MAP (regW, addrW)
	PORT MAP (
          RST => RST,
			 WR => WR,
			 CE => CE,
          Addr => Addr,
          Din => Din,
          Dout => Dout
        );
		  
	simulate: process
	begin
		addrV <= (others => '0');
		iterAddr <= 0;
		wait for CLK_period / 128;
		while iterAddr < 2**addrW-1 loop
			regV <= (others => '0');
			regV_noCEwrite <= (others => '0');
			iterReg <= 0;
			Addr <= addrV;
			wait for CLK_period / 4;
			while iterReg < 2**regW loop
				WR <= '1';
				CE <= '1';
				Din <= regV;
				wait for CLK_period / 4 * 2;
				regV_noCEwrite <= std_logic_vector(unsigned(regV) + 1);
				CE <= '0';
				assert Dout = outputZ report "Assertion error Z." severity error;
				wait for CLK_period / 4 * 1;
				Din <= regV_noCEwrite;
				wait for CLK_period / 4 * 2;
				WR <= '0';
				wait for CLK_period / 4;
				assert Dout = regV report "Assertion error." severity error;
				regV <= std_logic_vector(unsigned(regV) + 1);
				iterReg <= iterReg + 1;
				wait for CLK_period / 4;
			end loop;
			iterAddr <= iterAddr + 1;
			addrV <= std_logic_vector(unsigned(addrV) + 1);
			wait for CLK_period / 128;
		end loop;
		assert false report "successfully completed..." severity failure;
	end process;
	
	--CLK <= not CLK after CLK_period / 2;

END;
