library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration
entity mux is
    generic (
        N : integer := 8 -- Bus width (default is 8 bits)
    );
    port (
        A   : in  std_logic_vector(N-1 downto 0); -- Input bus A
        B   : in  std_logic_vector(N-1 downto 0); -- Input bus B
        sel : in  std_logic;                      -- Selection bit
        Y   : out std_logic_vector(N-1 downto 0)  -- Output bus
    );
end mux;

-- Architecture declaration
architecture Behavioral of mux is
begin
    process (A, B, sel)
    begin
        if sel = '0' then
            Y <= A; -- Select input A
        else
            Y <= B; -- Select input B
        end if;
    end process;
end Behavioral;
