library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Rotator is
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
        
        --ADC0-- 
        byte0_adc0             : in  std_logic_vector(7 downto 0); 
        byte1_adc0             : in  std_logic_vector(7 downto 0); 
        byte2_adc0             : in  std_logic_vector(7 downto 0); 
        byte3_adc0             : in  std_logic_vector(7 downto 0); 
        --ADC1-- 
        byte0_adc1             : in  std_logic_vector(7 downto 0); 
        byte1_adc1             : in  std_logic_vector(7 downto 0); 
        byte2_adc1             : in  std_logic_vector(7 downto 0); 
        byte3_adc1             : in  std_logic_vector(7 downto 0);
        
        --for ADC0 data--
        fifo_line0             : out std_logic_vector(13 downto 0);
        valid0                 : out std_logic;
        fifo_line1             : out std_logic_vector(13 downto 0);
        valid1                 : out std_logic;
        --for ADC1 data--
        fifo_line2             : out std_logic_vector(13 downto 0);
        valid2                 : out std_logic;
        fifo_line3             : out std_logic_vector(13 downto 0);
        valid3                 : out std_logic  
    );
end Rotator;

architecture structural of Rotator is

    component reg is
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
    end component;
    
    component mux is
        generic (
            N : integer := 8 -- Bus width (default is 8 bits)
        );
        port (
            A   : in  std_logic_vector(N-1 downto 0); -- Input bus A
            B   : in  std_logic_vector(N-1 downto 0); -- Input bus B
            sel : in  std_logic;                      -- Selection bit
            Y   : out std_logic_vector(N-1 downto 0)  -- Output bus
        );
    end component;

    SIGNAL byte3_adc0_1 , byte3_adc1_1 : STD_LOGIC_VECTOR(7 downto 0);
    
    SIGNAL Bus0_adc0, Bus1_adc0, Bus2_adc0, Bus3_adc0  : STD_LOGIC_VECTOR(13 downto 0);
    SIGNAL Bus0_adc1,Bus1_adc1,Bus2_adc1,Bus3_adc1  : STD_LOGIC_VECTOR(13 downto 0);

    SIGNAL valid0_adc0, valid1_adc0, valid2_adc0,valid3_adc0 : STD_LOGIC;
    SIGNAL valid0_adc1, valid1_adc1, valid2_adc1,valid3_adc1 : STD_LOGIC;
    SIGNAL pos_rst, en_buff_adc0, en_buff_adc1 : STD_LOGIC; 

    SIGNAL frame, frame_1, current_frame : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL sel_frame : STD_LOGIC;

    begin
        pos_rst <= not(rst_n);

        Bus0_adc0(13 downto 6) <= byte0_adc0;
        Bus0_adc0(5 downto 0) <= byte1_adc0(7 downto 2);-- (1 : 0) tail
        valid0_adc0 <= rx_start_of_frame(0) and not(rx_start_of_frame(1)) and  rx_end_of_frame(1);

        Bus0_adc1(13 downto 6) <= byte0_adc1;
        Bus0_adc1(5 downto 0) <= byte1_adc1(7 downto 2);-- (1 : 0) tail
        valid0_adc0 <= rx_start_of_frame(0) and not(rx_start_of_frame(1)) and  rx_end_of_frame(1);

        Bus1_adc0(13 downto 6) <= byte1_adc0;
        Bus1_adc0(5 downto 0 ) <= byte2_adc0(7 downto 2);
        valid1_adc0 <= rx_start_of_frame(1) and not(rx_start_of_frame(2)) and rx_end_of_frame(2);

        Bus1_adc1(13 downto 6) <= byte1_adc1;
        Bus1_adc1(5 downto 0 ) <= byte2_adc1(7 downto 2);
        valid1_adc1 <= rx_start_of_frame(1) and not(rx_start_of_frame(2)) and rx_end_of_frame(2);

        Bus2_adc0(13 downto 6) <= byte2_adc0;
        Bus2_adc0(5 downto 0) <= byte3_adc0(7 downto 2); --(1 : 0) tail
        valid2_adc0 <= rx_start_of_frame(2) and not(rx_start_of_frame(3)) and rx_end_of_frame(3);

        Bus2_adc1(13 downto 6) <= byte2_adc1;
        Bus2_adc1(5  downto 0) <= byte3_adc1(7 downto 2); --(1 : 0) tail
        valid2_adc1 <= rx_start_of_frame(2) and not(rx_start_of_frame(3)) and rx_end_of_frame(3);


        en_buff_adc0 <= enable and rx_start_of_frame(3);
