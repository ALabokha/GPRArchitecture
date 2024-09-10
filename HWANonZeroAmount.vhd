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

entity GPRHWA is
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
end GPRHWA;

architecture Behavioral of GPRHWA is

component RAM
	 Generic ( RegWidth: integer := cur_RAM_chunk_size;
				  AddressWidth : integer := cur_RAM_address_width;
				  InitialState : RAM_inner_data := cur_RAM_data);
    Port ( WR : in  STD_LOGIC; 
			  CLK : in STD_LOGIC;
           Addr : in  STD_LOGIC_VECTOR (AddressWidth-1 downto 0);
           Din : in  std_logic_vector(RegWidth-1 downto 0);
           Dout : out  std_logic_vector(RegWidth-1 downto 0) );
end component;

component ROM
    Generic ( RegWidth: integer := ROM_chunk_size;
				  AddressWidth : integer := ROM_address_width;
				  InitialState : ROM_inner_data := cur_ROM_data);
    Port ( Addr : in  STD_LOGIC_VECTOR (AddressWidth-1 downto 0);
           Dout : out  STD_LOGIC_VECTOR (RegWidth-1 downto 0));
end component;

--will be changed
type state is (
	IDLE, --waiting for start signal
	FETCH,
	STATE_NEXT,
	STATE_GOTO,
	STATE_GOTO_SS,
	STATE_GOTO_SC,
	STORE,
	READ,
	SUBSTRACT, 
	INCRIMENT,
	DECRIMENT,
	HALT --done or interrupted
);

signal current_state: state := IDLE;
signal next_state: state;

signal RAM_WR : STD_LOGIC;
signal RAM_CLK : STD_LOGIC;
signal RAM_Addr : STD_LOGIC_VECTOR (cur_RAM_address_width-1 downto 0);
signal RAM_Din : STD_LOGIC_VECTOR (cur_RAM_chunk_size-1 downto 0);
signal RAM_Dout : STD_LOGIC_VECTOR (cur_RAM_chunk_size-1 downto 0);

signal ROM_Addr : STD_LOGIC_VECTOR (cur_ROM_address_width-1 downto 0);
signal ROM_Dout : STD_LOGIC_VECTOR (cur_ROM_chunk_size-1 downto 0);

signal ALU_CARRY, ALU_ZERO : boolean;

signal IC: std_logic_vector(cur_ROM_address_width-1 downto 0) := (others => '0');
signal GPR: TGPRArray := GPR_Empty;

signal instruction: std_logic_vector(cur_ROM_chunk_size-1 downto 0);
signal current_ROM_CMD: std_logic_vector(ROM_command_width-1 downto 0);
signal current_ROM_operand: std_logic_vector(cur_RAM_chunk_size-1 downto 0);
signal current_ROM_register: std_logic_vector(cur_RAM_chunk_size-1 downto 0);
signal current_ROM_parameter: std_logic; --'1' = ZERO FLAG		--'0' = SIGN_FLAG

begin

RAM_ports: RAM
	generic map (cur_RAM_chunk_size, cur_RAM_address_width, cur_RAM_data)
	port map (RAM_WR, RAM_CLK, RAM_Addr, RAM_Din, RAM_Dout);
	
ROM_ports: ROM
	generic map (cur_ROM_chunk_size, cur_ROM_address_width, cur_ROM_data)
	port map (ROM_Addr, ROM_Dout);

state_machine: process(next_state, CLK, RST)
begin 
	if RST = '1' then
		current_state <= IDLE;
	elsif rising_edge(CLK) then
		current_state <= next_state;
	end if;
end process;

rom_IC_update: process(CLK, RST, current_state, current_ROM_CMD, current_ROM_parameter)
begin
	if RST = '1' then
		IC <= (others => '0');
	elsif rising_edge(CLK) then
		if current_state = STATE_NEXT then
			IC <= IC + "1";
		elsif current_state = STATE_GOTO then 
			IC <= current_ROM_operand(ROM_address_width-1 downto 0);
		elsif current_state = STATE_GOTO_SS then
			if current_ROM_parameter = '0' and ALU_CARRY then
				IC <= IC + "1";
			 elsif current_ROM_parameter = '1' and ALU_ZERO then	
				IC <= IC + "1";
			else
				IC <= current_ROM_register(ROM_address_width-1 downto 0);
			end if;
		elsif current_state = STATE_GOTO_SC then
			if current_ROM_parameter = '0' and not ALU_CARRY then	
				IC <= IC + "1";
			elsif current_ROM_parameter = '1' and not ALU_ZERO then	
				IC <= IC + "1";
			else
				IC <= current_ROM_register(ROM_address_width-1 downto 0);
			end if;
		end if;
	end if;
end process;

read_next_instruction: process(RST, current_state, ROM_Dout)
begin
	if RST = '1' then
		instruction <= (others => '0');
	elsif current_state = FETCH then
		instruction <= ROM_Dout;
	end if;
