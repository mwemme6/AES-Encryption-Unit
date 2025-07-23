library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity aes_enc_top is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        enable      : in  STD_LOGIC;
        key         : in  STD_LOGIC_VECTOR(127 downto 0);
        plaintext   : in  STD_LOGIC_VECTOR(127 downto 0);
        ciphertext  : out STD_LOGIC_VECTOR(127 downto 0);
        done        : out STD_LOGIC
    );
end aes_enc_top;

architecture RTL of aes_enc_top is

    type state_type is (IDLE_S, KEY_EXPANSION_S, AES_ENC_S, DONE_S);
    signal state, next_state : state_type := IDLE_S;

    component aes_enc
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            enable     : in  std_logic;
            data_in    : in  std_logic_vector(127 downto 0);
            round_keys : in  all_round_key_word;
            data_out   : out std_logic_vector(127 downto 0);
            done       : out std_logic
        );
    end component;

    component key_expansion
        port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            enable   : in  std_logic;
            key_in   : in  std_logic_vector(127 downto 0);
            done     : out std_logic;
            keys_out : out all_round_key_word
        );
    end component;

    -- Signals
    signal done_key_expansion     : std_logic := '0';
    signal done_aes_enc           : std_logic := '0';
    signal round_keys             : all_round_key_word := (others => (others => '0'));
    signal enable_key_expansion   : std_logic := '0';
    signal enable_aes_enc         : std_logic := '0';

begin

    -- Key Expansion Instance
    key_expansion_inst: key_expansion
        port map (
            clk      => clk,
            reset    => reset,
            enable   => enable_key_expansion,
            key_in   => key,
            done     => done_key_expansion,
            keys_out => round_keys
        );

    -- AES Encryption Instance
    aes_enc_inst: aes_enc
        port map (
            clk        => clk,
            reset      => reset,
            enable     => enable_aes_enc,
            data_in    => plaintext,
            round_keys => round_keys,
            data_out   => ciphertext,
            done       => done
        );

    -- FSM: Next State Logic
    process(state, enable, done_key_expansion, done_aes_enc)
    begin
        case state is
            when IDLE_S =>
                if enable = '1' then
                    next_state <= KEY_EXPANSION_S;
                else
                    next_state <= IDLE_S;
                end if;
            when KEY_EXPANSION_S =>
                if done_key_expansion = '1' then
                    next_state <= AES_ENC_S;
                else
                    next_state <= KEY_EXPANSION_S;
                end if;
            when AES_ENC_S =>
                if done_aes_enc = '1' then
                    next_state <= DONE_S;
                else
                    next_state <= AES_ENC_S;
                end if;
            when DONE_S =>
                next_state <= DONE_S;
            when others =>
                next_state <= IDLE_S;
        end case;
    end process;

    -- FSM: State Register
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE_S;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Output Logic
    process(state)
    begin
        -- Default outputs
        enable_key_expansion <= '0';
        enable_aes_enc       <= '0';
        -- done                 <= '0';

        case state is
            when KEY_EXPANSION_S =>
                enable_key_expansion <= '1';
            when AES_ENC_S =>
                enable_aes_enc <= '1';
            -- when DONE_S =>
            --     done <= '1';
            when others =>
                null;
        end case;
    end process;

end RTL;