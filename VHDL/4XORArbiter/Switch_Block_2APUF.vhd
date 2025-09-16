LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity Switch_Block_2APUF is
	port (
		clk			: in std_logic;
		reset			: in std_logic;
		challenge	: in std_logic_vector(127 downto 0);
		enable_in	: in std_logic_vector(3 downto 0);
		response		: out std_logic;
		ena_get		: in std_logic
	
	);
end Switch_Block_2APUF;


architecture main of Switch_Block_2APUF is
	signal len_gate	: std_logic_vector(127 downto 0) := (others => '0');
	signal len2_gate	: std_logic_vector(127 downto 0) := (others => '0');
	signal len3_gate	: std_logic_vector(127 downto 0) := (others => '0');
	signal len4_gate	: std_logic_vector(127 downto 0) := (others => '0');
	signal pulse		: std_logic;
	
	attribute KEEP : string;
	attribute KEEP of len_gate   : signal is "true";
	attribute KEEP of len2_gate  : signal is "true";
	attribute KEEP of len3_gate  : signal is "true";
	attribute KEEP of len4_gate  : signal is "true";
	
	signal FF1, FF2 : std_logic;
	
		--clock divider
	signal count: integer:=1;
	signal tmp : std_logic := '0';
	signal clk_out : std_logic;
	signal clk_lock	: std_logic;

	
	component mux2 
	port(
		data0      	: in  std_logic;
		data1      	: in  std_logic;
		sel    	 	: in  std_logic;
		result      : out std_logic
	);
	end component;
	
	component AndGate
   port(
      a : IN std_logic;
      b : IN std_logic;          
      o : OUT std_logic
      );
   end component;
	
	component FF_Symmetrical is
    port (
        clk  : in  std_logic;
        ena  : in  std_logic;
        A    : in  std_logic;
        B    : in  std_logic;
        Q    : out std_logic
    );
	end component;
	
	component XorGate
    Port ( 
		a : in  STD_LOGIC;
	   b : in  STD_LOGIC;
	   o : out  STD_LOGIC
		);
	end component;
	
begin

	-- Clock divider
	
	ClockDivider10MHz: entity work.clock_divider_self
		 generic map (DIVIDE_BY => 10)
		 port map (
			  inclk0 => clk,
			  reset  => reset,
			  outclk => clk_out,
			  locked => clk_lock
		 );

	-- Generate the first generator for the MUX2-1 with randomness
	 
    process(clk, reset, ena_get)
    begin
        --if reset = '0' then
		  if reset = '0' or ena_get = '0' then
            len_gate(0) <= '0';
				len2_gate(0) <= '0';
				len3_gate(0) <= '0';
				len4_gate(0) <= '0';
		  elsif ena_get = '1' then
			  if rising_edge(clk) then
					len_gate(0) <= enable_in(0) xor clk_out;
					len2_gate(0) <= enable_in(1) xor clk_out;
					len3_gate(0) <= enable_in(2) xor clk_out;
					len4_gate(0) <= enable_in(3) xor clk_out;
			  end if;
		  end if;
    end process;
		
	-- Generate the 128 arrays of MUX2-1

	buildarbiter1: for i in 1 to len_gate'high generate		-- Generate the Not Gate as much as Signals
		MuxGate_i : mux2 port map ( 
				data0  => len_gate(i-1), 						-- LUT input
				data1	 => len2_gate(i-1),
				sel	 => challenge(i-1), 
				result  => len_gate(i)    						-- LUT general output
			);
	end generate;

	buildarbiter2: for i in 1 to len2_gate'high generate		-- Generate the Not Gate as much as Signals
		MuxGate_ii : mux2 port map ( 
				data0  => len2_gate(i-1), 						-- LUT input
				data1	 => len_gate(i-1),
				sel	 => challenge(i-1), 
				result  => len2_gate(i)    						-- LUT general output
			);
	end generate;

	ArbFF1: FF_Symmetrical
		 port map (
			  clk => clk,
			  ena => ena_get,
			  A   => len_gate(127),
			  B   => len2_gate(127),
			  Q   => FF1
		 );


    
    --XorGate_0: XorGate port map ( a => FF1, b => FF2, o => pulse );
	 

	
-- Output assignment
	response <= FF1;


end main;