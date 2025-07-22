library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity tb_add_round_key is
end entity;

architecture sim of tb_add_round_key is
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';
    signal enable    : std_logic := '0';
    signal done      : std_logic;
    signal cur_round : integer range 0 to 10 := 0;

    signal state_in  : aes_matrix;
    signal state_out : aes_matrix;
    signal round_keys: all_round_key_word;
    
    -- Debug signals for state_in (16 individual bytes)
    signal state_in_00, state_in_01, state_in_02, state_in_03 : std_logic_vector(7 downto 0);
    signal state_in_10, state_in_11, state_in_12, state_in_13 : std_logic_vector(7 downto 0);
    signal state_in_20, state_in_21, state_in_22, state_in_23 : std_logic_vector(7 downto 0);
    signal state_in_30, state_in_31, state_in_32, state_in_33 : std_logic_vector(7 downto 0);
    
    -- Debug signals for state_out (16 individual bytes)
    signal state_out_00, state_out_01, state_out_02, state_out_03 : std_logic_vector(7 downto 0);
    signal state_out_10, state_out_11, state_out_12, state_out_13 : std_logic_vector(7 downto 0);
    signal state_out_20, state_out_21, state_out_22, state_out_23 : std_logic_vector(7 downto 0);
    signal state_out_30, state_out_31, state_out_32, state_out_33 : std_logic_vector(7 downto 0);

    constant clk_period : time := 10 ns;
begin
    -- Connect debug signals
    state_in_00 <= state_in(0,0); state_in_01 <= state_in(0,1); state_in_02 <= state_in(0,2); state_in_03 <= state_in(0,3);
    state_in_10 <= state_in(1,0); state_in_11 <= state_in(1,1); state_in_12 <= state_in(1,2); state_in_13 <= state_in(1,3);
    state_in_20 <= state_in(2,0); state_in_21 <= state_in(2,1); state_in_22 <= state_in(2,2); state_in_23 <= state_in(2,3);
    state_in_30 <= state_in(3,0); state_in_31 <= state_in(3,1); state_in_32 <= state_in(3,2); state_in_33 <= state_in(3,3);
    
    state_out_00 <= state_out(0,0); state_out_01 <= state_out(0,1); state_out_02 <= state_out(0,2); state_out_03 <= state_out(0,3);
    state_out_10 <= state_out(1,0); state_out_11 <= state_out(1,1); state_out_12 <= state_out(1,2); state_out_13 <= state_out(1,3);
    state_out_20 <= state_out(2,0); state_out_21 <= state_out(2,1); state_out_22 <= state_out(2,2); state_out_23 <= state_out(2,3);
    state_out_30 <= state_out(3,0); state_out_31 <= state_out(3,1); state_out_32 <= state_out(3,2); state_out_33 <= state_out(3,3);

    -- Clock process
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Instantiate the Unit Under Test
    uut: entity work.add_round_key
        port map (
            clk => clk,
            reset => reset,
            enable => enable,
            state_in => state_in,
            round_keys => round_keys,
            cur_round => cur_round,
            done => done,
            state_out => state_out
        );

    -- Stimulus process
    stim_proc: process
    begin
        -- Wait 1 clk
        wait for clk_period;
        reset <= '0';
        enable <= '1';

        -- Initialize state_in with test pattern
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                state_in(r,c) <= x"AA"; -- Test byte pattern
            end loop;
        end loop;

        -- Initialize round keys
        for i in 0 to 43 loop
            round_keys(i) <= x"11223344"; -- 44 Words (4 * 11 Rounds)
        end loop;

        wait for 2 * clk_period;

        enable <= '0';

        wait for 3 * clk_period;
        -- Here you can check the results
        
        -- End simulation
        wait;
    end process;
end architecture;