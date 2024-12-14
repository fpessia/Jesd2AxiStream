library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reg is
    generic (
        N : integer := 8 -- Width of the register
    );
    port (
        clk    : in  std_logic;           -- Clock signal
        reset  : in  std_logic;           -- Reset signal (active high)
        enable : in  std_logic;           -- Enable signal
        d_in   : in  std_logic_vector(N-1 downto 0); -- Data input
        q_out  : out std_logic_vector(N-1 downto 0)  -- Data output
    );
end reg;

architecture Behavioral of reg is
    signal reg_val : std_logic_vector(N-1 downto 0) := (others => '0');
begin
    process (clk, reset)--asynchronous reset
    begin
        if reset = '1' then
            reg_val <= (others => '0'); -- Clear the register on reset
        elsif rising_edge(clk) then
            if enable = '1' then
                reg_val <= d_in; -- Load data on enable
            end if;
        end if;
    end process;

    q_out <= reg_val; -- Assign register value to output
end Behavioral;
