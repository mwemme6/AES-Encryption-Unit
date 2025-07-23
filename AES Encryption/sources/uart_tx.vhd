library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        BAUD_PERIOD : integer);
    Port ( 
        data_in : in std_logic_vector(7 downto 0);
        transmit_en : in std_logic; 
        reset : in std_logic; 
        clk : in std_logic;
        tx: out std_logic;
        new_symbol: out std_logic);
end uart_tx;

architecture Behavioral of uart_tx is
---------------------------
--FSM States
---------------------------
type state_type is (Idle, Load, Transmit);
signal CS, NS : state_type := Idle;

---------------------------
--FSM Signals
---------------------------
Signal symbol_load : std_logic := '0';
signal length_tc : std_logic := '0';
Signal length_cnt_en  : std_Logic := '0';

---------------------------
--ROM Signals
---------------------------
Signal sci_code : std_logic_vector(9 downto 0) := (others => '0');

---------------------------
--Datapath Signals
---------------------------
signal new_bit : std_logic := '0';
signal bit_cnt : integer := 0;
signal data_register : std_logic_vector(9 downto 0) :=(others => '1');
signal baud_cnt: integer := 0;

begin 

sci_code <= '1' & data_in & '0'; 
-------------------
-- Baud counter 
-------------------
baud_counter: process(clk, baud_cnt)
begin
    if rising_edge(clk) then
        baud_cnt <= baud_cnt + 1;
        if symbol_load = '1' or new_bit = '1' then   
            baud_cnt <= 0; 
        end if;
    end if; 

    new_bit <= '0';
    if baud_cnt = BAUD_PERIOD-1 then
        new_bit <= '1';
    end if;
end process; 

---------------------------------
-- Bit counter and shift register
---------------------------------
bit_counter: process(clk, bit_cnt)
begin
    if rising_edge(clk) then 
        if symbol_load = '1' then
            bit_cnt <= 10; 
            data_register <= sci_code;
        elsif new_bit = '1' then 
            data_register <= '1' & data_register(9 downto 1) ; 
            if length_cnt_en = '1' then 
                bit_cnt <= bit_cnt - 1;
            end if; 
        end if;
    end if; 
    
    length_tc <= '0'; 
    if bit_cnt = 0 then 
        length_tc <= '1'; 
    end if;
end process; 

tx <= data_register(0); 
new_symbol <= symbol_load; 


-------------------
--FSM Logic
-------------------
state_update : process(clk, reset) 
begin 
    if reset = '1' then 
        CS <= Idle;
    elsif rising_edge(clk) then
        CS <= NS;
    end if;
end process;


NS_Logic : process(CS, transmit_en, length_tc)
begin
    NS <= CS;
    case CS is 
        when Idle => 
            if transmit_en = '1' then 
                NS <= Load; 
            end if;
        when Load => 
            NS <= Transmit;
        when Transmit => 
            if length_tc = '1' then 
                NS <= Idle;
            end if;
        when Others => null;
    end case; 
end process;


Output_Logic : Process(CS)
begin 
    symbol_load <= '0';
    length_cnt_en <= '0';
    case CS is 
        when Load => 
            symbol_load <= '1';
        when Transmit => 
           length_cnt_en <= '1';
        when Others => null;
    end case;
end process;

end Behavioral;
