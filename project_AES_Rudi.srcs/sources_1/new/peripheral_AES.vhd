--###############################################################################
--# peripheral_millis.vhd  - A millisecond counter
--#
--# A GPIO peripheral
--#
--# See https://github.com/hamsternz/Rudi-RV32I
--#
--# MIT License
--#
--###############################################################################
--#
--# Copyright (c) 2020 Mike Field
--#
--# Permission is hereby granted, free of charge, to any person obtaining a copy
--# of this software and associated documentation files (the "Software"), to deal
--# in the Software without restriction, including without limitation the rights
--# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--# copies of the Software, and to permit persons to whom the Software is
--# furnished to do so, subject to the following conditions:
--#
--# The above copyright notice and this permission notice shall be included in all
--# copies or substantial portions of the Software.
--#
--# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--# SOFTWARE.
--#
--###############################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


entity peripheral_AES is
  generic ( clock_freq  : natural );
  port ( clk            : in  STD_LOGIC;

         bus_busy       : out STD_LOGIC;
         bus_addr       : in  STD_LOGIC_VECTOR(5 downto 2);
         bus_enable     : in  STD_LOGIC;
         bus_write_mask : in  STD_LOGIC_VECTOR(3 downto 0);
         bus_write_data : in  STD_LOGIC_VECTOR(31 downto 0);
         bus_read_data  : out STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
         reset          : in std_logic;

         gpio           : inout STD_LOGIC_VECTOR);

end entity;

architecture Behavioral of peripheral_AES is
    signal data_valid   : STD_LOGIC := '1';
    
    type array_t is array (0 to 3) of std_logic_vector(31 downto 0);
    signal aes_key_regs : array_t;

    signal aes_msg_regs : array_t;
    
    signal aes_result_regs : array_t;
    
    signal aes_ctrl : std_logic_vector(31 downto 0);
    signal aes_status : std_logic_vector(31 downto 0);
    
    signal aes_key_vector : std_logic_vector(127 downto 0);
    signal aes_msg_vector : std_logic_vector(127 downto 0);
    signal aes_result_vector : std_logic_vector(127 downto 0);
    
    signal aes_ready    : std_logic;    --done bit bzw bei mir status
    signal aes_start    : std_logic;
    
    
    function flip_input(a: std_logic_vector(31 downto 0)) return std_logic_vector is
        variable flipped : std_logic_vector(31 downto 0);
    begin
        flipped := a(7 downto 0) & a(15 downto 8) & a(23 downto 16) & a (31 downto 24);
        return flipped;
    end function;
    
    component aes_enc_top 
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

begin

    aes_top_inst : aes_enc_top 
        port map (
            clk => clk,
            reset => reset,
            enable => aes_start,
            key => aes_key_vector,
            plaintext => aes_msg_vector,
            ciphertext => aes_result_vector,
            done => aes_ready
            );

process(bus_enable, bus_write_mask, data_valid)
begin
    bus_busy <= '0';
    if bus_enable = '1' and bus_write_mask = "0000" then
        if data_valid = '0' then
           bus_busy <= '1';
        end if;
    end if;
end process;

process(clk) 
begin
    if rising_edge(clk) then

        -- Process the bus request
        data_valid <= '0';
        bus_read_data <= x"00000000";
        if bus_enable = '1' then
            if bus_write_mask /= "0000" then
                case bus_addr is
                    when "0000" =>
                        aes_key_regs(0) <=  bus_write_data;
                    when "0001" =>
                        aes_key_regs(1) <= bus_write_data;  
                    when "0010" =>
                        aes_key_regs(2) <= bus_write_data;
                    when "0011" =>
                        aes_key_regs(3) <= bus_write_data;
                    when "0100" =>
                        aes_msg_regs(0) <= bus_write_data; 
                    when "0101" =>
                        aes_msg_regs(1) <= bus_write_data; 
                    when  "0110" =>
                        aes_msg_regs(2) <= bus_write_data;  
                    when "0111" =>
                        aes_msg_regs(3) <= bus_write_data; 
                    when "1000" =>
                        aes_ctrl <= bus_write_data;             --das hier ist start, dann wohl enable?
                    when others =>
                end case;
            else
                if data_valid = '0' then
                   data_valid <= '1';
                end if;
                
                case bus_addr is
                    when "1001" =>
                        bus_read_data <= aes_status;            --done bit; hier vllt auch mit bit maske arbeiten
                    when "1100" =>
                        bus_read_data <= aes_result_regs(0);
                    when "1101" =>
                        bus_read_data <= aes_result_regs(1);
                    when "1110" => 
                        bus_read_data <= aes_result_regs(2);
                    when "1111" =>
                        bus_read_data <= aes_result_regs(3);
                    when others =>
                end case; 
            end if;
        end if;
    end if;
end process;
    
    aes_status(0) <= aes_ready;
    aes_start <= aes_ctrl(0);
    
    aes_key_vector <= flip_input(aes_key_regs(0)) & flip_input(aes_key_regs(1)) & flip_input(aes_key_regs(2)) & flip_input(aes_key_regs(3));
    aes_msg_vector <= flip_input(aes_msg_regs(0)) & flip_input(aes_msg_regs(1)) & flip_input(aes_msg_regs(2)) & flip_input(aes_msg_regs(3));
    
    aes_result_regs(0) <= flip_input(aes_result_vector(127 downto 96));
    aes_result_regs(1) <= flip_input(aes_result_vector(95 downto 64));
    aes_result_regs(2) <= flip_input(aes_result_vector(63 downto 32));
    aes_result_regs(3) <= flip_input(aes_result_vector(31 downto 0));

end Behavioral;