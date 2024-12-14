library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIFO is --dont change generic map
    generic (
        DATA_WIDTH_IN : integer := 14;  -- Data bus width (parallelism)
        FIFO_DEPTH : integer := 128 -- FIFO depth (number of entries)
    );
    port (
        clk       : in  std_logic;                     -- Clock signal
        reset     : in  std_logic;                     -- Asynchronous reset
        
        --for ADC0 data ---
        fifo_line0 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid0     : in std_logic;
        fifo_line1 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid1     : in std_logic;
        
        -- for ADC1 data --
        fifo_line2 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid2     : in std_logic;
        fifo_line3 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid3     : in std_logic;
        
        --AXI-Stream FSM interface--
        rd_en     : in  std_logic;                     -- Read enable
        data_out  : out std_logic_vector(63 downto 0); -- Data output
        valid     : out std_logic;
        last      : out std_logic;
        tkeep     : out std_logic_vector(7 downto 0);
        
        fifo_full : out std_logic     -- FIFO full flag
    );
end FIFO;

architecture Behavioral of FIFO is
    -- Derived constants
    constant ADDR_WIDTH : integer :=7; --integer(ceil(log2(real(FIFO_DEPTH)))); -- Address width

    -- Internal signals
    type memory_array_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(63 downto 0);
    signal memory : memory_array_type;
    --signal memory : array (0 to FIFO_DEPTH-1) of std_logic_vector(63 downto 0);


    signal wr_ptr : unsigned(ADDR_WIDTH downto 0) := (others => '0'); -- Write pointer
    signal rd_ptr : unsigned(ADDR_WIDTH downto 0) := (others => '0'); -- Read pointer
    signal full   : std_logic;
    signal sub_words, trigger_activated : std_logic;

