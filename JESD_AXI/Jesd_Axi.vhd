LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY JESD_AXI IS
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

END JESD_AXI;

ARCHITECTURE STRUCTURAL OF JESD_AXI IS

COMPONENT reg is
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
end COMPONENT;

COMPONENT Rotator is
    generic (
        NUMBER_OF_LINES : INTEGER :=2
    );
    port (
        clk                    : in  std_logic;           
        rst_n                  : in  std_logic;           
        enable                 : in  std_logic; 
        rx_start_of_multiframe : in std_logic_vector(3 downto 0);
        rx_end_of_multiframe   : in std_logic_vector(3 downto 0);
        rx_start_of_frame      : in std_logic_vector(3 downto 0);
        rx_end_of_frame        : in std_logic_vector(3 downto 0);
        
        byte0_adc0             : in  std_logic_vector(7 downto 0); 
        byte1_adc0             : in  std_logic_vector(7 downto 0); 
        byte2_adc0             : in  std_logic_vector(7 downto 0); 
        byte3_adc0             : in  std_logic_vector(7 downto 0); 
        byte0_adc1             : in  std_logic_vector(7 downto 0); 
        byte1_adc1             : in  std_logic_vector(7 downto 0); 
        byte2_adc1             : in  std_logic_vector(7 downto 0); 
        byte3_adc1             : in  std_logic_vector(7 downto 0);
        
        fifo_line0             : out std_logic_vector(13 downto 0);
        valid0                 : out std_logic;
        fifo_line1             : out std_logic_vector(13 downto 0);
        valid1                 : out std_logic;
        fifo_line2             : out std_logic_vector(13 downto 0);
        valid2                 : out std_logic;
        fifo_line3             : out std_logic_vector(13 downto 0);
        valid3                 : out std_logic
        
    );
end COMPONENT;


COMPONENT FIFO is
    generic (
        DATA_WIDTH_IN : integer := 14;
        FIFO_DEPTH : integer := 128
    );
    port (
        clk       : in  std_logic;                     
        reset     : in  std_logic;                
        fifo_line0 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid0     : in std_logic;
        fifo_line1 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid1     : in std_logic;
        fifo_line2 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid2     : in std_logic;
        fifo_line3 : in std_logic_vector(DATA_WIDTH_IN-1 downto 0);
        valid3     : in std_logic;
        rd_en     : in  std_logic;                     
        data_out  : out std_logic_vector(63 downto 0); 
        valid     : out std_logic;
        last      : out std_logic;
        tkeep     : out std_logic_vector(7 downto 0);
        fifo_full : out std_logic   
    );
end COMPONENT;


	SIGNAL rx_end_of_frame_1, rx_end_of_frame_2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL rx_start_of_frame_1, rx_start_of_frame_2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL rx_start_of_multiframe_1, rx_start_of_multiframe_2 : STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL rx_end_of_multiframe_1, rx_end_of_multiframe_2 : STD_LOGIC_VECTOR(3 downto 0);
	SIGNAL rx_frame_error_1, rx_frame_error_2 : STD_LOGIC_VECTOR((4*NUMBER_OF_LINES)-1 DOWNTO 0);

	SIGNAL rxN_tvalid_1, pos_reset : STD_LOGIC;
	SIGNAL rx_data_adc0, rx_data_adc1 : STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL rx_data_adc0_1, rx_data_adc1_1 : STD_LOGIC_VECTOR(31 downto 0); 

	SIGNAL byte0_adc0, byte1_adc0, byte2_adc0, byte3_adc0 : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL byte0_adc1, byte1_adc1, byte2_adc1, byte3_adc1 : STD_LOGIC_VECTOR(7 downto 0);

	SIGNAL fifo_line0, fifo_line1, fifo_line2, fifo_line3   :  std_logic_vector(13 downto 0);
	SIGNAL valid0, valid1,valid2,valid3 : STD_LOGIC;


BEGIN


--This circuitry synchronizes the inputs to the Rotator subunit following the
--timing diagram on JESD204 7.2v IP from xilinx...this circuit is optmized for the generic map, hence it is not fexible for other octests_per_

pos_reset <= not(arest_n);

--multiframe regs
reg0_end_of_multiframe: reg generic map (N=> 4)
                           port map(clk=>rx_aclk, reset=> pos_reset, enable=>'1', d_in=>rx_end_of_multiframe , q_out => rx_end_of_multiframe_1);

reg1_end_of_multiframe: reg generic map (N=> 4)
                           port map(clk=>rx_aclk, reset=> pos_reset, enable=>'1', d_in=>rx_end_of_multiframe_1 , q_out => rx_end_of_multiframe_2);						   

reg0_start_of_multiframe: reg generic map (N=> 4)
                           port map(clk=>rx_aclk, reset=> pos_reset, enable=>'1', d_in=>rx_start_of_multiframe , q_out =>  rx_start_of_multiframe_1);

