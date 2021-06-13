--------------------------------------------------------------------------------
--
--   FileName:         pmod_adc_ad7991.vhd
--   Dependencies:     i2c_master.vhd (Version 2.2)
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 09/18/2020 Scott Larson
--     Initial Public Release
-- 
-- Source: https://forum.digikey.com/t/adc-ad7991-pmod-controller-vhdl/12895
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY pmod_adc_ad7991 IS
  GENERIC(
    sys_clk_freq : INTEGER := 50_000_000);                --input clock speed from user logic in Hz
  PORT(
    clk          : IN    STD_LOGIC;                       --system clock
    reset_n      : IN    STD_LOGIC;                       --asynchronous active-low reset
    scl          : INOUT STD_LOGIC;                       --I2C serial clock
    sda          : INOUT STD_LOGIC;                       --I2C serial data
    i2c_ack_err  : OUT   STD_LOGIC;                       --I2C slave acknowledge error flag
    adc_ch0_data : OUT   STD_LOGIC_VECTOR(11 DOWNTO 0);   --ADC Channel 0 data obtained
    adc_ch1_data : OUT   STD_LOGIC_VECTOR(11 DOWNTO 0);   --ADC Channel 1 data obtained
    adc_ch2_data : OUT   STD_LOGIC_VECTOR(11 DOWNTO 0);   --ADC Channel 2 data obtained
    adc_ch3_data : OUT   STD_LOGIC_VECTOR(11 DOWNTO 0));  --ADC Channel 3 data obtained
END pmod_adc_ad7991;

