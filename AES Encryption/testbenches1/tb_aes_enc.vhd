library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity tb_aes_enc is
end tb_aes_enc;

architecture behavior of tb_aes_enc is

    -- Component Declaration for the Unit Under Test (UUT)
    component aes_enc
    port(
        clk : in std_logic;
        reset : in std_logic;
        enable : in std_logic;
        data_in : in std_logic_vector(127 downto 0);
        round_keys : in all_round_key_word;
        data_out : out std_logic_vector(127 downto 0);
        done : out std_logic;

        -- Debug outputs
        debug_add_round_key_out : out aes_matrix;
        debug_sub_bytes_out     : out aes_matrix;
        debug_shift_rows_out    : out aes_matrix;
        debug_mix_column_out    : out aes_matrix;
        debug_add_round_key_in : out aes_matrix
    );
    end component;

    component key_expansion
        port(
            clk        : in  std_logic;
            reset      : in  std_logic;
            enable     : in  std_logic;
            key_in     : in  std_logic_vector(127 downto 0);
            done       : out std_logic;
            keys_out   : out all_round_key_word
        );
    end component;

    -- Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal enable : std_logic := '0';
    signal data_in : std_logic_vector(127 downto 0) := (others => '0');
    

    -- Outputs
    signal data_out : std_logic_vector(127 downto 0);
    signal keys : all_round_key_word := (others => (others => '0'));
    signal keys_done : std_logic := '0';
    signal keys_en : std_logic := '0';
    signal key : std_logic_vector(127 downto 0) := (others => '0');
    signal done : std_logic := '0';

    --Debug      
    -- Internal AES component outputs for debugging
    signal dbg_add_out   : aes_matrix;
    signal dbg_sub_out   : aes_matrix;
    signal dbg_shift_out : aes_matrix;
    signal dbg_mix_out   : aes_matrix;
    signal dbg_add_in    : aes_matrix;

    signal round_key_0 : std_logic_vector(127 downto 0);
    signal round_key_1 : std_logic_vector(127 downto 0);
    signal round_key_2 : std_logic_vector(127 downto 0);
    signal round_key_3 : std_logic_vector(127 downto 0);
    signal round_key_4 : std_logic_vector(127 downto 0);
    signal round_key_5 : std_logic_vector(127 downto 0);
    signal round_key_6 : std_logic_vector(127 downto 0);
    signal round_key_7 : std_logic_vector(127 downto 0);
    signal round_key_8 : std_logic_vector(127 downto 0);
    signal round_key_9 : std_logic_vector(127 downto 0);
    signal round_key_10 : std_logic_vector(127 downto 0);


    -- Clock period definitions
    constant clk_period : time := 10 ns;

    -- add_round_key output
    signal add_byte_00, add_byte_01, add_byte_02, add_byte_03 : std_logic_vector(7 downto 0);
    signal add_byte_10, add_byte_11, add_byte_12, add_byte_13 : std_logic_vector(7 downto 0);
    signal add_byte_20, add_byte_21, add_byte_22, add_byte_23 : std_logic_vector(7 downto 0);
    signal add_byte_30, add_byte_31, add_byte_32, add_byte_33 : std_logic_vector(7 downto 0);

    -- sub_bytes output
    signal sub_byte_00, sub_byte_01, sub_byte_02, sub_byte_03 : std_logic_vector(7 downto 0);
    signal sub_byte_10, sub_byte_11, sub_byte_12, sub_byte_13 : std_logic_vector(7 downto 0);
    signal sub_byte_20, sub_byte_21, sub_byte_22, sub_byte_23 : std_logic_vector(7 downto 0);
    signal sub_byte_30, sub_byte_31, sub_byte_32, sub_byte_33 : std_logic_vector(7 downto 0);

    -- shift_rows output
    signal shift_byte_00, shift_byte_01, shift_byte_02, shift_byte_03 : std_logic_vector(7 downto 0);
    signal shift_byte_10, shift_byte_11, shift_byte_12, shift_byte_13 : std_logic_vector(7 downto 0);
    signal shift_byte_20, shift_byte_21, shift_byte_22, shift_byte_23 : std_logic_vector(7 downto 0);
    signal shift_byte_30, shift_byte_31, shift_byte_32, shift_byte_33 : std_logic_vector(7 downto 0);

    -- mix_column output
    signal mix_byte_00, mix_byte_01, mix_byte_02, mix_byte_03 : std_logic_vector(7 downto 0);
    signal mix_byte_10, mix_byte_11, mix_byte_12, mix_byte_13 : std_logic_vector(7 downto 0);
    signal mix_byte_20, mix_byte_21, mix_byte_22, mix_byte_23 : std_logic_vector(7 downto 0);
    signal mix_byte_30, mix_byte_31, mix_byte_32, mix_byte_33 : std_logic_vector(7 downto 0);

    -- Debug input signals
    -- add_round_key input
    signal add_in_byte_00, add_in_byte_01, add_in_byte_02, add_in_byte_03 : std_logic_vector(7 downto 0);
    signal add_in_byte_10, add_in_byte_11, add_in_byte_12, add_in_byte_13 : std_logic_vector(7 downto 0);
    signal add_in_byte_20, add_in_byte_21, add_in_byte_22, add_in_byte_23 : std_logic_vector(7 downto 0);
    signal add_in_byte_30, add_in_byte_31, add_in_byte_32, add_in_byte_33 : std_logic_vector(7 downto 0);

