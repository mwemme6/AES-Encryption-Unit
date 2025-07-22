library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity tb_mix_column is
end tb_mix_column;

architecture Behavioral of tb_mix_column is

    -- Component Declaration for the Unit Under Test (UUT)
    component mix_column
        port(
            clk: in std_logic;
            reset: in std_logic;
            enable: in std_logic;
            state_in: in aes_matrix;
            done: out std_logic;
            state_out: out aes_matrix  
        );
    end component;

    -- Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal enable : std_logic := '0';
    signal state_in : aes_matrix := (others => (others => (others => '0')));

    -- Outputs
    signal done : std_logic;
    signal state_out : aes_matrix;

    -- Individual output byte signals for monitoring
    signal out_00, out_01, out_02, out_03 : std_logic_vector(7 downto 0);
    signal out_10, out_11, out_12, out_13 : std_logic_vector(7 downto 0);
    signal out_20, out_21, out_22, out_23 : std_logic_vector(7 downto 0);
    signal out_30, out_31, out_32, out_33 : std_logic_vector(7 downto 0);

    -- Clock period definitions
    constant clk_period : time := 10 ns;

begin

    -- Connect individual output signals
    out_00 <= state_out(0, 0);
    out_01 <= state_out(0, 1);
    out_02 <= state_out(0, 2);
    out_03 <= state_out(0, 3);
    out_10 <= state_out(1, 0);
    out_11 <= state_out(1, 1);
    out_12 <= state_out(1, 2);
    out_13 <= state_out(1, 3);
    out_20 <= state_out(2, 0);
    out_21 <= state_out(2, 1);
    out_22 <= state_out(2, 2);
    out_23 <= state_out(2, 3);
    out_30 <= state_out(3, 0);
    out_31 <= state_out(3, 1);
    out_32 <= state_out(3, 2);
    out_33 <= state_out(3, 3);

    -- Instantiate the Unit Under Test (UUT)
    uut: mix_column port map (
        clk => clk,
        reset => reset,
        enable => enable,
        state_in => state_in,
        done => done,
        state_out => state_out
    );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state for 2 clock cycles
        report "Applying reset...";
        reset <= '1';
        wait for clk_period*2;
        reset <= '0';
        wait for clk_period;
        
        -- Test Case 1: AES standard test vector
        report "Starting Test Case 1: AES standard test vector";
        state_in <= (
            (x"63", x"63", x"63", x"63"),
            (x"7C", x"7C", x"7C", x"7C"),
            (x"77", x"77", x"77", x"77"),
            (x"7B", x"7B", x"7B", x"7B")
        );
        enable <= '1';
        wait until done = '1';
        enable <= '0';
        report "Test Case 1 Output:";
        wait for clk_period*2;
        
        -- Test Case 2: All zeros input
        report "Starting Test Case 2: All zeros input";
        state_in <= (
            (x"00", x"00", x"00", x"00"),
            (x"00", x"00", x"00", x"00"),
            (x"00", x"00", x"00", x"00"),
            (x"00", x"00", x"00", x"00")
        );
        enable <= '1';
        wait until done = '1';
        enable <= '0';
        report "Test Case 2 Output:";
        wait for clk_period*2;
        
        -- Test Case 3: All ones input (FF)
        report "Starting Test Case 3: All FF input";
        state_in <= (
            (x"FF", x"FF", x"FF", x"FF"),
            (x"FF", x"FF", x"FF", x"FF"),
            (x"FF", x"FF", x"FF", x"FF"),
            (x"FF", x"FF", x"FF", x"FF")
        );
        enable <= '1';
        wait until done = '1';
        enable <= '0';
        wait for clk_period*2;
        
        -- Test Case 4: Random values with unique bytes
        report "Starting Test Case 4: Random unique values";
        state_in <= (
            (x"01", x"02", x"03", x"04"),
            (x"05", x"06", x"07", x"08"),
            (x"09", x"0A", x"0B", x"0C"),
            (x"0D", x"0E", x"0F", x"10")
        );
        enable <= '1';
        wait until done = '1';
        enable <= '0';
        report "Test Case 4 Output:";
        wait for clk_period*2;
        
        -- Test reset during operation
        report "Testing reset during operation";
        state_in <= (
            (x"AA", x"BB", x"CC", x"DD"),
            (x"EE", x"FF", x"00", x"11"),
            (x"22", x"33", x"44", x"55"),
            (x"66", x"77", x"88", x"99")
        );
        enable <= '1';
        wait for clk_period/2;
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        enable <= '0';
        wait for clk_period*2;
        
        -- End simulation
        report "Simulation completed";
        wait;
    end process;

end Behavioral;