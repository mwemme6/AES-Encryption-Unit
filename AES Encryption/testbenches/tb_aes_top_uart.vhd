library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
library work; 
use work.defs_pkg.all;

ENTITY tb_aes_top_uart IS
END tb_aes_top_uart;

ARCHITECTURE tb OF tb_aes_top_uart IS 

    COMPONENT aes_top_uart
    PORT(
        clk : in std_logic; 
        uart_rx_e : in std_logic; 
        reset : in std_logic; 
        uart_tx_e : out std_logic;
        done : out std_logic);
    end component;

	signal sci_rx_ext : std_logic := '1';
    constant clk_period : time := 100 ns;
    signal clk : std_logic := '0'; 
    signal data : std_logic_vector(127 downto 0) := x"3243f6a8885a308d313198a2e0370734"; 
    signal key : std_logic_vector(127 downto 0) := x"2b7e151628aed2a6abf7158809cf4f3c";
    signal sci_byte : std_logic_vector(9 downto 0) := (others => '0'); 
    signal reset : std_logic := '0'; 

    signal sci_tx_ext : std_logic;
    signal done_ext : std_logic;
BEGIN


    uut: aes_top_uart 
    PORT MAP (
        clk => clk,
        uart_rx_e => sci_rx_ext,
        reset => reset, 
        uart_tx_e => sci_tx_ext,
        done => done_ext
        );
        
    clk_process: process 
    begin
        clk <= not clk;
        wait for clk_period/2;  
    end process;
    
    stim_proc: process
    begin        
        wait for 100 * clk_period;
        
        for i in 0 to 15 loop
             sci_byte <= "1" & key(127 - 8 * i downto 120 - 8 * i) & "0"; 
             for j in 0 to 9 loop
                sci_rx_ext <= sci_byte(j);
                wait for 10 * clk_period;  
             end loop; 
        end loop; 
        
        sci_rx_ext <= '1'; 
        wait for 100 * clk_period; 
        
        for i in 0 to 15 loop
             sci_byte <= "1" & data(127 - 8 * i downto 120 - 8 * i) & "0"; 
             for j in 0 to 9 loop
                sci_rx_ext <= sci_byte(j);
                wait for 10 * clk_period;  
             end loop; 
        end loop;
        
        sci_rx_ext <= '1'; 
        wait for 10000 * clk_period; 
        
        reset <= '1'; 
        wait for 10 * clk_period; 
        
        reset <= '0'; 
        wait for 10 * clk_period; 
        
        for i in 0 to 15 loop
             sci_byte <= "1" & key(127 - 8 * i downto 120 - 8 * i) & "0"; 
             for j in 0 to 9 loop
                sci_rx_ext <= sci_byte(j);
                wait for 10 * clk_period;  
             end loop; 
        end loop; 
        
        sci_rx_ext <= '1'; 
        wait for 100 * clk_period; 
        
        for i in 0 to 15 loop
             sci_byte <= "1" & data(127 - 8 * i downto 120 - 8 * i) & "0"; 
             for j in 0 to 9 loop
                sci_rx_ext <= sci_byte(j);
                wait for 10 * clk_period;  
             end loop; 
        end loop;
        
        sci_rx_ext <= '1'; 
        wait for 100 * clk_period; 
        
        for i in 0 to 15 loop
             sci_byte <= "1" & data(127 - 8 * i downto 120 - 8 * i) & "0"; 
             for j in 0 to 9 loop
                sci_rx_ext <= sci_byte(j);
                wait for 10 * clk_period;  
             end loop; 
        end loop;
        
        wait; 
    end process;
    
end tb; 