end process;

decode_instruction: process(current_state, instruction, CLK)
begin
	if falling_edge(CLK) and current_state = FETCH then
		current_ROM_CMD <= instruction(ROM_command_width+ROM_operand_width+ROM_register_width-1 downto cur_RAM_chunk_size+ROM_register_width);
		current_ROM_operand <= instruction(cur_RAM_chunk_size+ROM_register_width-1 downto ROM_register_width);
		current_ROM_register <= instruction(ROM_register_width-1 downto 0);
		current_ROM_parameter <= instruction(ROM_register_width);
	end if;
end process;

store_proc: process(current_state, current_ROM_register, current_ROM_CMD, GPR)
begin
	if current_state = STORE then
		case current_ROM_CMD is
			when CMD_MOVLF => RAM_Din <= current_ROM_register;
			when CMD_MOVRF => RAM_Din <= GPR(conv_integer(current_ROM_register));
			when others => RAM_Din <= (others => '0');
		end case;
	end if;
end process;

change_gpr: process(current_state, current_ROM_CMD, current_ROM_operand, current_ROM_register, current_ROM_parameter, RAM_Dout)
begin		
	if current_state = READ then
		GPR(conv_integer(current_ROM_register)) <= RAM_Dout;
	elsif current_state = INCRIMENT then
		if current_ROM_parameter = '0' and not ALU_CARRY then	
			GPR(conv_integer(current_ROM_register)) <= std_logic_vector(unsigned(GPR(conv_integer(current_ROM_register))) + 1);
		elsif current_ROM_parameter = '1' and not ALU_ZERO then	
			GPR(conv_integer(current_ROM_register)) <= std_logic_vector(unsigned(GPR(conv_integer(current_ROM_register))) + 1);
		end if;
	elsif current_state = DECRIMENT then
		GPR(conv_integer(current_ROM_register)) <= std_logic_vector(unsigned(GPR(conv_integer(current_ROM_register))) - 1);
	end if;
end process;

set_ALU_result: process(current_state, current_ROM_CMD, current_ROM_operand, current_ROM_register, GPR)
variable result: STD_LOGIC_VECTOR (RAM_chunk_size downto 0) := (others => '0');
begin
	if current_state = SUBSTRACT then
		if current_ROM_CMD = CMD_SUBLR then
			result := std_logic_vector ( resize(unsigned (GPR(conv_integer(current_ROM_register))), RAM_chunk_size+1) - resize(unsigned(current_ROM_operand), RAM_chunk_size+1));
		elsif current_ROM_CMD = CMD_SUBRR then
			result := std_logic_vector ( resize(unsigned (GPR(conv_integer(current_ROM_operand))), RAM_chunk_size+1) - resize(unsigned(GPR(conv_integer(current_ROM_register))), RAM_chunk_size+1) );
		end if;
		ALU_CARRY <= result(RAM_chunk_size) = '1';
		if result = (result'range => '0') then
			ALU_ZERO <= true;
		else
			ALU_ZERO <= false;
		end if;
	end if;
end process;

define_next_state: process(current_state, Start, current_ROM_CMD)
begin
	case current_state is
		when IDLE =>
			if Start = '1' then
				next_state <= FETCH;
			else
				next_state <= IDLE;
			end if;
		when FETCH =>
			case current_ROM_CMD is
				when CMD_MOVF | CMD_MOVF_REGADDR => next_state <= READ;
				when CMD_SUBLR | CMD_SUBRR => next_state <= SUBSTRACT;
				when CMD_GOTO => next_state <= STATE_GOTO;
				when CMD_BTFSS_GO => next_state <= STATE_GOTO_SS;
				when CMD_BTFSC_GO => next_state <= STATE_GOTO_SC;
				when CMD_BTFSC_INC => next_state <= INCRIMENT;
				when CMD_DECR => next_state <= DECRIMENT;
				when CMD_MOVLF | CMD_MOVRF => next_state <= STORE;
				when CMD_END => next_state <= HALT;
				when others => next_state <= HALT;
			end case;
		when READ | STORE | SUBSTRACT | INCRIMENT | DECRIMENT => next_state <= STATE_NEXT;
		when STATE_GOTO_SS | STATE_GOTO_SC | STATE_GOTO | STATE_NEXT => next_state <= FETCH;
		when HALT  => next_state <= HALT;
		when others => next_state <= HALT;
	end case;
end process;

ROM_Addr <= IC;
RAM_CLK <= not CLK;
RAM_WR <= '1' when (current_state = STORE) else '0';
Stop <= '1' when (current_state = HALT) else '0';
RAM_Addr <= GPR(conv_integer(current_ROM_operand))(cur_RAM_address_width-1 downto 0) when (current_ROM_CMD = CMD_MOVF_REGADDR) else current_ROM_operand(cur_RAM_address_width-1 downto 0);

end Behavioral;