ARCHITECTURE behavior OF pmod_adc_ad7991 IS
  TYPE machine IS(start, read_data, output_result);     --needed states
  SIGNAL state        : machine;                        --state machine
  SIGNAL config       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --value to set the Sensor Configuration Register
  SIGNAL i2c_ena      : STD_LOGIC;                      --i2c enable signal
  SIGNAL i2c_addr     : STD_LOGIC_VECTOR(6 DOWNTO 0);   --i2c address signal
  SIGNAL i2c_rw       : STD_LOGIC;                      --i2c read/write command signal
  SIGNAL i2c_data_wr  : STD_LOGIC_VECTOR(7 DOWNTO 0);   --i2c write data
  SIGNAL i2c_data_rd  : STD_LOGIC_VECTOR(7 DOWNTO 0);   --i2c read data
  SIGNAL i2c_busy     : STD_LOGIC;                      --i2c busy signal
  SIGNAL busy_prev    : STD_LOGIC;                      --previous value of i2c busy signal
  SIGNAL adc_buffer_a : STD_LOGIC_VECTOR(15 DOWNTO 0);  --ADC Channel 0 data buffer
  SIGNAL adc_buffer_b : STD_LOGIC_VECTOR(15 DOWNTO 0);  --ADC Channel 1 data buffer
  SIGNAL adc_buffer_c : STD_LOGIC_VECTOR(15 DOWNTO 0);  --ADC Channel 2 data buffer
  SIGNAL adc_buffer_d : STD_LOGIC_VECTOR(15 DOWNTO 0);  --ADC Channel 3 data buffer

  COMPONENT i2c_master IS
    GENERIC(
      input_clk : INTEGER;  --input clock speed from user logic in Hz
      bus_clk   : INTEGER); --speed the i2c bus (scl) will run at in Hz
    PORT(
      clk       : IN     STD_LOGIC;                    --system clock
      reset_n   : IN     STD_LOGIC;                    --active low reset
      ena       : IN     STD_LOGIC;                    --latch in command
      addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
      rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
      data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
      busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
      data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
      ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
      sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
      scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
  END COMPONENT;

BEGIN

  --instantiate the i2c master
  i2c_master_0:  i2c_master
    GENERIC MAP(input_clk => sys_clk_freq, bus_clk => 400_000)
    PORT MAP(
        clk         => clk, 
        reset_n     => reset_n, 
        ena         => i2c_ena, 
        addr        => i2c_addr,
        rw          => i2c_rw, 
        data_wr     => i2c_data_wr, 
        busy        => i2c_busy,
        data_rd     => i2c_data_rd, 
        ack_error   => i2c_ack_err, 
        sda         => sda,
        scl         => scl
    );

  PROCESS(clk, reset_n)
    VARIABLE busy_cnt : INTEGER RANGE 0 TO 8 := 0;               --counts the busy signal transistions during one transaction
    VARIABLE counter  : INTEGER RANGE 0 TO sys_clk_freq/10 := 0; --counts 100ms to wait before communicating
  BEGIN
    IF(reset_n = '0') THEN               --reset activated
      counter := 0;                        --clear wait counter
      i2c_ena <= '0';                      --clear i2c enable
      busy_cnt := 0;                       --clear busy counter
      adc_ch0_data <= (OTHERS => '0');     --clear ADC Channel 0 result output
      adc_ch1_data <= (OTHERS => '0');     --clear ADC Channel 1 result output
      adc_ch2_data <= (OTHERS => '0');     --clear ADC Channel 2 result output
      adc_ch3_data <= (OTHERS => '0');     --clear ADC Channel 3 result output
      state <= start;                      --return to start state
    ELSIF(clk'EVENT AND clk = '1') THEN  --rising edge of system clock
      CASE state IS                        --state machine
      
        --give ADC 100ms to power up before communicating
        WHEN start =>
          IF(counter < sys_clk_freq/10) THEN   --100ms not yet reached
            counter := counter + 1;              --increment counter
          ELSE                                 --100ms reached
            counter := 0;                        --clear counter
            state <= read_data;                  --initate ADC conversions and retrieve data
          END IF;
        
        --initiate ADC conversions and retrieve data
        WHEN read_data =>
          busy_prev <= i2c_busy;                          --capture the value of the previous i2c busy signal
          IF(busy_prev = '0' AND i2c_busy = '1') THEN     --i2c busy just went high
            busy_cnt := busy_cnt + 1;                       --counts the times busy has gone from low to high during transaction
          END IF;
          CASE busy_cnt IS                                --busy_cnt keeps track of which command we are on
            WHEN 0 =>                                       --no command latched in yet
              i2c_ena <= '1';                                 --initiate the transaction
              i2c_addr <= "0101000";                          --set the address of the ADC
              i2c_rw <= '1';                                  --command 1 is a read
            WHEN 1 =>                                       --1st busy high: command 1 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 1 is ready
                adc_buffer_a(15 DOWNTO 8) <= i2c_data_rd;       --retrieve MSB data from command 1
              END IF;
            WHEN 2 =>                                       --2nd busy high: command 2 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 2 is ready
                adc_buffer_a(7 DOWNTO 0) <= i2c_data_rd;        --retrieve LSB data from command 2
              END IF;
            WHEN 3 =>                                       --3rd busy high: command 3 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 3 is ready
                adc_buffer_b(15 DOWNTO 8) <= i2c_data_rd;       --retrieve MSB data from command 3
              END IF;
            WHEN 4 =>                                       --4th busy high: command 4 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 4 is ready
                adc_buffer_b(7 DOWNTO 0) <= i2c_data_rd;        --retrieve LSB data from command 4
              END IF;
            WHEN 5 =>                                       --5th busy high: command 5 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 5 is ready
                adc_buffer_c(15 DOWNTO 8) <= i2c_data_rd;       --retrieve MSB data from command 5
              END IF;
            WHEN 6 =>                                       --6th busy high: command 6 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 6 is ready
                adc_buffer_c(7 DOWNTO 0) <= i2c_data_rd;        --retrieve LSB data from command 6
              END IF;  
            WHEN 7 =>                                       --7th busy high: command 7 latched, okay to issue command 2
              IF(i2c_busy = '0') THEN                         --indicates data read in command 7 is ready
                adc_buffer_d(15 DOWNTO 8) <= i2c_data_rd;       --retrieve MSB data from command 7
              END IF;          
            WHEN 8 =>                                       --8th busy high: command 8 latched
              i2c_ena <= '0';                                 --deassert enable to stop transaction after command 8
              IF(i2c_busy = '0') THEN                         --indicates data read in command 8 is ready
                adc_buffer_d(7 DOWNTO 0) <= i2c_data_rd;        --retrieve LSB data from command 8
                busy_cnt := 0;                                  --reset busy_cnt for next transaction
                state <= output_result;                         --output the results
              END IF;
            WHEN OTHERS => NULL;
          END CASE;

        --match received ADC data to outputs
        WHEN output_result =>
          CASE adc_buffer_a(13 DOWNTO 12) IS             --determine which channel was read first
            WHEN "00" =>                                   --first data read was channel 0
              adc_ch0_data <= adc_buffer_a(11 DOWNTO 0);     --write ADC channel 0 data to output
              adc_ch1_data <= adc_buffer_b(11 DOWNTO 0);     --write ADC channel 1 data to output
              adc_ch2_data <= adc_buffer_c(11 DOWNTO 0);     --write ADC channel 2 data to output
              adc_ch3_data <= adc_buffer_d(11 DOWNTO 0);     --write ADC channel 3 data to output
            WHEN "01" =>                                   --first data read was channel 1
              adc_ch1_data <= adc_buffer_a(11 DOWNTO 0);     --write ADC channel 1 data to output
              adc_ch2_data <= adc_buffer_b(11 DOWNTO 0);     --write ADC channel 2 data to output
              adc_ch3_data <= adc_buffer_c(11 DOWNTO 0);     --write ADC channel 3 data to output
              adc_ch0_data <= adc_buffer_d(11 DOWNTO 0);     --write ADC channel 0 data to output
            WHEN "10" =>                                   --first data read was channel 2
              adc_ch2_data <= adc_buffer_a(11 DOWNTO 0);     --write ADC channel 2 data to output
              adc_ch3_data <= adc_buffer_b(11 DOWNTO 0);     --write ADC channel 3 data to output
              adc_ch0_data <= adc_buffer_c(11 DOWNTO 0);     --write ADC channel 0 data to output
              adc_ch1_data <= adc_buffer_d(11 DOWNTO 0);     --write ADC channel 1 data to output
            WHEN "11" =>                                   --first data read was channel 3
              adc_ch3_data <= adc_buffer_a(11 DOWNTO 0);     --write ADC channel 3 data to output
              adc_ch0_data <= adc_buffer_b(11 DOWNTO 0);     --write ADC channel 0 data to output
              adc_ch1_data <= adc_buffer_c(11 DOWNTO 0);     --write ADC channel 1 data to output
              adc_ch2_data <= adc_buffer_d(11 DOWNTO 0);     --write ADC channel 2 data to output
            WHEN OTHERS => NULL;
          END CASE;       
          state <= read_data;                            --initiate next conversions and retrieve data

        --default to start state
        WHEN OTHERS =>
          state <= start;

      END CASE;
    END IF;
  END PROCESS;   
END behavior;
