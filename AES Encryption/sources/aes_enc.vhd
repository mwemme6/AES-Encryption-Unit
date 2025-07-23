library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity aes_enc is 
    port(
        clk: in std_logic;
        reset: in std_logic;
        enable: in std_logic;
        data_in: in std_logic_vector(127 downto 0);
        round_keys: in all_round_key_word;
        data_out: out std_logic_vector(127 downto 0);
        done: out std_logic

        -- Debug outputs
        -- debug_add_round_key_out : out aes_matrix;
        -- debug_sub_bytes_out     : out aes_matrix;
        -- debug_shift_rows_out    : out aes_matrix;
        -- debug_mix_column_out    : out aes_matrix;
        -- debug_add_round_key_in : out aes_matrix
    );
end entity;

architecture RTL of aes_enc is 
   
    -- Component Declarations
    component add_round_key
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
    end component;

    component sub_bytes
        port(
            clk: in std_logic;
            reset: in std_logic;
            enable: in std_logic;
            state_in: in aes_matrix;
            done: out std_logic;
            state_out: out aes_matrix  
        );
    end component;

    component shift_rows
        port(
            clk: in std_logic;
            reset: in std_logic;
            enable: in std_logic;
            state_in: in aes_matrix;
            done: out std_logic;
            state_out: out aes_matrix  
        );
    end component;

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

    --SIGNALS--
    --final state machine
    type states_type is (idle, add_round_key_state, sub_bytes_state, shift_rows_state, mix_column_state, done_state, data_in_state);
    signal current_state : states_type := idle;
    signal next_state : states_type := idle;
    signal input_reg : aes_matrix := (others => (others => (others => '0')));
    signal add_round_key_in : aes_matrix := (others => (others => (others => '0')));
    signal cur_round_internal : integer range 0 to 10 := 0;

    -- add_round_key
    signal add_round_key_enable: std_logic := '0';
    signal add_round_key_done: std_logic := '0';
    signal add_round_key_state_out: aes_matrix := (others => (others => (others => '0')));

    --sub_bytes
    signal sub_bytes_enable: std_logic := '0';
    signal sub_bytes_done: std_logic := '0';
    signal sub_bytes_state_out : aes_matrix := (others => (others => (others => '0')));

    --shift_rows
    signal shift_rows_enable: std_logic := '0';
    signal shift_rows_done: std_logic := '0';
    signal shift_rows_state_out : aes_matrix := (others => (others => (others => '0')));
    
    --mix_column
    signal mix_column_enable: std_logic := '0';
    signal mix_column_done: std_logic := '0';
    signal mix_column_state_out : aes_matrix := (others => (others => (others => '0')));
    
