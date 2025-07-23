library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity aes_top_uart is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        uart_rx_e   : in STD_LOGIC;
        uart_tx_e   : out STD_LOGIC;
        done        : out STD_LOGIC
    );
end aes_top_uart;

architecture RTL of aes_top_uart is

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

    -------------------
    -- SCI Receiver 
    -------------------
    component uart_rx is 
    generic(
        BAUD_PERIOD : integer);
    port(
        receive_en : in std_logic;
        reset : in std_logic; 
        clk : in std_logic; 
        rx : in std_logic; 
        sci_ready : out std_logic; 
        sci_output : out std_logic_vector(7 downto 0));
    end component;

    -------------------
    -- SCI Transmitter
    -------------------
    component uart_tx is 
    generic (
        BAUD_PERIOD : integer);
    port ( 
        data_in : in std_logic_vector(7 downto 0);
        transmit_en : in std_logic; 
        reset : in std_logic; 
        clk : in std_logic;
        tx: out std_logic;
        new_symbol: out std_logic);
    end component;

    -- Cipher signals
    signal key : std_logic_vector(127 downto 0) := (others => '0');
    signal key_ready, key_en : std_logic := '0';
    signal cipher_data_in : std_logic_vector(127 downto 0) := (others => '0');
    signal cipher_data_out : std_logic_vector(127 downto 0) := (others => '0');
    signal cipher_en, cipher_ready : std_logic := '0';
    signal cipher_words_in, key_words_out : all_round_key_word := (others => (others => '0')); 

    --SCI signals
    signal sci_rx_data_out, sci_tx_data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal sci_tx_data_buf : std_logic_vector(127 downto 0) := (others => '0'); 
    signal sci_rx_ready : std_logic := '0';
    signal transmit_en : std_logic := '0';
    signal sci_tx_new_byte : std_logic := '0'; 
    -- constant SCI_RX_BAUD_PERIOD : integer := 10416;      --for synthesis
    -- constant SCI_TX_BAUD_PERIOD : integer := 10416;      --for synthesis
    constant SCI_RX_BAUD_PERIOD : integer := 10;       --for simulation
    constant SCI_TX_BAUD_PERIOD : integer := 10;       --for simulation

    --
    signal input_buffer : std_logic_vector(127 downto 0) := (others => '0');

    type receive_state_t is (RECEIVE_KEY, UPDATE_KEY, RECEIVE_DATA, UPDATE_CIPHER_DATA);
    signal receive_cs, receive_ns : receive_state_t := RECEIVE_KEY;
    signal rx_byte_count : natural range 0 to 15 := 0;
    signal rx_byte_tc, key_reg_update_en : std_logic := '0'; 

    type transmit_state_t is (IDLE, TRANSMIT);
    signal transmit_cs, transmit_ns : transmit_state_t := IDLE;
    signal tx_byte_count : natural range 0 to 15 := 0;
    signal tx_byte_tc : std_logic := '0'; 
    signal sci_tx_out : std_logic := '1';

