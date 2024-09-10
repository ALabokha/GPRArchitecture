library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

package commands is

constant RAM_chunk_size: integer := 8;
constant RAM_address_width: integer := 6;
subtype RAM_chunk is std_logic_vector(RAM_chunk_size-1 downto 0);
subtype RAM_address_chunk is std_logic_vector(RAM_address_width-1 downto 0);

constant ROM_command_width: integer := 4;
constant ROM_operand_width: integer := RAM_chunk_size;
constant ROM_register_width: integer := RAM_chunk_size;
constant ROM_chunk_size: integer := ROM_command_width + ROM_operand_width + ROM_register_width;
constant ROM_address_width: integer := 6;
subtype ROM_chunk is std_logic_vector(ROM_chunk_size-1 downto 0);
subtype operand_chunk is std_logic_vector(ROM_operand_width-1 downto 0);
subtype command_chunk is std_logic_vector(ROM_command_width-1 downto 0);
subtype register_chunk is std_logic_vector(ROM_register_width-1 downto 0);
subtype ROM_address_chunk is std_logic_vector(ROM_address_width-1 downto 0);

constant CMD_MOVF: command_chunk := "0000";	-- 0
constant CMD_MOVLF: command_chunk := CMD_MOVF + "1";	-- 1
constant CMD_MOVRF: command_chunk := CMD_MOVLF + "1";	-- 10
constant CMD_SUBLR: command_chunk := CMD_MOVRF + "1";	-- 11
constant CMD_SUBRR: command_chunk := CMD_SUBLR + "1";		-- 100
constant CMD_BTFSC_GO: command_chunk := CMD_SUBRR + "1";		-- 101
constant CMD_BTFSS_GO: command_chunk := CMD_BTFSC_GO + "1";		-- 110
constant CMD_BTFSC_INC: command_chunk := CMD_BTFSS_GO + "1";			-- 111
constant CMD_GOTO: command_chunk := CMD_BTFSC_INC + "1";		-- 1000
constant CMD_DECR: command_chunk := CMD_GOTO + "1";			-- 1001
constant CMD_MOVF_REGADDR: command_chunk := CMD_DECR + "1";			-- 1010
constant CMD_END: command_chunk := CMD_MOVF_REGADDR + "1";		-- 1011

constant REGFile_chunk_size: integer := RAM_address_width;
constant REGFile_address_width: integer := 2;
subtype REGFile_chunk is std_logic_vector(REGFile_chunk_size-1 downto 0);
subtype REGFile_address_chunk is std_logic_vector(REGFile_address_width-1 downto 0);

constant RAMAddressMax : integer := 2 ** RAM_address_width - 1;
type RAM_inner_data is array (0 to RAMAddressMax) of RAM_chunk;
constant REGFileAddressMax : integer := 2 ** REGFile_address_width - 1;
type REGFile_inner_data is array (0 to REGFileAddressMax) of REGFile_chunk;
constant ROMAddressMax : integer := 2 ** ROM_address_width - 1;
type ROM_inner_data is array (0 to ROMAddressMax) of ROM_chunk;
constant GPRCount : integer := 4;
type TGPRArray is array (0 to GPRCount-1) of RAM_chunk;

constant NO_REG: register_chunk := "11111111";
constant RA0: register_chunk := "00000000";
constant RA1: register_chunk := "00000001";
constant RA2: register_chunk := "00000010";
constant RESULT: register_chunk := "00000011";

constant ROM_data_amount: ROM_inner_data := (
0 => CMD_MOVLF & "00000000" & "00000000",			--clear result
1 => CMD_MOVLF & "00000001" & "00000000",			--clear error code
2 => CMD_MOVF & "00000010" & RA0,			--min_address
3 => CMD_SUBLR & "00000100" & RA0,		--SUBSTRACT literal
4 => CMD_BTFSC_GO & "00000000" & "00010010", 	--BTFSC + GOTO
5 => CMD_MOVF & "00000011" & RA1,			--max_address
6 => CMD_SUBLR & "10000000" & RA1,		--SUBSTRACT literal from top stack value
7 => CMD_BTFSS_GO & "00000000" & "00010010", 		--BTFSC + GOTO
8 => CMD_SUBRR & RA1 & RA0,	
9 => CMD_BTFSC_GO & "00000000" & "00010010", 		--BTFSC + GOTO
--cycle 1010
10 => CMD_MOVF_REGADDR & RA1 & RA2,			--load array value
11 => CMD_SUBLR & "00000000" & RA2,		--substract zero
12 => CMD_BTFSC_INC & "00000001" & RESULT, 		--BTFSC STATUS, 2
13 => CMD_DECR & "00000001" & RA1, 		--decr current address
14 => CMD_SUBRR & RA1 & RA0,		--SUB cur_address - min address
15 => CMD_BTFSS_GO & "00000000" & "00001010", 		--BTFSS + goto
16 => CMD_MOVRF & "00000000" & RESULT,		--save result
17 => CMD_GOTO & "00010011" & NO_REG,		--GOTO END
--set error code 10010
18 => CMD_MOVLF & "00000001" & "00000001",		--set, that error occured
--finish execution 10011
19 => CMD_END & "00000000" & NO_REG,			--end
others => (others => '0')
);

constant ROM_data_amount_fast: ROM_inner_data := (
0 => CMD_MOVLF & "00000000" & "00000000",			--clear result
1 => CMD_MOVLF & "00000001" & "00000000",			--clear error code
2 => CMD_MOVF & "00000010" & RA0,			--min_address
3 => CMD_MOVF & "00000011" & RA1,			--max_address
--cycle 100
4 => CMD_MOVF_REGADDR & RA1 & RA2,			--load array value
5 => CMD_SUBLR & "00000000" & RA2,		--substract zero
6 => CMD_BTFSC_INC & "00000001" & RESULT, 		--BTFSC STATUS, 2
7 => CMD_DECR & "00000001" & RA1, 		--decr current address
8 => CMD_SUBRR & RA1 & RA0,		--SUB cur_address - min address
9 => CMD_BTFSS_GO & "00000000" & "00000100", 		--BTFSS + goto
10 => CMD_MOVRF & "00000000" & RESULT,		--save result
11 => CMD_END & "00000000" & NO_REG,			--end
others => (others => '0')
);

constant RAM_data_amount: RAM_inner_data := (
0 => "00000000", 	--result
1 => "00000000", 	--error_code
2 => "00000111", 	--min_address
3 => "01111111", 	--max_address
--data array 0 to 7
7 => "00010011",
10 => "00000111",
11 => "10000000",
12 => "00001010",
others => (others => '0')
);

constant RAM_wrong_adresses: RAM_inner_data := (
0 => "00000000", 	--result
1 => "00000000", 	--error_code
2 => "00000101", 	--min_address
3 => "11111100", 	--max_address
--data array 0 to 7
4 => "00000000",	
5 => "00110000",		
6 => "00010011",
7 => "00000000",
8 => "00000000",
9 => "00000111",
10 => "10000000",
11 => "00001010", 
others => (others => '0')
);

constant GPR_Empty: TGPRArray := (
others => (others => '0')
);

end commands;

--package body commands is
--end commands;
