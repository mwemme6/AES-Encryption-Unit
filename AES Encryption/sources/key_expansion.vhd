library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.defs_pkg.all;

entity key_expansion is 
    port(
        clk        : in  std_logic;
        reset      : in  std_logic;
        enable     : in  std_logic;
        key_in     : in  std_logic_vector(127 downto 0);
        done       : out std_logic;
        keys_out   : out all_round_key_word
    );
end entity;

architecture RTL of key_expansion is 
    -- Funktionen (unverändert)
    function rotation(word_in: round_key_word) return std_logic_vector is 
        variable temp: std_logic_vector(31 downto 0);
    begin
        temp(31 downto 24) := word_in(23 downto 16);
        temp(23 downto 16) := word_in(15 downto 8);
        temp(15 downto 8)  := word_in(7 downto 0);
        temp(7 downto 0)   := word_in(31 downto 24);
        return temp;
    end function;

    function sub(word_in: std_logic_vector(31 downto 0)) return std_logic_vector is
        variable temp: std_logic_vector(31 downto 0);
    begin
        for i in 0 to 3 loop
            temp(31-8*i downto 24-8*i) := sbox(to_integer(unsigned(word_in(31-8*i downto 24-8*i))));
        end loop;
        return temp;
    end function;

    function g_func(word_in: std_logic_vector(31 downto 0); cur_round: integer) return std_logic_vector is
    begin
        return sub(rotation(word_in)) xor rcon(cur_round);
    end function;
    
    -- Signale
    type state_type is (IDLE, INIT, EXPAND, DONE_S);
    signal state        : state_type := IDLE;
    signal cur_round    : integer range 0 to 10 := 0;
    signal temp_reg     : all_round_key_word := (others => (others => '0'));
    signal done_internal: std_logic := '0';
    signal g_result     : std_logic_vector(31 downto 0);
begin
  -- Kombinatorische g-Funktion
  g_result <= g_func(temp_reg(cur_round*4-1), cur_round) when cur_round > 0 else (others => '0');

  process(clk)
      variable w0, w1, w2, w3 : std_logic_vector(31 downto 0);
  begin
      if rising_edge(clk) then
          if reset = '1' then
              state <= IDLE;
              cur_round <= 0;
              done_internal <= '0';
              temp_reg <= (others => (others => '0'));
          else
              case state is
                  when IDLE =>
                      if enable = '1' then
                          state <= INIT;
                      end if;
                      
                  when INIT =>
                      -- Initialschlüssel laden
                      temp_reg(0) <= key_in(127 downto 96);
                      temp_reg(1) <= key_in(95 downto 64);
                      temp_reg(2) <= key_in(63 downto 32);
                      temp_reg(3) <= key_in(31 downto 0);
                      cur_round <= 1;
                      state <= EXPAND;
                  
                  when EXPAND =>
                      -- Alle 4 Wörter in einem Zyklus berechnen
                      w0 := temp_reg((cur_round-1)*4) xor g_result;
                      w1 := w0 xor temp_reg((cur_round-1)*4+1);
                      w2 := w1 xor temp_reg((cur_round-1)*4+2);
                      w3 := w2 xor temp_reg((cur_round-1)*4+3);
                      
                      -- Ergebnisse zuweisen
                      temp_reg(cur_round*4)   <= w0;
                      temp_reg(cur_round*4+1) <= w1;
                      temp_reg(cur_round*4+2) <= w2;
                      temp_reg(cur_round*4+3) <= w3;
                      
                      if cur_round = 10 then
                          state <= DONE_S;
                      else
                          cur_round <= cur_round + 1;
                      end if;
                  
                  when DONE_S =>
                      done_internal <= '1';
                      state <= IDLE;
              end case;
          end if;
      end if;
  end process;
  
  done <= done_internal;
  keys_out <= temp_reg;
end RTL;