begin

    -- Key Expansion Instance
    key_expansion_inst: key_expansion
        port map (
            clk      => clk,
            reset    => reset,
            enable   => key_en,
            key_in   => key,
            done     => key_ready,
            keys_out => key_words_out
        );

    -- AES Encryption Instance
    aes_enc_inst: aes_enc
        port map (
            clk        => clk,
            reset      => reset,
            enable     => cipher_en,
            data_in    => cipher_data_in,
            round_keys => cipher_words_in,
            data_out   => cipher_data_out,
            done       => cipher_ready
        );

    uart_rx_inst: uart_rx
        generic map ( 
            BAUD_PERIOD => SCI_TX_BAUD_PERIOD)
        port map ( 
            clk => clk,
            receive_en => '1', 
            reset => reset, 
            rx => uart_rx_e, 
            sci_ready => sci_rx_ready, 
            sci_output => sci_rx_data_out 
        );


    uart_tx_inst: uart_tx
    generic map (
        BAUD_PERIOD => SCI_TX_BAUD_PERIOD)
	port map (	
		clk => clk,
		data_in => sci_tx_data_in, 
		transmit_en => transmit_en, 
		reset => reset, 
		tx => sci_tx_out,
		new_symbol => sci_tx_new_byte
	);

    state_update: process(clk, reset)
    begin
        if reset = '1' then 
            receive_cs <= RECEIVE_KEY; 
            transmit_cs <= IDLE;  
        elsif rising_edge(clk) then
            receive_cs <= receive_ns; 
            transmit_cs <= transmit_ns;  
        end if; 
    end process;
    
    transmit_ns_logic : process (transmit_cs, cipher_ready, tx_byte_tc)
    begin
        transmit_ns <= transmit_cs; 
        case transmit_cs is
            when IDLE =>
                if cipher_ready = '1' then
                    transmit_ns <= TRANSMIT; 
                end if;
            when TRANSMIT => 
                if tx_byte_tc = '1' then
                    transmit_ns <= IDLE;  
                end if; 
        end case;
    end process;
    
    transmit_output_logic : process(transmit_cs, sci_tx_new_byte, tx_byte_count)
    begin
        transmit_en <= '0'; 
        case transmit_cs is 
            when TRANSMIT =>  
                transmit_en <= '1';
            when others => null;  
        end case; 
    end process;
    
    tx_byte_counter: process(clk, tx_byte_count, reset)
    begin
        if reset = '1' then 
            tx_byte_count <= 0; 
        elsif rising_edge(clk) then 
            tx_byte_tc <= '0'; 
            if sci_tx_new_byte = '1' then 
                if tx_byte_count = 15 then 
                    tx_byte_tc <= '1'; 
                    tx_byte_count <= 0;
                else
                    tx_byte_count <= tx_byte_count + 1; 
                end if;     
            end if;
        end if; 
    end process; 
    
    tx_data_in_reg : process(clk)
    begin
        if rising_edge(clk) then
             if transmit_en = '0' and cipher_ready = '1' then 
                sci_tx_data_buf <= cipher_data_out;  
             end if; 
        end if; 
    end process; 
     
    sci_tx_data_in <= sci_tx_data_buf(127 - 8 * tx_byte_count downto 120 - 8 * tx_byte_count);
    key <= input_buffer; 
    cipher_data_in <= input_buffer;
    
    receiver_ns_logic: process(receive_cs, rx_byte_tc, key_ready)
    begin
        receive_ns <= receive_cs; 
        case receive_cs is 
            when RECEIVE_KEY => 
                if rx_byte_tc = '1' then
                    receive_ns <= UPDATE_KEY; 
                end if; 
            when UPDATE_KEY => 
                if rx_byte_tc = '0' then 
                    receive_ns <= RECEIVE_DATA;
                end if; 
            when RECEIVE_DATA => 
                if rx_byte_tc = '1' then
                    receive_ns <= UPDATE_CIPHER_DATA; 
                end if;
            when UPDATE_CIPHER_DATA => 
                if rx_byte_tc = '0' then 
                    receive_ns <= RECEIVE_DATA;
                end if;
        end case; 
    end process; 
    
    input_buffer_register : process(clk)
    begin
        if rising_edge(clk) then
            if sci_rx_ready = '1' then 
                input_buffer <= input_buffer(119 downto 0) & sci_rx_data_out;
            end if; 
        end if;   
    end process;
    
    rx_byte_counter: process(clk, reset)
    begin
        if reset = '1' then
            rx_byte_count <= 0; 
        elsif rising_edge(clk) then 
            rx_byte_tc <= '0';
            if sci_rx_ready = '1' then 
                if rx_byte_count = 15 then 
                    rx_byte_tc <= '1';
                    rx_byte_count <= 0; 
                else 
                    rx_byte_count <= rx_byte_count + 1;
                end if;      
            end if;
        end if;
    end process;
    
    receiver_output_logic : process(receive_cs)
    begin
        key_en <= '0';
        cipher_en <= '0'; 
        case receive_cs is  
            when UPDATE_KEY => 
                key_en <= '1'; 
            when UPDATE_CIPHER_DATA => 
                cipher_en <= '1'; 
            when others => null;
        end case; 
    end process; 
    
    key_cipher_input_reg : process(clk)
    begin
        if rising_edge(clk) then 
            if key_ready = '1' then 
                cipher_words_in <= key_words_out; 
            end if;
        end if; 
    end process;  
    
    done <= cipher_ready;
    uart_tx_e <= sci_tx_out; 

end RTL;