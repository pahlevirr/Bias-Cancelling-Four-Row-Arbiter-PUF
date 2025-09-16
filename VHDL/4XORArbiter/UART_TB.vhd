library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart is
end tb_uart;

architecture sim of tb_uart is
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal rx       : std_logic := '1'; -- Idle line is high
    signal tx       : std_logic;

    -- UART internal
    signal data_out : std_logic_vector(7 downto 0);
    signal data_valid : std_logic;
    signal tx_data  : std_logic_vector(7 downto 0) := x"55";
    signal tx_start : std_logic := '0';
    signal tx_busy  : std_logic;

    constant CLK_PERIOD   : time := 20 ns;     -- 50 MHz
    constant BAUD_PERIOD  : time := 8680 ns;   -- 115200 baud

    component UartRx
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            rx         : in  std_logic;
            data_out   : out std_logic_vector(7 downto 0);
            data_valid : out std_logic
        );
    end component;

    component UartTx
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            tx_start  : in  std_logic;
            tx_data   : in  std_logic_vector(7 downto 0);
            tx_busy   : out std_logic;
            tx        : out std_logic
        );
    end component;

begin

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Reset process
    rst_process : process
    begin
        rst <= '0';
        wait for 50 ns;
        rst <= '1';
        wait;
    end process;

    -- UART TX instance
    uart_tx_inst : UartTx
        port map (
            clk       => clk,
            rst       => rst,
            tx_start  => tx_start,
            tx_data   => tx_data,
            tx_busy   => tx_busy,
            tx        => rx  -- Loopback
        );

    -- UART RX instance
    uart_rx_inst : UartRx
        port map (
            clk        => clk,
            rst        => rst,
            rx         => rx,
            data_out   => data_out,
            data_valid => data_valid
        );

    -- Stimulus process
    stim_proc : process
    begin
        wait until rst = '1';
        wait for 100 ns;

        -- Test 1: TX to RX (loopback)
        tx_data <= x"A5";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';

        wait for 2 ms;

        -- Test 2: Manual RX Simulation
        rx <= '1';
        wait for 100 us;

        rx <= '0';  -- Start bit
        wait for BAUD_PERIOD;

        -- 8 data bits for 0xA5 = 10100101 (LSB first)
        rx <= '1'; wait for BAUD_PERIOD; -- Bit 0
        rx <= '0'; wait for BAUD_PERIOD; -- Bit 1
        rx <= '1'; wait for BAUD_PERIOD; -- Bit 2
        rx <= '0'; wait for BAUD_PERIOD; -- Bit 3
        rx <= '0'; wait for BAUD_PERIOD; -- Bit 4
        rx <= '1'; wait for BAUD_PERIOD; -- Bit 5
        rx <= '0'; wait for BAUD_PERIOD; -- Bit 6
        rx <= '1'; wait for BAUD_PERIOD; -- Bit 7

        rx <= '1'; wait for BAUD_PERIOD; -- Stop bit

        wait for 2 ms;

        assert false report "UART RX/TX test completed." severity note;
        wait;
    end process;

end sim;

