library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.commands.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ROM is
    Generic ( RegWidth: integer := ROM_chunk_size;
				  AddressWidth : integer := ROM_address_width;
				  InitialState : ROM_inner_data := ROM_data_amount);
    Port ( Addr : in  STD_LOGIC_VECTOR (AddressWidth-1 downto 0);
           Dout : out  STD_LOGIC_VECTOR (RegWidth-1 downto 0));
end ROM;

architecture Behavioral of ROM is
begin

reading: process(Addr)
begin
	Dout <= InitialState(conv_integer(Addr));
end process;

end Behavioral;