buffer_adc0: reg  generic map (N=> 8)
                    port map(clk=>clk, reset=>pos_rst, enable => en_buff_adc0, d_in =>byte3_adc0, q_out => byte3_adc0_1);


        Bus3_adc0(13 downto 6) <= byte3_adc0_1;
        Bus3_adc0(5  downto 0) <= byte0_adc0(7  downto 2); --(1 : 0) tail
        valid3_adc0 <=  rx_end_of_frame(0);

        en_buff_adc1 <= enable and rx_start_of_frame(3);
buffer_adc1: reg  generic map (N=> 8)
                    port map(clk=>clk, reset=>pos_rst, enable => en_buff_adc1, d_in =>byte3_adc1, q_out => byte3_adc1_1);


        Bus3_adc1(13 downto 6) <= byte3_adc1_1;
        Bus3_adc1(5  downto 0) <= byte0_adc1(7  downto 2); --(1 : 0) tail
        valid3_adc1 <=  rx_end_of_frame(0);




frame_buffer: reg generic map (N => 4)
                  port map(clk=>clk, reset => pos_rst, enable=>enable, d_in=>frame, q_out=> frame_1);
                 
frame_mux : mux generic map(N=> 4)
                port map(A=>frame_1, B=>rx_start_of_multiframe, sel=>sel_frame, Y=> current_frame);
            
            sel_frame <= rx_start_of_multiframe(0) or rx_start_of_multiframe(1) or rx_start_of_multiframe(2) or rx_start_of_multiframe(3); 


