library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_divider_self is
    generic (
        DIVIDE_BY : integer := 2  -- Must be >= 2, and even for 50% duty cycle
    );
    port (
        inclk0 : in  std_logic;  -- Input clock
        reset  : in  std_logic;
        outclk : out std_logic;
        locked : out std_logic
    );
end entity;

architecture behavior of clock_divider_self is
    signal counter  : integer range 0 to DIVIDE_BY - 1 := 0;
    signal temp_clk : std_logic := '0';
begin

    process (inclk0, reset)
    begin
        if reset = '0' then
            counter   <= 0;
            temp_clk  <= '0';
        elsif rising_edge(inclk0) then
            if counter = (DIVIDE_BY / 2) - 1 then
                temp_clk <= not temp_clk;
                counter  <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    outclk <= temp_clk;
    locked <= '1';  -- Always '1' unless you want to add a PLL-like lock state

end architecture;
