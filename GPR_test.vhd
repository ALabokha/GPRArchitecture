LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.commands.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY GPR_test IS
END GPR_test;
 
ARCHITECTURE behavior OF GPR_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT GPRHWA
    Generic (
			  cur_RAM_chunk_size: integer := RAM_chunk_size;
			  cur_RAM_address_width: integer := RAM_address_width;
			  cur_RAM_data: RAM_inner_data := RAM_data_amount;
			  cur_ROM_chunk_size: integer := ROM_chunk_size;
			  cur_ROM_address_width: integer := ROM_address_width;
			  cur_ROM_data: ROM_inner_data := ROM_data_amount;
			  cur_CMD_width: integer := ROM_command_width);
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           Start : in  STD_LOGIC;
           Stop : out  STD_LOGIC);
    END COMPONENT;
    
   signal CLK : std_logic := '0';
   signal RST : std_logic := '0';
   signal Start : std_logic := '0';
   signal Stop : std_logic;

   constant ram_data: RAM_inner_data := RAM_data_amount;
	constant rom_data: ROM_inner_data := ROM_data_amount;
	
	constant CLK_period: time := 5 ns;
 
BEGIN
 
	uut: GPRHWA
	GENERIC MAP (RAM_chunk_size, RAM_address_width, ram_data, ROM_chunk_size, ROM_address_width, rom_data, ROM_command_width)
	PORT MAP (
          CLK => CLK,
          RST => RST,
          Start => Start,
          Stop => Stop
        );
	
	CLK <= not CLK after CLK_period / 2;

   tb : PROCESS
	  BEGIN
			wait for CLK_period * 9 / 8;
			RST <= '1';
			wait for CLK_period / 8;
			RST <= '0';
			wait for CLK_period;
			Start <= '1';
			wait for CLK_period;
			Start <= '0';
			wait for CLK_period * 4060;
			assert false report "simulation completed..." severity failure;
	  END PROCESS tb;

END;
