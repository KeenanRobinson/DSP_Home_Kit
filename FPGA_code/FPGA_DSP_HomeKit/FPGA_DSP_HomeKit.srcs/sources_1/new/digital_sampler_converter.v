`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Cape Town
// Engineer: Keenan Robinson
// Supervisor: Dr Simon Winberg
// 
// Create Date: 01.06.2021 10:36:24
// Design Name: 
// Module Name: digital_sampler_converter
// Project Name: DSP@Home Kit
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2018.3
// Description: 
// This module acts as a digital sampling interface, recording digital signals at the
// rate of the sample_clock input. What is meant by digital sampling is that the input
// line to the periphary is only 1-bit wide. The read signal is stored in shift registers
// where a 16-bit number can then be formed to be transferred over to the sampling channel
// module memory buffer FIFO.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module digital_sampler_converter(
    input wire clk_100MHz,
    input wire reset,
    input wire clk_sampling,
    input wire samplingEnable,
    input wire inputChannel,                //Connected to the perihperal
    output reg writeEnable,
    output wire [15:0] output_data_stream
    //DEBUGGING
    //output wire w_cState
);
//Internal registers
reg r_samplingEnable        = 0;
reg r_reset                 = 0;
reg [15:0] data_reg         = 16'b0;    //Stores the data coming from the peripheral
reg [3:0]  shiftCounter     = 0;        //This count is only necessary if dealing digital samples
reg prevSampleClock         = 0;

//Internal States
parameter IDLE    = 1'b0;
parameter SAMPLE  = 1'b1;
reg cState = IDLE;

//Populate internal registers
always@(posedge clk_100MHz) begin
    r_reset         <= reset;
    r_samplingEnable<= samplingEnable;
end

//State machine
always@(posedge clk_100MHz) begin
    prevSampleClock <= clk_sampling; //note on this clock edge, the two are still different.
    if(r_reset) begin
        cState <= IDLE;
        data_reg <= 0;
        shiftCounter <= 0;
    end
    else begin
        case(cState)
            IDLE: begin
                writeEnable <= 0; //Causes writeEnable to be a single pulse
                if(r_samplingEnable && (prevSampleClock  == 0) && clk_sampling) begin //on rising edge of clk_sampling, while requested to sample
                   cState <= SAMPLE; 
                end
                else begin
                    cState <= IDLE;
                end
            end
            SAMPLE: begin //Redefine this logic to allow for the correct sampling format.
                if(shiftCounter == 4'b1111) begin
                    writeEnable <= 1;   //cause a write pulse, whatever is on output_data_stream is written to memory buffer
                    data_reg <= (data_reg <<1) | inputChannel; //Sample input channel eg. pin/peripheral, store in a shift register
                    shiftCounter <= shiftCounter+1; //increments the shiftCounter.
                end
                else begin
                    data_reg <= (data_reg <<1) | inputChannel; //Sample input channel eg. pin/peripheral, store in a shift register
                    shiftCounter <= shiftCounter+1; //increments the shiftCounter.
                end
                cState <= IDLE;
            end
        endcase
    end
end

assign output_data_stream = data_reg;
assign w_cState = cState;

endmodule
