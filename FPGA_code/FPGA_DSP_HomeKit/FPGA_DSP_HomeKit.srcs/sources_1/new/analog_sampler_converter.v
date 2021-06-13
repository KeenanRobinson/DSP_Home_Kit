`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Cape Town
// Engineer: Keenan Robinson
// Supervisor: Dr Simon Winberg
// 
// Create Date: 01.06.2021 10:36:24
// Design Name: 
// Module Name: analog_sampler_converter
// Project Name: DSP@Home Kit
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2018.3
// Description: 
// This module acts as an analog sampling interface, recording multibit signals at the
// rate of the sample_clock input.  The read signal is stored in a register before 
// it is then written to the memory buffer provided by the sampling channel
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module analog_sampler_converter(
    input wire clk_100MHz,
    input wire reset,
    input wire clk_sampling,
    input wire samplingEnable,
    output reg writeEnable,
    output wire [15:0] output_data_stream,
    //AD2 Pmod: these connections need to go to the top module
    inout wire scl,
    inout wire sda,
    output wire [11:0] fromI2C
    //DEBUGGING
    //output wire w_cState
);
//Internal registers
reg r_samplingEnable        = 0;
reg r_reset                 = 0;
reg [15:0] data_reg         = 16'b0;    //Stores the data coming from the peripheral
reg prevSampleClock         = 0;        //Part of detecting the rising edge of the sampling clock,
                                        //configured like this to enable pulsing the FIFO

//ADC Pmod connections
reg [1:0] clk_divider=0;
wire clk_50MHz;
assign clk_50MHz = clk_divider[1]; //Produces a 50MHz clock required
wire i2c_ack_err;
wire [11:0] adc_output_ch0;
wire reset_n;
assign reset_n = ~r_reset;

//Internal States
parameter IDLE    = 1'b0;
parameter SAMPLE  = 1'b1;
reg cState = IDLE;

//Module instantiation
pmod_adc_ad7991 ADC (
    .clk(clk_50MHz),
    .reset_n(reset_n),
    .scl(scl),
    .sda(sda),
    .i2c_ack_err(i2c_ack_err),
    .adc_ch0_data(adc_output_ch0),
    .adc_ch1_data(),
    .adc_ch2_data(),
    .adc_ch3_data()
);
assign fromI2C = adc_output_ch0;
//Populate internal registers
always@(posedge clk_100MHz) begin
    r_reset         <= reset;
    r_samplingEnable<= samplingEnable;
end

//Produce 50MHz clock for the AD2 Pmod
always@(posedge clk_100MHz) begin
    clk_divider <= clk_divider+1;
end

always@(posedge clk_100MHz) begin
    prevSampleClock <= clk_sampling; //note on this clock edge, the two are still different.
    if(r_reset) begin
        cState <= IDLE;
        data_reg <= 0;
    end
    else begin
        case(cState)
            IDLE: begin
                writeEnable <= 0; //Causes writeEnable to be a single pulse
                if(r_samplingEnable && (prevSampleClock  == 0) && clk_sampling) begin //on rising edge of clk_sampling, while requested to sample
                   cState <= SAMPLE; 
                   data_reg <= {4'b0000, adc_output_ch0}; //Concatenate to form a 16-bit word
                end
                else begin
                    cState <= IDLE;
                end
            end
            SAMPLE: begin //Redefine this logic to allow for the correct sampling format.
                    writeEnable <= 1;   //cause a write pulse, whatever is on output_data_stream is written to memory buffer
                    cState <= IDLE;
            end
        endcase
    end
end

assign output_data_stream = data_reg;
//assign w_cState = cState;

endmodule
