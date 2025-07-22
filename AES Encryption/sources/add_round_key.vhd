library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity add_round_key is 
    port(
        clk: in std_logic;
        reset: in std_logic;
        enable: in std_logic;
        state_in: in aes_matrix;
        round_keys: in all_round_key_word;
        cur_round: in integer range 0 to 10;
        done: out std_logic;
        state_out: out aes_matrix
    );
end entity;

architecture RTL of add_round_key is
    -- signal done_internal : std_logic := '0';
    -- signal temp : aes_matrix := (others => (others => (others => '0')));
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                done <= '0';
            
            elsif enable = '1' and reset = '0' then
                for row in 0 to 3 loop
                    for column in 0 to 3 loop
                        state_out(row, column) <= state_in(row, column) xor round_keys(4 * cur_round + column)(8 * (3 - row) + 7 downto 8 * (3 - row));

                    end loop;
                    done <= '1';
                end loop;
            
            else
            done <= '0';
            
            end if;
        end if;
    end process;
    
    --output assignments
    -- done <= done_internal;
    -- state_out <= temp;
end architecture;