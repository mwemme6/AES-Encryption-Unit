library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;  -- Enthält all_round_key_word, round_key_word usw.

entity tb_key_expansion is
end tb_key_expansion;

architecture sim of tb_key_expansion is

    -- DUT Signale
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal enable   : std_logic := '0';
    signal key_in   : std_logic_vector(127 downto 0) := (others => '0');
    signal done     : std_logic;
    signal keys_out : all_round_key_word;

    -- Sichtbare Round Keys (128 Bit = 4x 32 Bit)
    signal roundkey_0  : std_logic_vector(127 downto 0);
    signal roundkey_1  : std_logic_vector(127 downto 0);
    signal roundkey_2  : std_logic_vector(127 downto 0);
    signal roundkey_3  : std_logic_vector(127 downto 0);
    signal roundkey_4  : std_logic_vector(127 downto 0);
    signal roundkey_5  : std_logic_vector(127 downto 0);
    signal roundkey_6  : std_logic_vector(127 downto 0);
    signal roundkey_7  : std_logic_vector(127 downto 0);
    signal roundkey_8  : std_logic_vector(127 downto 0);
    signal roundkey_9  : std_logic_vector(127 downto 0);
    signal roundkey_10 : std_logic_vector(127 downto 0);

    type expected_keys_type is array (0 to 10) of std_logic_vector(127 downto 0);
    signal rk : std_logic_vector(127 downto 0);
    constant clk_period : time := 10 ns;

begin

    -- DUT Instanz
    uut: entity work.key_expansion
        port map (
            clk      => clk,
            reset    => reset,
            enable   => enable,
            key_in   => key_in,
            done     => done,
            keys_out => keys_out
        );

    -- Taktprozess
    clk_process : process
    begin
        while now < 5000 ns loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Round Keys zusammenbauen aus keys_out
    roundkey_0  <= keys_out(0)  & keys_out(1)  & keys_out(2)  & keys_out(3);
    roundkey_1  <= keys_out(4)  & keys_out(5)  & keys_out(6)  & keys_out(7);
    roundkey_2  <= keys_out(8)  & keys_out(9)  & keys_out(10) & keys_out(11);
    roundkey_3  <= keys_out(12) & keys_out(13) & keys_out(14) & keys_out(15);
    roundkey_4  <= keys_out(16) & keys_out(17) & keys_out(18) & keys_out(19);
    roundkey_5  <= keys_out(20) & keys_out(21) & keys_out(22) & keys_out(23);
    roundkey_6  <= keys_out(24) & keys_out(25) & keys_out(26) & keys_out(27);
    roundkey_7  <= keys_out(28) & keys_out(29) & keys_out(30) & keys_out(31);
    roundkey_8  <= keys_out(32) & keys_out(33) & keys_out(34) & keys_out(35);
    roundkey_9  <= keys_out(36) & keys_out(37) & keys_out(38) & keys_out(39);
    roundkey_10 <= keys_out(40) & keys_out(41) & keys_out(42) & keys_out(43);

    -- Stimulusprozess
    stim_proc: process
        -- Erwartete Round Keys für den Testschlüssel

        constant expected_keys : expected_keys_type := (
            x"2b7e151628aed2a6abf7158809cf4f3c", -- Round 0
            x"a0fafe1788542cb123a339392a6c7605", -- Round 1
            x"f2c295f27a96b9435935807a7359f67f", -- Round 2
            x"3d80477d4716fe3e1e237e446d7a883b", -- Round 3
            x"ef44a541a8525b7fb671253bdb0bad00", -- Round 4
            x"d4d1c6f87c839d87caf2b8bc11f915bc", -- Round 5
            x"6d88a37a110b3efddbf98641ca0093fd", -- Round 6
            x"4e54f70e5f5fc9f384a64fb24ea6dc4f", -- Round 7
            x"ead27321b58dbad2312bf5607f8d292f", -- Round 8
            x"ac7766f319fadc2128d12941575c006e", -- Round 9
            x"d014f9a8c9ee2589e13f0cc8b6630ca6"  -- Round 10
        );
    begin
        -- Reset
        reset <= '1';
        wait for 2 * clk_period;
        reset <= '0';

        -- Beispielschlüssel (AES 128 Standard Test Key)
        key_in <= expected_keys(0);
        enable <= '1';

        -- Warten bis done = '1'
        wait until done = '1';
        enable <= '0';

        -- Automatische Überprüfung aller Round Keys
        for i in 0 to 10 loop
            case i is
                when 0 => rk <= roundkey_0;
                when 1 => rk <= roundkey_1;
                when 2 => rk <= roundkey_2;
                when 3 => rk <= roundkey_3;
                when 4 => rk <= roundkey_4;
                when 5 => rk <= roundkey_5;
                when 6 => rk <= roundkey_6;
                when 7 => rk <= roundkey_7;
                when 8 => rk <= roundkey_8;
                when 9 => rk <= roundkey_9;
                when 10 => rk <= roundkey_10;
            end case;
            
            wait for 1 ns; -- Warten auf Signalstabilisierung
            
            assert rk = expected_keys(i)
                report "Round Key " & integer'image(i) & " falsch!" severity error;
            
        end loop;

        report "Test abgeschlossen";
        wait;
    end process;

end sim;
