library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity mix_column is
    port(
        clk: in std_logic;
        reset: in std_logic;
        enable: in std_logic;
        state_in: in aes_matrix;
        done: out std_logic;
        state_out: out aes_matrix  
    );
end entity;

architecture RTL of mix_column is
    --FUNCTIONS--
    function gf2(byte_in: std_logic_vector(7 downto 0)) return std_logic_vector is
        variable temp: std_logic_vector(7 downto 0);
    begin
        if byte_in(7) = '1' then
            temp := byte_in(6 downto 0) & '0' xor x"1B";
        else 
            temp := byte_in(6 downto 0) & '0';
        end if;

        return temp;
    end function;
    
    function gf3(byte_in: std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return gf2(byte_in) xor byte_in;
    end function;

    --SIGNALS--
    -- signal done_internal : std_logic := '0';
    -- signal temp : aes_matrix := (others => (others => (others => '0')));

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                done <= '0';
            
            elsif enable = '1' and reset = '0' then
                for column in 0 to 3 loop
                    state_out(0, column) <= gf2(state_in(0, column)) xor gf3(state_in(1, column)) xor state_in(2, column) xor state_in(3, column);
                    state_out(1, column) <= state_in(0, column) xor gf2(state_in(1, column)) xor gf3(state_in(2, column)) xor state_in(3, column);
                    state_out(2, column) <= state_in(0, column) xor state_in(1, column) xor gf2(state_in(2, column)) xor gf3(state_in(3, column));
                    state_out(3, column) <= gf3(state_in(0, column)) xor state_in(1, column) xor state_in(2, column) xor gf2(state_in(3, column));
                end loop;
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;
    

end RTL;