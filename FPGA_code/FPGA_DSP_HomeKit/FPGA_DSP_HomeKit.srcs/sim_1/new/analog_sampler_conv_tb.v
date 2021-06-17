`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2021 13:57:30
// Design Name: 
// Module Name: digital_sampler_converter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define clk_100MHz_period 10
`define clk_sampling_period 100

module analog_sampler_converter_tb;

reg clk_100MHz;
reg reset;
reg clk_sampling;
reg samplingEnable;
reg inputChannel;                //Connected to the perihperal
wire writeEnable;
wire [15:0] output_data_stream;

wire scl;
wire sda;
wire [11:0] fromI2C;
//DEBUGGING
wire w_cState;
reg [11:0] testing;

analog_sampler_converter uut(
    .clk_100MHz(clk_100MHz),
    .reset(reset),
    .clk_sampling(clk_sampling),
    .samplingEnable(samplingEnable),
    .writeEnable(writeEnable),
    .output_data_stream(output_data_stream),
    //DEBUGGING
    .w_cState(w_cState),
    .testing(testing)
);

always#(`clk_100MHz_period/2) clk_100MHz = ~clk_100MHz;
always#((`clk_sampling_period/2)+5) clk_sampling = ~clk_sampling; //+5 just to align clock signals for testing

initial begin
    //Initialise clocks
    clk_100MHz = 0;
    clk_sampling = 0; 
    testing = 12'b100000000011;
    
    reset = 0;
    samplingEnable = 0;
    inputChannel = 0;
    
    #100 
    samplingEnable = 1; //Allow channel to start sampling
    inputChannel = 1;
    
    #1500 
    testing = 12'b100000011111;
    
    #1500
    inputChannel = 0;
    
    
end
endmodule