begin
    --debug
    -- debug_add_round_key_out <= add_round_key_state_out;
    -- debug_sub_bytes_out     <= sub_bytes_state_out;
    -- debug_shift_rows_out    <= shift_rows_state_out;
    -- debug_mix_column_out    <= mix_column_state_out;
    -- debug_add_round_key_in <= add_round_key_in;
    
    --Component Instantiation
    add_round_key_inst: add_round_key
    port map(
        clk => clk,
        reset => reset,
        enable => add_round_key_enable,
        state_in => add_round_key_in,
        round_keys => round_keys,
        cur_round => cur_round_internal,
        done => add_round_key_done,
        state_out => add_round_key_state_out
    );

    sub_bytes_inst: sub_bytes
    port map(
        clk => clk,
        reset => reset,
        enable => sub_bytes_enable,
        state_in => add_round_key_state_out,
        done => sub_bytes_done,
        state_out => sub_bytes_state_out
    );

    shift_rows_inst: shift_rows
    port map(
        clk => clk,
        reset => reset,
        enable => shift_rows_enable,
        state_in => sub_bytes_state_out,
        done => shift_rows_done,
        state_out => shift_rows_state_out
    );

    mix_column_inst: mix_column
    port map(
        clk => clk,
        reset => reset,
        enable => mix_column_enable,
        state_in => shift_rows_state_out,
        done => mix_column_done,
        state_out => mix_column_state_out
    );

    --state update 
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= idle;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    --next state logic
    process(current_state, enable, add_round_key_done, sub_bytes_done, shift_rows_done, mix_column_done, cur_round_internal)
    begin
        next_state <= current_state; 
        
        case current_state is
            when idle =>
                if enable = '1' then
                    next_state <= data_in_state;
                end if;
    
            when data_in_state => 
                next_state <= add_round_key_state;
    
            when add_round_key_state =>
                if add_round_key_done = '1' then
                    if cur_round_internal = 10 then
                        next_state <= done_state;
                    else
                        next_state <= sub_bytes_state;
                    end if;
                end if;
    
            when sub_bytes_state => 
                if sub_bytes_done = '1' then
                    next_state <= shift_rows_state;
                end if;
            
            when shift_rows_state =>
                if shift_rows_done = '1' then
                    if cur_round_internal <= 9 then
                        next_state <= mix_column_state;
                    else
                        next_state <= add_round_key_state;
                    end if;
                end if;
    
            when mix_column_state =>
                if mix_column_done = '1' then
                    next_state <= add_round_key_state;
                end if;
    
            when done_state => 
                next_state <= idle;
    
            when others =>
                next_state <= idle;
        end case;
    end process;

    --data_in
    process(clk)
    begin
        if rising_edge(clk) then
            if current_state = data_in_state then
                input_reg(0, 0) <= data_in(127 downto 120);
                input_reg(1, 0) <= data_in(119 downto 112);
                input_reg(2, 0) <= data_in(111 downto 104);
                input_reg(3, 0) <= data_in(103 downto 96);
                input_reg(0, 1) <= data_in(95 downto 88);
                input_reg(1, 1) <= data_in(87 downto 80);
                input_reg(2, 1) <= data_in(79 downto 72);
                input_reg(3, 1) <= data_in(71 downto 64);
                input_reg(0, 2) <= data_in(63 downto 56);
                input_reg(1, 2) <= data_in(55 downto 48);
                input_reg(2, 2) <= data_in(47 downto 40);
                input_reg(3, 2) <= data_in(39 downto 32);
                input_reg(0, 3) <= data_in(31 downto 24);
                input_reg(1, 3) <= data_in(23 downto 16);
                input_reg(2, 3) <= data_in(15 downto 8);
                input_reg(3, 3) <= data_in(7 downto 0);
            end if;
        end if;
    end process;

    --add_round_key_in
    process(clk)
    begin
        if rising_edge(clk) then
            case next_state is
                when add_round_key_state => 
                    if cur_round_internal = 0 then
                        add_round_key_in <= input_reg;
                    elsif cur_round_internal = 10 then
                        add_round_key_in <= shift_rows_state_out;
                    else
                        add_round_key_in <= mix_column_state_out;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    --enable logic
    process(current_state)
    begin
        add_round_key_enable <= '0';
        sub_bytes_enable <= '0';
        shift_rows_enable <= '0';
        mix_column_enable <= '0';
        done <= '0';

        case current_state is 
            when add_round_key_state =>
                add_round_key_enable <= '1';

            when sub_bytes_state =>
                sub_bytes_enable <= '1';
        
            when shift_rows_state =>
                shift_rows_enable <= '1';
        
            when mix_column_state =>
                mix_column_enable <= '1';
            
            when done_state =>
                done <= '1';
            
            when others =>
                null;

        end case;
    end process;


    --round count
    process(clk, reset)
    begin
        if reset = '1' then
            cur_round_internal <= 0;

        elsif rising_edge(clk) then
            if current_state = add_round_key_state and add_round_key_done = '1' then
                if cur_round_internal < 10 then
                    cur_round_internal <= cur_round_internal + 1;
                end if;

            elsif current_state = done_state then
                cur_round_internal <= 0;
            end if;
        end if;
    end process;
    
    --output assignment
    process(current_state)
    begin
        if current_state = done_state then
            data_out(127 downto 120) <= add_round_key_state_out(0, 0); 
            data_out(119 downto 112) <= add_round_key_state_out(1, 0); 
            data_out(111 downto 104) <= add_round_key_state_out(2, 0);
            data_out(103 downto 96) <= add_round_key_state_out(3, 0);
            data_out(95 downto 88) <= add_round_key_state_out(0, 1);
            data_out(87 downto 80) <= add_round_key_state_out(1, 1);
            data_out(79 downto 72) <= add_round_key_state_out(2, 1);
            data_out(71 downto 64) <= add_round_key_state_out(3, 1);
            data_out(63 downto 56) <= add_round_key_state_out(0, 2);
            data_out(55 downto 48) <= add_round_key_state_out(1, 2);
            data_out(47 downto 40) <= add_round_key_state_out(2, 2);
            data_out(39 downto 32) <= add_round_key_state_out(3, 2);
            data_out(31 downto 24) <= add_round_key_state_out(0, 3);
            data_out(23 downto 16) <= add_round_key_state_out(1, 3);
            data_out(15 downto 8) <= add_round_key_state_out(2, 3);
            data_out(7 downto 0) <= add_round_key_state_out(3, 3);
        else
            data_out <= (others => '0');
        end if;
    end process;

end RTL;