reg1_start_of_multiframe: reg generic map (N=> 4)
                           port map(clk=>rx_aclk, reset=> pos_reset, enable=>'1', d_in=>rx_start_of_multiframe_1 , q_out => rx_start_of_multiframe_2);	

--frames regs
reg0_end_of_frame:reg generic map (N =>4)
		 			  port map(clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in=>rx_end_of_frame, q_out => rx_end_of_frame_1 );

reg1_end_of_frame:reg generic map (N =>4)
		 			  port map(clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in=> rx_end_of_frame_1, q_out => rx_end_of_frame_2 );

reg0_start_of_frame:reg generic map (N =>4)
		 			  port map(clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in=>rx_start_of_frame, q_out => rx_start_of_frame_1 );

reg1_start_of_frame:reg generic map (N =>4)
		 			  port map(clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in=>rx_start_of_frame_1, q_out => rx_start_of_frame_2 );



--valid reg
tvalid_reg: reg generic map(N=> 1)
					port map(clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in(0)=>rxN_tvalid, q_out(0) => rxN_tvalid_1);
                
--Data Pipe
rx_data_adc0 <= rx_tdata(31 downto 0);
rx_data_adc1 <= rx_tdata(63 downto 32);

data_adc0: reg generic map (N=> 32)
               port map(clk=>rx_aclk, reset => pos_reset, enable =>rxN_tvalid, d_in => rx_data_adc0, q_out => rx_data_adc0_1);

byte0_adc0 <= rx_data_adc0_1(7 downto 0);
byte1_adc0 <= rx_data_adc0_1(15 downto 8);
byte2_adc0 <= rx_data_adc0_1(23 downto 16);
byte3_adc0 <= rx_data_adc0_1(31 downto 24);

data_adc1: reg generic map (N=> 32)
               port map(clk=>rx_aclk, reset => pos_reset, enable =>rxN_tvalid, d_in => rx_data_adc1, q_out => rx_data_adc1_1);

byte0_adc1 <= rx_data_adc1_1(7 downto 0);
byte1_adc1 <= rx_data_adc1_1(15 downto 8);
byte2_adc1 <= rx_data_adc1_1(23 downto 16);
byte3_adc1 <= rx_data_adc1_1(31 downto 24);

--frame error pipe
reg0_frame_error: reg generic map (N=> (4*NUMBER_OF_LINES))
                     port map (clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in => rx_frame_error , q_out => rx_frame_error_1);

reg1_frame_error: reg generic map (N=> (4*NUMBER_OF_LINES))
                     port map (clk=>rx_aclk, reset => pos_reset, enable =>'1', d_in => rx_frame_error_1 , q_out => rx_frame_error_2);


--Rotator sub-unit 
rot0: Rotator port map(
	clk=>rx_aclk,
	rst_n => arest_n,
	enable =>  rxN_tvalid_1,
	rx_start_of_multiframe => rx_start_of_multiframe_2,
	rx_end_of_multiframe =>  rx_end_of_multiframe_2,
	rx_start_of_frame =>  rx_start_of_frame_2,
	rx_end_of_frame => rx_end_of_frame_2,
	byte0_adc0 => byte0_adc0,
	byte1_adc0 => byte1_adc0,
	byte2_adc0 => byte2_adc0,
	byte3_adc0 => byte3_adc0,
	byte0_adc1 => byte0_adc1,
	byte1_adc1 => byte1_adc1,
	byte2_adc1 => byte2_adc1,
	byte3_adc1 => byte3_adc1,
	fifo_line0 => fifo_line0,
	valid0 => valid0,
	fifo_line1 => fifo_line1,
	valid1 => valid1,
	fifo_line2 => fifo_line2,
	valid2 => valid2,
	fifo_line3 => fifo_line3,
	valid3 => valid3
);

--FIFO sub-unit
AxiFifo: FIFO generic map(DATA_WIDTH_IN=> 14, FIFO_DEPTH=>128)
			  port map(clk=>rx_aclk,
			  		   reset=>pos_reset,
					   fifo_line0=>fifo_line0,
					   valid0=>valid0,
					   fifo_line1=>fifo_line1,
					   valid1=>valid1,
					   fifo_line2=>fifo_line2,
					   valid2=>valid2,
					   fifo_line3=>fifo_line3,
					   valid3=>valid3,
					   rd_en=>t_ready,
					   data_out=>t_data,
					   valid=>t_valid,
					   last=>t_last,
					   tkeep=>t_keep,
					   fifo_full=>fifo_full);


	--rimisurare l'area degli accellerators con full folding
	--sysref external-> use Subclass0 since it only requires synch and no sysref
	--controlla le bram resources della zc706 to determine the maximum number of buffered multistream we can have 
	-- get the license for the jesd core


END;