frame_process_adc0: process(rst_n,enable, rx_start_of_frame , current_frame, rx_end_of_multiframe, Bus0_adc0, valid0_adc0,
                            Bus1_adc0, valid1_adc0, Bus2_adc0, valid2_adc0, Bus3_adc0, valid3_adc0)
                            begin
                                --reset active low
                                if rst_n = '0' then 
                                    valid0 <= '0';
                                    fifo_line0 <= (others=> '0');
                                    valid1 <= '0';
                                    fifo_line1 <= (others=>'0');
                                    frame <= (others=>'0');

                                else
                                    if enable = '1' then
                                        if( current_frame(0) = '1' and rx_start_of_frame(0) = '1'  and valid0_adc0 = '1')  then
                                            valid0 <= '1';
                                            fifo_line0 <= Bus0_adc0;
                                            if(current_frame(0) = '1' and rx_start_of_frame(2) = '1' and valid2_adc0= '1') then
                                                valid1 <='1';
                                                fifo_line1 <= Bus2_adc0;
                                                frame <= "0001";
                                            elsif(current_frame(0) = '1' and rx_start_of_frame(3) = '1' ) then
                                                valid1 <= '0';
                                                fifo_line1 <= (others=>'0');
                                                frame <= "1000";--valid3 is supposed to be high next cycle
                                            else 
                                                valid1 <= '0';
                                                fifo_line1 <= (others=>'0');
                                                frame <= "0100";
                                            end if;


                                        elsif(current_frame(1) = '1' and rx_start_of_frame(1) = '1' and valid1_adc0 = '1' ) then
                                            if (rx_end_of_multiframe(0) = '1') then
                                                valid0 <= '1';
                                                fifo_line0 <= Bus3_adc0;
                                                valid1 <= '1';
                                                fifo_line1 <= Bus1_adc0;
                                            else 
                                                valid0 <= '1';
                                                fifo_line0 <= Bus1_adc0;
                                                valid1 <= '0';
                                                fifo_line1 <= (others=>'0');
                                            end if;
                                                --if(current_frame(1) = '1' and rx_start_of_frame(3) = '1') then
                                                --    frame <= "1000";
                                                --else
                                                --    frame <= "1000";
                                                --end if;
                                                
                                            frame <= "1000"; --they all collapse in the same state but valid3 can be low or high
                                        
                                        
                                        elsif (current_frame(2) = '1' ) then
                                            if(rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '0' and rx_start_of_frame(2) = '1' and valid2_adc0 = '1') then
                                                valid0 <= '1';
                                                fifo_line0 <= Bus2_adc0;
                                                if(rx_start_of_frame(0) = '1' and valid0_adc0 = '1') then
                                                    valid1 <= '1';
                                                    fifo_line1 <= Bus0_adc0;
                                                    frame <= "0100";
                                                else
                                                    valid1 <= '0';
                                                    fifo_line1 <=  (others=>'0');
                                                    frame <= "0001";
                                                end if;
                                            elsif (rx_end_of_multiframe(0) = '1' and rx_end_of_multiframe(1) = '0') then
                                                valid0 <= '1';
                                                fifo_line0 <= Bus3_adc0;
                                                if(rx_start_of_frame(2) = '1' and valid2_adc0 = '1') then
                                                    valid1 <= '1';
                                                    fifo_line1 <= Bus2_adc0;
                                                    frame<="0001";
                                                else --you should never enter this state
                                                    valid1 <= '0';
                                                    fifo_line1 <=  (others=>'0');
                                                    frame <= "0100";
                                                end if;
                                            elsif (rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '1')  then
                                                valid0 <= '1';
                                                fifo_line0 <= Bus0_adc0;
                                                if(rx_start_of_frame(2) = '1' and valid2_adc0 = '1') then
                                                    valid1 <= '1';
                                                    fifo_line1 <= Bus2_adc0;
                                                    frame <= "0001";
                                                else --you should never enter this state
                                                    valid1 <= '0';
                                                    fifo_line1 <=  (others=>'0');
                                                    frame <= "0100";
                                                end if;
                                            
                                                else
                                                    valid0 <= '0';
                                                    fifo_line0 <=  (others=>'0');
                                                    fifo_line1 <=  (others=>'0');
                                                    valid1 <= '0';
                                                    frame <= "0100";
                                            end if;


                                        elsif (current_frame(3) = '1' ) then
                                            if(rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '0' and rx_end_of_multiframe(2) = '0') then
                                                if (valid3_adc0 = '1') then
                                                    valid0 <= '1';
                                                    fifo_line0 <= Bus3_adc0;
                                                    if (rx_start_of_frame(1) = '1' and valid1_adc0 = '1') then
                                                        valid1 <= '1';
                                                        fifo_line1 <= Bus1_adc0;
                                                        frame <= "1000";
                                                    elsif(rx_start_of_frame(2) = '1' and valid2_adc0 = '1') then
                                                        valid1 <= '1';
                                                        fifo_line1 <= Bus2_adc0;
                                                        frame <= "0001";
                                                    else
                                                        valid1 <= '0';
                                                        fifo_line1 <= (others=>'0');
                                                        frame <= "0010";
                                                    end if;
                                                else
                                                        valid0 <= '0';
                                                        fifo_line0 <= (others=>'0');
                                                        valid1 <= '0';
                                                        fifo_line1 <= (others=>'0');
                                                        frame <= "1000";
                                                end if;
                                            
                                            elsif (rx_end_of_multiframe(0) = '1' and rx_end_of_multiframe(1) = '0' and rx_end_of_multiframe(2) = '0' and valid3_adc0 = '1') then
                                                valid0 <='1';
                                                fifo_line0 <= Bus3_adc0;
                                                if (rx_start_of_frame(1) = '1' and valid1_adc0 = '1') then
                                                    valid1 <= '1';
                                                    fifo_line1 <= Bus1_adc0;
                                                    frame <= "1000";
                                                elsif(rx_start_of_frame(2) = '1' and valid2_adc0 = '1') then
                                                    valid1 <= '1';
                                                    fifo_line1 <= Bus2_adc0;
                                                    frame <= "0001";
                                                else
                                                    valid1 <= '0';
                                                    fifo_line1 <= (others=>'0');
                                                    frame <= "0010";
                                                end if;
                                            
                                            elsif (rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '1' and rx_end_of_multiframe(2) = '0' and valid0_adc0 = '1') then
                                                valid0 <= '1';
                                                fifo_line0 <=  Bus0_adc0;
                                                frame <= "1000";
                                                valid1 <= '0';
                                                fifo_line1 <= (others=>'0');
                                            elsif (rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '0' and rx_end_of_multiframe(2) = '1' and valid1_adc0 = '1') then
                                                valid0 <= '1';
                                                fifo_line0 <= Bus1_adc0;
                                                if(valid3_adc0 = '1') then
                                                    valid1 <= '1';
                                                    fifo_line1 <= Bus3_adc0;
                                                    frame <= "0010";
                                                else
                                                    valid1 <= '0';
                                                    fifo_line1 <=  (others=>'0');
                                                    frame <= "1000";
                                                end if;
                                            else -- you should never enter this state
                                                valid0 <= '0';
                                                fifo_line0 <= (others=>'0');
                                                valid1 <= '0';
                                                fifo_line1 <= (others=>'0');
                                                frame <= "1000";    
                                            end if;
                                        
                                        
                                        
                                        else
                                            valid0 <= '0';
                                            valid1 <= '0';
                                            fifo_line0 <= (others=>'0');
                                            fifo_line1 <= (others=>'0');
                                            frame <= "0000";
                                        end if;
                                    end if;
                                end if;

                            end process;






