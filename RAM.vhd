library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    Port ( 
        CLOCK_50     : in STD_LOGIC;                     -- 50 MHz clock input
        KEY0         : in STD_LOGIC;                     -- Reset button (active low)
        LEDR         : out STD_LOGIC_VECTOR(7 downto 0); -- 8-bit LED output
        HEX0         : out STD_LOGIC_VECTOR(6 downto 0); -- 7-segment display (state indicator)
        HEX1         : out STD_LOGIC_VECTOR(6 downto 0)  -- 7-segment display (address)
    );
end RAM;
5
architecture Behavioral of RAM is
    -- State type definition
    type state_type is (START_STATE, WRITE_STATE, CLEAR_STATE, READ_STATE);
    
    -- Signals
    signal current_state : state_type := START_STATE;    -- Current state of the FSM
    signal addr_counter  : unsigned(3 downto 0) := (others => '0'); -- 4-bit address counter
    signal we_internal   : STD_LOGIC := '0';             -- Write Enable signal
    signal data_internal : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- Data signal
    signal addr_internal : STD_LOGIC_VECTOR(3 downto 0); -- Address for the LEDs
    signal reset_n       : STD_LOGIC;                    -- Active high reset signal

    -- Clock divider signals
    signal clk_divided : std_logic := '0';               -- Divided clock signal
    signal counter     : integer := 0;                   -- Counter for clock division

    constant CLK_DIV_FACTOR : integer := 25000000;       -- Divide 50 MHz by 2*25M to get 1 Hz
begin

    -- Reset logic
    reset_n <= not KEY0;

    -- Clock Divider Process
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if counter = CLK_DIV_FACTOR - 1 then
                counter <= 0;
                clk_divided <= not clk_divided; -- Toggle the slower clock
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- Main State Machine Process
    state_machine: process(clk_divided, reset_n)
    begin
        if reset_n = '1' then
            -- Reset conditions
            current_state <= START_STATE;
            addr_counter <= (others => '0');
            we_internal <= '0';
        elsif rising_edge(clk_divided) then
            -- State Transition Logic
            case current_state is
                when START_STATE =>
                    current_state <= WRITE_STATE;
                    addr_counter <= (others => '0');
                    we_internal <= '1';
                
                when WRITE_STATE =>
                    if addr_counter = "1111" then
                        current_state <= CLEAR_STATE;
                        we_internal <= '0';
                    else
                        addr_counter <= addr_counter + 1;
                    end if;
                
                when CLEAR_STATE =>
                    addr_counter <= (others => '0');
                    current_state <= READ_STATE;
                    we_internal <= '0';
                
                when READ_STATE =>
                    if addr_counter = "1111" then
                        current_state <= START_STATE;
                    else
                        addr_counter <= addr_counter + 1;
                    end if;
            end case;
        end if;
    end process state_machine;

    -- Data Output Process
    data_output: process(current_state, addr_counter)
    begin
        case current_state is
            when START_STATE =>
                data_internal <= (others => '0');
            
            when WRITE_STATE =>
                -- Write data that matches the address
                data_internal <= STD_LOGIC_VECTOR(resize(unsigned(addr_counter), 8));
            
            when CLEAR_STATE =>
                data_internal <= (others => '0');
            
            when READ_STATE =>
                -- Simulate read by outputting address value
                data_internal <= STD_LOGIC_VECTOR(resize(unsigned(addr_counter), 8));
        end case;
    end process data_output;

    -- Address Output
    addr_internal <= STD_LOGIC_VECTOR(addr_counter);
    LEDR <= data_internal;

    -- 7-Segment Display Decoder
    hex_decoder: process(addr_internal, we_internal)
    variable hex_addr : STD_LOGIC_VECTOR(3 downto 0);
    begin
        hex_addr := addr_internal;
        
        -- Address display on HEX1
        case hex_addr is
            when "0000" => HEX1 <= "1000000"; -- 0
            when "0001" => HEX1 <= "1111001"; -- 1
            when "0010" => HEX1 <= "0100100"; -- 2
            when "0011" => HEX1 <= "0110000"; -- 3
            when "0100" => HEX1 <= "0011001"; -- 4
            when "0101" => HEX1 <= "0010010"; -- 5
            when "0110" => HEX1 <= "0000010"; -- 6
            when "0111" => HEX1 <= "1111000"; -- 7
            when "1000" => HEX1 <= "0000000"; -- 8
            when "1001" => HEX1 <= "0010000"; -- 9
            when "1010" => HEX1 <= "0001000"; -- A
            when "1011" => HEX1 <= "0000011"; -- B
            when "1100" => HEX1 <= "1000110"; -- C
            when "1101" => HEX1 <= "0100001"; -- D
            when "1110" => HEX1 <= "0000110"; -- E
            when "1111" => HEX1 <= "0001110"; -- F
            when others => HEX1 <= "1111111"; -- off
        end case;

        -- State display on HEX0
        if we_internal = '1' then
            HEX0 <= "1111001"; -- 1 for write
        else
            HEX0 <= "1000000"; -- d for read
        end if;
    end process hex_decoder;

end Behavioral;