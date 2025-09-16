library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xoruf is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rx          : in  std_logic;
        tx          : out std_logic;
		  tailer0	  : out std_logic;
		  tailer1	  : out std_logic;
		  tailer2	  : out std_logic;
		  tailer3	  : out std_logic
    );
end entity;

architecture rtl of xoruf is
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

    component Switch_Block
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            challenge  : in  std_logic_vector(127 downto 0);
            enable_in  : in  std_logic_vector(3 downto 0);
            response   : out std_logic;
            ena_get    : in  std_logic;
				tail0, tail1, tail2, tail3 : out std_logic
        );
    end component;

    -- Signals
    signal challenge      : std_logic_vector(127 downto 0) := (others => '0');
    signal enable         : std_logic_vector(3 downto 0)   := (others => '0');
    signal rx_byte        : std_logic_vector(7 downto 0);
    signal rx_valid       : std_logic;
    signal rx_count       : integer range 0 to 17 := 0;
    signal response_bit   : std_logic := '0';

    signal tx_start       : std_logic := '0';
    signal tx_busy        : std_logic;

    signal puf_done       : std_logic;
    signal puf_enabled    : std_logic := '0';
	 
	 -- States
    type state_type is (IDLE, RECEIVING, WAITING_PUF, SENDING);
    signal state        : state_type := IDLE;

    signal delay_cnt    : integer range 0 to 101 := 0;
	 
	 signal tx_data     : std_logic_vector(7 downto 0) := (others => '0');
	 signal sample_count: integer range 0 to 8 := 0;

begin

    -- UART RX instance
    uart_rx_inst : UartRx
        port map (
            clk        => clk,
            rst        => rst,
            rx         => rx,
            data_out   => rx_byte,
            data_valid => rx_valid
        );

    -- UART TX instance
    uart_tx_inst : UartTx
        port map (
            clk       => clk,
            rst       => rst,
            tx_start  => tx_start,
            tx_data   => tx_data,
            tx_busy   => tx_busy,
            tx        => tx
        );

    -- Arbiter PUF (Switch_Block)
    puf_inst : Switch_Block
        port map (
            clk        => clk,
            reset      => rst,
            challenge  => challenge,
            enable_in  => enable,
            response   => response_bit,
            ena_get    => puf_enabled,
				tail0			=> tailer0,
				tail1			=> tailer1,
				tail2			=> tailer2,
				tail3			=> tailer3
        );


-- Main controller
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                rx_count     <= 0;
                state        <= IDLE;
                puf_enabled  <= '0';
                tx_start     <= '0';
            else
                case state is
                    when IDLE =>
								puf_enabled <= '0';
                        if rx_valid = '1' then
                            rx_count <= 1;
                            challenge(127 downto 120) <= rx_byte;
                            state <= RECEIVING;
                        end if;

                    when RECEIVING =>
                        if rx_valid = '1' then
                            if rx_count < 16 then
                                challenge(127 - rx_count*8 downto 120 - rx_count*8) <= rx_byte;
                                rx_count <= rx_count + 1;
                            elsif rx_count = 16 then
                                enable <= rx_byte(3 downto 0);
                                puf_enabled <= '1';
                                delay_cnt <= 0;
                                state <= WAITING_PUF;
                                rx_count <= 0;
                            end if;
                        end if;

                    when WAITING_PUF =>
						  
								if delay_cnt < 33 then
									 delay_cnt <= delay_cnt + 1;
								else
									 delay_cnt <= 0;

									 tx_data <= tx_data(6 downto 0) & response_bit;
									 sample_count <= sample_count + 1;

									 if sample_count = 7 then
										  state <= SENDING;
									 else
										  puf_enabled <= '1'; -- retrigger PUF
									 end if;
								end if;

                    when SENDING =>
								puf_enabled <= '0';
                        if tx_busy = '0' then
									tx_start <= '1'; -- triggers UART send
									sample_count <= 0;
									state <= IDLE;
									enable <= "0000";
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture;
