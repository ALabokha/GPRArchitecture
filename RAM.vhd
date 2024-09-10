library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.commands.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM is
	 Generic ( RegWidth: integer := RAM_chunk_size;
				  AddressWidth : integer := RAM_address_width;
				  InitialState : RAM_inner_data := RAM_data_amount);
    Port ( WR : in  STD_LOGIC; -- write or read operation; if '1' then try to write to register and output nothing; else output value
			  CLK : in STD_LOGIC; 
           Addr : in  RAM_address_chunk;
           Din : in  RAM_chunk;
           Dout : out RAM_chunk );
end RAM;

architecture Behavioral of RAM is

signal data: RAM_inner_data := InitialState;

begin
	write_clock: process(WR, CLK, Din, Addr)
	begin
		if rising_edge(CLK) then
			if WR = '1' then
				data(to_integer(unsigned(Addr))) <= Din;
			end if;
		end if;
	end process;
	
	Dout <= data(to_integer(unsigned(Addr))) when (WR = '0') else (others => 'Z');
	
end Behavioral;

