library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
  generic(
    BAUD_PERIOD : integer);
  Port ( 
    receive_en : in std_logic; 
    reset : in std_logic; 
  	clk : in STD_Logic;
  	rx : in std_logic;
    sci_ready : out std_logic;
    sci_output : out std_logic_vector(7 downto 0));
end uart_rx;

architecture Behavioral of uart_rx is
---------------------------
--FSM States
---------------------------
type state_type is (Idle, Shift, Ready);
signal CS, NS : State_type := Idle;

---------------------------
--FSM Control Signals
---------------------------
signal baud_cnt_en : std_logic := '0';
Signal bit_cnt_en : std_logic := '0';

---------------------------
--Datapath Signals
---------------------------
constant HALF_BAUD_PERIOD : integer := BAUD_PERIOD / 2;
signal baud_cnt: integer := 0;
signal baud_tc : std_logic := '0';
signal half_baud_tc : std_logic := '0';
signal bit_tc : std_logic := '0';
signal bit_cnt : integer := 0;
signal data_register : std_logic_vector(9 downto 0) := (others => '0');

begin
---------------------------
--Baud Counter
---------------------------
baud_counter: process(clk, baud_cnt)
begin
	if rising_edge(clk) then
    	if baud_cnt_en = '1' then 
        	baud_cnt <= baud_cnt + 1;
        end if; 
        if baud_tc = '1' or baud_cnt_en = '0' then   --resets the count when tc
            baud_cnt <= 0;
        end if;
    end if; 
    
    --asynchronous TC
    baud_tc <= '0';
    if baud_cnt = BAUD_PERIOD-1 then
        baud_tc <= '1';
    end if;
    
    half_baud_tc <= '0'; 
    if baud_cnt = HALF_BAUD_PERIOD - 1 then 
    	half_baud_tc <= '1'; 
    end if;
end process; 

---------------------------
--Bit Counter
---------------------------
bit_counter: process(clk, bit_cnt, reset)
begin
    if rising_edge(clk) then
    	if bit_cnt_en = '1' and half_baud_tc = '1' then 
        	bit_cnt <= bit_cnt + 1; 
        end if;
        
        if bit_cnt_en = '0' or bit_tc = '1' then 
        	bit_cnt <= 0;
        end if; 
    end if; 
    
    -- asynchronous bit count TC
    bit_tc <= '0'; 
    if bit_cnt = 10 then 
    	bit_tc <= '1'; 
    end if;
end process;

shift_register: process(clk)
begin
    if rising_edge(clk) then 
        if half_baud_tc = '1' then 
            data_register <= rx & data_register(9 downto 1); 
        end if;
    end if; 
end process;

sci_output <= data_register(8 downto 1);

----------------------------------------
--FSM Logic 
----------------------------------------

state_update : process(clk, reset)
begin
    if reset = '1' then 
        CS <= Idle;
    elsif (rising_edge(clk)) then
        CS <= NS;
    end if;
end process;

NS_Logic : process(CS, rx, receive_en, bit_tc)
begin
    NS <= CS; 
    case CS is 
        when Idle => 
            if rx = '0' then
                NS <= Shift;
            end if;
        when Shift =>
            if receive_en = '0' then 
                NS <= Idle;
            elsif bit_tC = '1' then
                NS <= Ready;
            end if;
        when Ready =>
            NS <= Idle;
        when Others =>
        	NS <= Idle;
        end case;
end process;


Output_Logic : Process(CS)
begin
    baud_cnt_en <= '0';
    bit_cnt_en <= '0';
    sci_ready <= '0';
    case CS is 
        when Ready => 
            sci_ready <= '1';
        when Shift =>
            baud_cnt_en <= '1';
            bit_cnt_en <= '1';
        when Others => null;
    end case;
end process;    

end Behavioral;