frame_process_adc1: process(rst_n,enable, rx_start_of_frame , current_frame, rx_end_of_multiframe, Bus0_adc1, valid0_adc1,
                            Bus1_adc1, valid1_adc1, Bus2_adc1, valid2_adc1, Bus3_adc1, valid3_adc1)
                            begin
                                --reset active low
                                if rst_n = '0' then 
                                    valid2 <= '0';
                                    fifo_line2 <= (others=> '0');
                                    valid3 <= '0';
                                    fifo_line2 <= (others=>'0');

                                else
                                    if enable = '1' then
                                        if( current_frame(0) = '1' and rx_start_of_frame(0) = '1'  and valid0_adc1 = '1')  then
                                            valid2 <= '1';
                                            fifo_line2 <= Bus0_adc1;
                                            if(current_frame(0) = '1' and rx_start_of_frame(2) = '1' and valid2_adc1= '1') then
                                                valid3 <='1';
                                                fifo_line3 <= Bus2_adc1;
                                            elsif(current_frame(0) = '1' and rx_start_of_frame(3) = '1' ) then
                                                valid3 <= '0';
                                                fifo_line3 <= (others=>'0');
                                                --frame <= "1000";--valid3 is supposed to be high next cycle
                                            else 
                                                valid3 <= '0';
                                                fifo_line3 <= (others=>'0');
                                                --frame <= "0100";
                                            end if;


                                        elsif(current_frame(1) = '1' and rx_start_of_frame(1) = '1' and valid1_adc1 = '1' ) then
                                            if (rx_end_of_multiframe(0) = '1') then
                                                valid2 <= '1';
                                                fifo_line2 <= Bus3_adc1;
                                                valid3 <= '1';
                                                fifo_line3 <= Bus1_adc1;
                                            else 
                                                valid2 <= '1';
                                                fifo_line2 <= Bus1_adc1;
                                                valid3 <= '0';
                                                fifo_line3 <= (others=>'0');
                                            end if;
                                                --if(current_frame(1) = '1' and rx_start_of_frame(3) = '1') then
                                                --    frame <= "1000";
                                                --else
                                                --    frame <= "1000";
                                                --end if;
                                                
                                            --frame <= "1000"; --they all collapse in the same state but valid3 can be low or high
                                        
                                        
                                        elsif (current_frame(2) = '1' ) then
                                            if(rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '0' and rx_start_of_frame(2) = '1' and valid2_adc1 = '1') then
                                                valid2 <= '1';
                                                fifo_line2 <= Bus2_adc1;
                                                if(rx_start_of_frame(0) = '1' and valid0_adc1 = '1') then
                                                    valid3 <= '1';
                                                    fifo_line3 <= Bus0_adc1;
                                                    --frame <= "0100";
                                                else
                                                    valid3 <= '0';
                                                    fifo_line3 <=  (others=>'0');
                                                    --frame <= "0001";
                                                end if;
                                            elsif (rx_end_of_multiframe(0) = '1' and rx_end_of_multiframe(1) = '0') then
                                                valid2 <= '1';
                                                fifo_line2 <= Bus3_adc1;
                                                if(rx_start_of_frame(2) = '1' and valid2_adc1 = '1') then
                                                    valid3 <= '1';
                                                    fifo_line3 <= Bus2_adc1;
                                                    --frame<="0001";
                                                else --you should never enter this state
                                                    valid3 <= '0';
                                                    fifo_line3 <=  (others=>'0');
                                                    --frame <= "0100";
                                                end if;
                                            elsif (rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '1')  then
                                                valid2 <= '1';
                                                fifo_line2 <= Bus0_adc1;
                                                if(rx_start_of_frame(2) = '1' and valid2_adc1 = '1') then
                                                    valid3 <= '1';
                                                    fifo_line3 <= Bus2_adc1;
                                                    --frame <= "0001";
                                                else --you should never enter this state
                                                    valid3 <= '0';
                                                    fifo_line3 <=  (others=>'0');
                                                    --frame <= "0100";
                                                end if;
                                            
                                                else
                                                    valid2 <= '0';
                                                    fifo_line2 <=  (others=>'0');
                                                    fifo_line3 <=  (others=>'0');
                                                    valid3 <= '0';
                                                    --frame <= "0100";
                                            end if;


                                        elsif (current_frame(3) = '1' ) then
                                            if(rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '0' and rx_end_of_multiframe(2) = '0') then
                                                if (valid3_adc1 = '1') then
                                                    valid2 <= '1';
                                                    fifo_line2 <= Bus3_adc1;
                                                    if (rx_start_of_frame(1) = '1' and valid1_adc1 = '1') then
                                                        valid3 <= '1';
                                                        fifo_line3 <= Bus1_adc1;
                                                        --frame <= "1000";
                                                    elsif(rx_start_of_frame(2) = '1' and valid2_adc1 = '1') then
                                                        valid3 <= '1';
                                                        fifo_line3 <= Bus2_adc1;
                                                        --frame <= "0001";
                                                    else
                                                        valid3 <= '0';
                                                        fifo_line3 <= (others=>'0');
                                                        --frame <= "0010";
                                                    end if;
                                                else
                                                        valid2 <= '0';
                                                        fifo_line2 <= (others=>'0');
                                                        valid3 <= '0';
                                                        fifo_line3 <= (others=>'0');
                                                        --frame <= "1000";
                                                end if;
                                            
                                            elsif (rx_end_of_multiframe(0) = '1' and rx_end_of_multiframe(1) = '0' and rx_end_of_multiframe(2) = '0' and valid3_adc1 = '1') then
                                                valid2 <='1';
                                                fifo_line2 <= Bus3_adc1;
                                                if (rx_start_of_frame(1) = '1' and valid1_adc1 = '1') then
                                                    valid3 <= '1';
                                                    fifo_line3 <= Bus1_adc1;
                                                    --frame <= "1000";
                                                elsif(rx_start_of_frame(2) = '1' and valid2_adc1 = '1') then
                                                    valid3 <= '1';
                                                    fifo_line3 <= Bus2_adc1;
                                                    --frame <= "0001";
                                                else
                                                    valid3 <= '0';
                                                    fifo_line3 <= (others=>'0');
                                                    --frame <= "0010";
                                                end if;
                                            
                                            elsif (rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '1' and rx_end_of_multiframe(2) = '0' and valid0_adc1 = '1') then
                                                valid2 <= '1';
                                                fifo_line2 <=  Bus0_adc1;
                                                --frame <= "1000";
                                                valid3 <= '0';
                                                fifo_line3 <= (others=>'0');
                                            elsif (rx_end_of_multiframe(0) = '0' and rx_end_of_multiframe(1) = '0' and rx_end_of_multiframe(2) = '1' and valid1_adc1 = '1') then
                                                valid2 <= '1';
                                                fifo_line2 <= Bus1_adc1;
                                                if(valid3_adc1 = '1') then
                                                    valid3 <= '1';
                                                    fifo_line3 <= Bus3_adc1;
                                                    --frame <= "0010";
                                                else
                                                    valid3 <= '0';
                                                    fifo_line3 <=  (others=>'0');
                                                    --frame <= "1000";
                                                end if;
                                            else -- you should never enter this state
                                                valid2 <= '0';
                                                fifo_line2 <= (others=>'0');
                                                valid3 <= '0';
                                                fifo_line3 <= (others=>'0');
                                                --frame <= "1000";    
                                            end if;
                                        
                                        
                                        
                                        else
                                            valid2 <= '0';
                                            valid3 <= '0';
                                            fifo_line2 <= (others=>'0');
                                            fifo_line3 <= (others=>'0');
                                            --frame <= "0000";
                                        end if;
                                    end if;
                                end if;

                            end process;

end structural;