begin

    -- Write process
    process (clk,reset)--asynch reset
    variable wr_ptr_imm : unsigned(ADDR_WIDTH downto 0) := (others => '0');
    begin
        if (reset = '1') then
            wr_ptr <= (others => '0');
            memory <= (others => (others => '0'));
            sub_words <= '0';
            wr_ptr_imm :=  (others => '0');

        elsif(rising_edge(clk)) then
            if (valid0 = '1' and valid2 = '1' and  full = '0' and valid1 = '0' and valid3 = '0') then
                if (sub_words = '0') then
                    memory(to_integer(wr_ptr))(13 downto 0) <= fifo_line0;
                    memory(to_integer(wr_ptr))(15 downto 14) <= (others => fifo_line0(13));
                    memory(to_integer(wr_ptr))(45 downto 32) <= fifo_line2;
                    memory(to_integer(wr_ptr))(47 downto 46) <= (others => fifo_line2(13));
                    sub_words <= '1';
                elsif(sub_words = '1') then
                    memory(to_integer(wr_ptr))(29 downto 16) <= fifo_line0;
                    memory(to_integer(wr_ptr))(31 downto 30) <= (others => fifo_line0(13));
                    memory(to_integer(wr_ptr))(61 downto 48) <= fifo_line2;
                    memory(to_integer(wr_ptr))(63 downto 62) <= (others => fifo_line2(13));
                    wr_ptr_imm := wr_ptr + 1;
                    if(wr_ptr_imm = FIFO_DEPTH) then
                        wr_ptr <=  (others => '0'); 
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;

                    sub_words <= '0';
                end if;
            elsif (valid0='1' and valid2 = '1' and full = '0' and valid1 = '1' and valid3 = '1') then --add valid2 and valid3
                if(sub_words = '0') then
                    memory(to_integer(wr_ptr))(13 downto 0) <= fifo_line0;
                    memory(to_integer(wr_ptr))(15 downto 14) <= (others => fifo_line0(13));
                    memory(to_integer(wr_ptr))(29 downto 16) <= fifo_line1;
                    memory(to_integer(wr_ptr))(31 downto 30) <= (others => fifo_line1(13));
                    memory(to_integer(wr_ptr))(45 downto 32) <= fifo_line2;
                    memory(to_integer(wr_ptr))(47 downto 46) <= (others => fifo_line2(13));
                    memory(to_integer(wr_ptr))(61 downto 48) <= fifo_line3;
                    memory(to_integer(wr_ptr))(63 downto 62) <= (others => fifo_line3(13));
                    wr_ptr_imm := wr_ptr + 1;
                    if(wr_ptr_imm = FIFO_DEPTH) then
                        wr_ptr <=  (others => '0'); 
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;
                    sub_words <= '0';
                else --sub_words = '1'
                    memory(to_integer(wr_ptr))(29 downto 16) <= fifo_line0;
                    memory(to_integer(wr_ptr))(31 downto 30) <= (others => fifo_line0(13));
                    memory(to_integer(wr_ptr))(61 downto 48) <= fifo_line2;
                    memory(to_integer(wr_ptr))(63 downto 62) <= (others => fifo_line0(13));
                    wr_ptr_imm := wr_ptr + 1;
                    if(wr_ptr_imm = FIFO_DEPTH) then
                        wr_ptr <=  (others => '0'); 
                        wr_ptr_imm := (others => '0');
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;
                    memory(to_integer(wr_ptr_imm))(13 downto 0) <= fifo_line1;
                    memory(to_integer(wr_ptr))(15 downto 14) <= (others => fifo_line0(13)); 
                    memory(to_integer(wr_ptr_imm))(45 downto 32) <= fifo_line3; 
                    memory(to_integer(wr_ptr))(47 downto 46) <= (others => fifo_line3(13));
                    sub_words <= '1';
                end if;
            else
                wr_ptr_imm := (others => '0');
                wr_ptr <= wr_ptr;
                sub_words <= sub_words;
            end if;
        end if;
    end process;





    -- Read process 2 AXI stream --
    process (clk,reset)
    variable rd_ptr_imm : unsigned(ADDR_WIDTH downto 0) := (others => '0');
    begin
        if reset = '1' then
            rd_ptr <= (others => '0');
            last <= '0';
            valid <= '0';
            data_out <= (others => '0');
            tkeep <= (others => '0');

        elsif (rising_edge(clk)) then
            if(full = '0' and rd_ptr /= wr_ptr)then
                valid <= '1';
                tkeep <= "11111111";
                data_out <=  memory(to_integer(rd_ptr));
                last <= '1'; --unpacked data
                if(rd_en = '1') then
                    rd_ptr_imm := rd_ptr +1;
                    if(rd_ptr_imm = FIFO_DEPTH) then
                        rd_ptr_imm := (others => '0');
                        rd_ptr <=  (others => '0');
                    else
                        rd_ptr <= rd_ptr +1;
                    end if;
                else
                    rd_ptr <= rd_ptr;
                end if;
            else
                valid <= '0';
                last <= '0';
                tkeep <= (others => '0');
                data_out <= (others => '0');
            end if;
        end if;
    end process;

    
    -- Count management  Check if the FIFO is full for debugging the FIFO leght--
    process (clk, reset)
    begin
        if(reset = '1') then --asynch reset
            full <= '0';
            trigger_activated <= '0';


        elsif rising_edge(clk) then
            if (full  = '0') then 
                if((to_integer(wr_ptr) = FIFO_DEPTH-1) and rd_ptr = 0) then 
                    full <= '1';
                elsif (wr_ptr < rd_ptr) then --this means that the writing has alredy turned the FIFO 
                    trigger_activated <= '1';
                
                elsif (trigger_activated = '1') then
                    if (wr_ptr >= rd_ptr) then 
                        full <= '1';
                    elsif (rd_ptr < wr_ptr) then
                        trigger_activated <= '0';
                    else
                        trigger_activated <= trigger_activated;
                    end if;
                else
                    trigger_activated <= '0';
                    full <= '0';
                end if;
            else
                full <= '1';
            end if;

        end if;
    end process;

    -- Flags
    fifo_full <= full;

end Behavioral;
