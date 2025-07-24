--###############################################################################
--# tb_riscv.vhd  - Testbench the basic RV32I instrucions function.
--#
--# Part of the Rudi-RV32I project
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_level is
end entity;

architecture behavior of tb_top_level is

    -- Signal für Takt und I/Os
    signal clk         : std_logic := '0';
    signal uart_rx     : std_logic := '1'; -- Leerlaufzustand für UART RX
    signal uart_tx     : std_logic;
    signal gpio        : std_logic_vector(15 downto 0);

    -- Instantiate das DUT (Device Under Test)
    component top_level_expanded
        generic (
            clock_freq           : natural;
            bus_bridge_use_clk   : std_logic;
            bus_expander_use_clk : std_logic;
            cpu_minimize_size    : std_logic
        );
        port (
            clk          : in  std_logic;
            uart_rxd_out : out std_logic;
            uart_txd_in  : in  std_logic;
            gpio         : inout std_logic_vector(15 downto 0)
        );
    end component;

begin

    -- Generiere den Takt mit 10 ns Periodendauer (100 MHz)
    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    -- Instanz des Designs
    uut: top_level_expanded
        generic map (
            clock_freq           => 100_000_000, -- 100 MHz
            bus_bridge_use_clk   => '1',
            bus_expander_use_clk => '1',   -- setze '1' um Taktnutzung zu aktivieren
            cpu_minimize_size    => '1'
        )
        port map (
            clk          => clk,
            uart_rxd_out => uart_tx,
            uart_txd_in  => uart_rx,
            gpio         => gpio
        );

end architecture;
