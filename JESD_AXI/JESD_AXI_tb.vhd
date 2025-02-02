LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY JESD_AXI_tb IS
END JESD_AXI_tb;

ARCHITECTURE Behavioral OF JESD_AXI_tb IS

COMPONENT JESD_AXI IS
    GENERIC (
        NUMBER_OF_LINES : INTEGER :=2; --Unflexible generic map
        OCTETS_FRAME : INTEGER := 2;
        NUMBER_OF_FRAMES_MULTIFRAME : INTEGER := 32
    );
    PORT (
        arest_n : IN STD_LOGIC; --asynchronous reset active low
        rx_aclk : IN STD_LOGIC; -- Clock
        rxN_tvalid : IN STD_LOGIC; 
        rx_tdata : IN STD_LOGIC_VECTOR((32*NUMBER_OF_LINES)-1 DOWNTO 0);--63 downto 0
        
        rx_start_of_frame : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rx_end_of_frame : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        rx_start_of_multiframe : IN STD_LOGIC_VECTOR(3 downto 0);
        rx_end_of_multiframe : IN STD_LOGIC_VECTOR(3 downto 0);

        rx_frame_error : STD_LOGIC_VECTOR((4*NUMBER_OF_LINES)-1 DOWNTO 0);

        --AXI-STREAM INTERFACE
        t_valid : OUT STD_LOGIC;
        t_ready : IN STD_LOGIC;
        t_data : OUT  STD_LOGIC_VECTOR((32*NUMBER_OF_LINES)-1 DOWNTO 0);
        t_last : OUT STD_LOGIC;
        t_keep : OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
        --FIFO FUL CONTROL SIGNAL
        fifo_full : OUT STD_LOGIC
    );

END COMPONENT;

    -- Constants
    CONSTANT CLK_PERIOD : time := 8 ns; --125MHz

    -- DUT Signals
    SIGNAL arest_n              : std_logic;
    SIGNAL rx_aclk              : std_logic;
    SIGNAL rxN_tvalid           : std_logic;

    -- Rx Data Signals
    SIGNAL rx_tdata             : std_logic_vector(63 DOWNTO 0); -- K == 2
    SIGNAL rx_start_of_frame    : std_logic_vector(3 DOWNTO 0);
    SIGNAL rx_end_of_frame      : std_logic_vector(3 DOWNTO 0);
    SIGNAL rx_start_of_multiframe : std_logic_vector(3 DOWNTO 0);
    SIGNAL rx_end_of_multiframe : std_logic_vector(3 DOWNTO 0);
    SIGNAL rx_frame_error       : std_logic_vector(7 DOWNTO 0);


    -- tx Data Signals
    SIGNAL t_valid              : std_logic;
    SIGNAL t_ready              : std_logic;
    SIGNAL t_data               : std_logic_vector(63 DOWNTO 0);
    SIGNAL t_last               : std_logic;
    SIGNAL t_keep               : std_logic_vector(7 DOWNTO 0);
    SIGNAL fifo_full            : std_logic;

BEGIN

    -- Instantiate the DUT
    DUT: JESD_AXI
        GENERIC MAP (
            NUMBER_OF_LINES => 2,
            OCTETS_FRAME => 2,
            NUMBER_OF_FRAMES_MULTIFRAME => 32
        )

        PORT MAP (
            arest_n => arest_n,
            rx_aclk => rx_aclk,
            rxN_tvalid => rxN_tvalid,
            rx_tdata => rx_tdata,
            rx_start_of_frame => rx_start_of_frame,
            rx_end_of_frame => rx_end_of_frame,
            rx_start_of_multiframe => rx_start_of_multiframe,
            rx_end_of_multiframe => rx_end_of_multiframe,
            rx_frame_error => rx_frame_error,
            t_valid => t_valid,
            t_ready => t_ready,
            t_data => t_data,
            t_last => t_last,
            t_keep => t_keep,
            fifo_full => fifo_full
        );


    -- standard clock process 
    clk_process: PROCESS
    BEGIN
        rx_aclk <= '0';
        WAIT FOR CLK_PERIOD / 2;
        rx_aclk <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS;



    -- standard reset process 
    reset_process: PROCESS
    BEGIN
        arest_n <= '0';
        WAIT FOR 2 ns;
        arest_n <= '1';
        WAIT;
    END PROCESS;



-- Testbench signals. 
 stimulus_process: PROCESS
BEGIN
    t_ready <= '0'; --check fifo full behaviour
    rxN_tvalid <= '0';
    rx_start_of_frame <= "0000";
    rx_end_of_frame <= "0000";
    rx_start_of_multiframe <= "0000";
    rx_end_of_multiframe <= "0000";
    rx_frame_error <= (OTHERS => '0');
    rx_tdata <= (others=>'0'); -- test random data in the bus
    wait for CLK_PERIOD / 2 ;
    rx_start_of_frame <= "0101";
    rx_end_of_frame <= "1010";
    rx_start_of_multiframe <= "0001";
    wait for CLK_PERIOD +1 ns;
    rxN_tvalid <= '1';
    rx_tdata <= X"7654321076543210"; -- test random data in the bus
    rx_end_of_multiframe <= "0000";
    wait for CLK_PERIOD;
    rx_tdata <= X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    rx_end_of_multiframe <= "1000";
    wait for CLK_PERIOD;
    rxN_tvalid <= '0';
    rx_end_of_multiframe <= "0000";
    
    wait for CLK_PERIOD;
    t_ready <= '1'; --check fifo full behaviour
    rxN_tvalid <= '1';
    rx_tdata <= X"7654321076543210"; -- test random data in the bus
    rx_end_of_multiframe <= "0000";
    wait for CLK_PERIOD;
    rx_tdata <= X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    t_ready <= '0'; --check fifo full behaviour
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    rx_end_of_multiframe <= "1000";
    wait for CLK_PERIOD;
    rxN_tvalid <= '0';
    rx_end_of_multiframe <= "0000";

    wait for CLK_PERIOD;
    rxN_tvalid <= '1';
    rx_tdata <= X"7654321076543210"; -- test random data in the bus
    rx_end_of_multiframe <= "0000";
    wait for CLK_PERIOD;
    rx_tdata <= X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    wait for CLK_PERIOD;
    rx_tdata <=  X"7654321076543210";
    wait for CLK_PERIOD;
    rx_tdata <=  X"FEDCBA98FEDCBA98"; 
    rx_end_of_multiframe <= "1000";
    wait for CLK_PERIOD;
    rxN_tvalid <= '0';
    rx_end_of_multiframe <= "0000";

    WAIT;
END PROCESS;




END Behavioral;