begin

    round_key_0 <= keys(0) & keys(1) & keys(2) & keys(3);
    round_key_1 <= keys(4) & keys(5) & keys(6) & keys(7);
    round_key_2 <= keys(8) & keys(9) & keys(10) & keys(11);
    round_key_3 <= keys(12) & keys(13) & keys(14) & keys(15);
    round_key_4 <= keys(16) & keys(17) & keys(18) & keys(19);
    round_key_5 <= keys(20) & keys(21) & keys(22) & keys(23);
    round_key_6 <= keys(24) & keys(25) & keys(26) & keys(27);
    round_key_7 <= keys(28) & keys(29) & keys(30) & keys(31);
    round_key_8 <= keys(32) & keys(33) & keys(34) & keys(35);
    round_key_9 <= keys(36) & keys(37) & keys(38) & keys(39);
    round_key_10 <= keys(40) & keys(41) & keys(42) & keys(43);

     -- AddRoundKey
     add_byte_00 <= dbg_add_out(0,0); add_byte_01 <= dbg_add_out(0,1); add_byte_02 <= dbg_add_out(0,2); add_byte_03 <= dbg_add_out(0,3);
     add_byte_10 <= dbg_add_out(1,0); add_byte_11 <= dbg_add_out(1,1); add_byte_12 <= dbg_add_out(1,2); add_byte_13 <= dbg_add_out(1,3);
     add_byte_20 <= dbg_add_out(2,0); add_byte_21 <= dbg_add_out(2,1); add_byte_22 <= dbg_add_out(2,2); add_byte_23 <= dbg_add_out(2,3);
     add_byte_30 <= dbg_add_out(3,0); add_byte_31 <= dbg_add_out(3,1); add_byte_32 <= dbg_add_out(3,2); add_byte_33 <= dbg_add_out(3,3);
 
     -- SubBytes
     sub_byte_00 <= dbg_sub_out(0,0); sub_byte_01 <= dbg_sub_out(0,1); sub_byte_02 <= dbg_sub_out(0,2); sub_byte_03 <= dbg_sub_out(0,3);
     sub_byte_10 <= dbg_sub_out(1,0); sub_byte_11 <= dbg_sub_out(1,1); sub_byte_12 <= dbg_sub_out(1,2); sub_byte_13 <= dbg_sub_out(1,3);
     sub_byte_20 <= dbg_sub_out(2,0); sub_byte_21 <= dbg_sub_out(2,1); sub_byte_22 <= dbg_sub_out(2,2); sub_byte_23 <= dbg_sub_out(2,3);
     sub_byte_30 <= dbg_sub_out(3,0); sub_byte_31 <= dbg_sub_out(3,1); sub_byte_32 <= dbg_sub_out(3,2); sub_byte_33 <= dbg_sub_out(3,3);
 
     -- ShiftRows
     shift_byte_00 <= dbg_shift_out(0,0); shift_byte_01 <= dbg_shift_out(0,1); shift_byte_02 <= dbg_shift_out(0,2); shift_byte_03 <= dbg_shift_out(0,3);
     shift_byte_10 <= dbg_shift_out(1,0); shift_byte_11 <= dbg_shift_out(1,1); shift_byte_12 <= dbg_shift_out(1,2); shift_byte_13 <= dbg_shift_out(1,3);
     shift_byte_20 <= dbg_shift_out(2,0); shift_byte_21 <= dbg_shift_out(2,1); shift_byte_22 <= dbg_shift_out(2,2); shift_byte_23 <= dbg_shift_out(2,3);
     shift_byte_30 <= dbg_shift_out(3,0); shift_byte_31 <= dbg_shift_out(3,1); shift_byte_32 <= dbg_shift_out(3,2); shift_byte_33 <= dbg_shift_out(3,3);
 
     -- MixColumns
     mix_byte_00 <= dbg_mix_out(0,0); mix_byte_01 <= dbg_mix_out(0,1); mix_byte_02 <= dbg_mix_out(0,2); mix_byte_03 <= dbg_mix_out(0,3);
     mix_byte_10 <= dbg_mix_out(1,0); mix_byte_11 <= dbg_mix_out(1,1); mix_byte_12 <= dbg_mix_out(1,2); mix_byte_13 <= dbg_mix_out(1,3);
     mix_byte_20 <= dbg_mix_out(2,0); mix_byte_21 <= dbg_mix_out(2,1); mix_byte_22 <= dbg_mix_out(2,2); mix_byte_23 <= dbg_mix_out(2,3);
     mix_byte_30 <= dbg_mix_out(3,0); mix_byte_31 <= dbg_mix_out(3,1); mix_byte_32 <= dbg_mix_out(3,2); mix_byte_33 <= dbg_mix_out(3,3);

     -- Debug input signals
     -- AddRoundKey input
     add_in_byte_00 <= dbg_add_in(0,0); add_in_byte_01 <= dbg_add_in(0,1); add_in_byte_02 <= dbg_add_in(0,2); add_in_byte_03 <= dbg_add_in(0,3);
     add_in_byte_10 <= dbg_add_in(1,0); add_in_byte_11 <= dbg_add_in(1,1); add_in_byte_12 <= dbg_add_in(1,2); add_in_byte_13 <= dbg_add_in(1,3);
     add_in_byte_20 <= dbg_add_in(2,0); add_in_byte_21 <= dbg_add_in(2,1); add_in_byte_22 <= dbg_add_in(2,2); add_in_byte_23 <= dbg_add_in(2,3);
     add_in_byte_30 <= dbg_add_in(3,0); add_in_byte_31 <= dbg_add_in(3,1); add_in_byte_32 <= dbg_add_in(3,2); add_in_byte_33 <= dbg_add_in(3,3);

    -- Instantiate the Unit Under Test (UUT)
    uut: aes_enc port map (
        clk => clk,
        reset => reset,
        enable => enable,
        data_in => data_in,
        round_keys => keys,
        data_out => data_out,
        done => done,
        -- Debug outputs
        debug_add_round_key_out => dbg_add_out,
        debug_sub_bytes_out     => dbg_sub_out,
        debug_shift_rows_out    => dbg_shift_out,
        debug_mix_column_out    => dbg_mix_out,
        -- Debug inputs
        debug_add_round_key_in => dbg_add_in
    );

    keys_inst: key_expansion
        port map(
            clk        => clk,
            reset      => reset,
            enable     => keys_en,
            key_in     => key,
            done       => keys_done,
            keys_out   => keys
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
        -- Initial reset
        reset <= '1';
        wait for 10 * clk_period; 
        reset <= '0';
        
        -- Key expansion
        key <= x"2b7e151628aed2a6abf7158809cf4f3c";
        keys_en <= '1'; 
        wait until keys_done = '1';
        keys_en <= '0';
        wait for 10 * clk_period;
        
        -- Start encryption
        data_in <= x"48656C6C6F20576F726C642020202020";
        enable <= '1';
        wait until data_out /= x"00000000000000000000000000000000"; -- Wait for output
        enable <= '0';
        
        -- Check result
        assert data_out = x"078928f2d60c884ad66e9d79ba5d9b2e"
            report "Encryption failed!" severity error;
        
        wait; 
    end process;

end behavior;