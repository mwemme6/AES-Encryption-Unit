library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity shift_rows is
    port(
        clk: in std_logic;
        reset: in std_logic;
        enable: in std_logic;
        state_in: in aes_matrix;
        done: out std_logic;
        state_out: out aes_matrix  
    );
end entity;

architecture RTL of shift_rows is

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                done <= '0';
    
            elsif enable = '1' and reset = '0' then
                for row in 0 to 3 loop
                    state_out(row, 0) <= state_in(row, (0 + row) mod 4);
                    state_out(row, 1) <= state_in(row, (1 + row) mod 4);
                    state_out(row, 2) <= state_in(row, (2 + row) mod 4);
                    state_out(row, 3) <= state_in(row, (3 + row) mod 4);
                end loop;
                done <= '1';
    
            else
                done <= '0';
                
            end if;
        end if;
    end process;
    
end RTL; 