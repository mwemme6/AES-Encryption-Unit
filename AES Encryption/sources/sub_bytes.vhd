library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity sub_bytes is
    port(
        clk: in std_logic;
        reset: in std_logic;
        enable: in std_logic;
        state_in: in aes_matrix;
        done: out std_logic;
        state_out: out aes_matrix  
    );
end entity;

architecture RTL of sub_bytes is 

    -- signal temp : aes_matrix := (others => (others => (others => '0')));
    -- signal done_internal : std_logic := '0';

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                done <= '0';
            
            elsif enable = '1' and reset = '0' then
                for row in 0 to 3 loop
                    for column in 0 to 3 loop
                        state_out(row, column) <= sbox(to_integer(unsigned(state_in(row, column))));
                    end loop;
                end loop;
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;


end RTL;