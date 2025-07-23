library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity tb_aes_enc_top is
end tb_aes_enc_top;

architecture tb of tb_aes_enc_top is

    -- Komponentendeklaration
    component aes_enc_top is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            enable      : in  STD_LOGIC;
            key         : in  STD_LOGIC_VECTOR(127 downto 0);
            plaintext   : in  STD_LOGIC_VECTOR(127 downto 0);
            ciphertext  : out STD_LOGIC_VECTOR(127 downto 0);
            done        : out STD_LOGIC
        );
    end component;

    -- Signale für die Verbindung
    signal clk_tb        : STD_LOGIC := '0';
    signal reset_tb      : STD_LOGIC := '1';
    signal enable_tb     : STD_LOGIC := '0';
    signal key_tb        : STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
    signal plaintext_tb  : STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
    signal ciphertext_tb : STD_LOGIC_VECTOR(127 downto 0);
    signal done_tb       : STD_LOGIC;

    -- Clockperiode
    constant CLK_PERIOD : time := 10 ns;

begin

    -- DUT (Device Under Test)
    uut: aes_enc_top
        port map (
            clk        => clk_tb,
            reset      => reset_tb,
            enable     => enable_tb,
            key        => key_tb,
            plaintext  => plaintext_tb,
            ciphertext => ciphertext_tb,
            done       => done_tb
        );

    -- Clock-Generator
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimuli-Prozess
    stim_proc : process
    begin
        -- Initialer Reset
        wait for 20 ns;
        reset_tb <= '0';

        -- Eingaben vorbereiten
        key_tb       <= x"2b7e151628aed2a6abf7158809cf4f3c"; -- Beispiel AES-Key
        plaintext_tb <= x"48656C6C6F20576F726C642020202020"; -- Beispiel Klartext

        -- Modul aktivieren
        enable_tb <= '1';
        wait for CLK_PERIOD;
        enable_tb <= '0';

        -- Auf "done" warten
        wait until done_tb = '1';
        
        -- Ergebnisse anzeigen
        report "AES Encryption done.";
        assert ciphertext_tb = x"078928f2d60c884ad66e9d79ba5d9b2e" report "Ciphertext mismatch!" severity error;
        report "Ciphertext = " & to_hstring(ciphertext_tb);
        
        wait for CLK_PERIOD;
        wait; -- Test beendet
    end process;

end tb;
