`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2021 08:54:15
// Design Name: 
// Module Name: sampling_channel_tb
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
`define clk_period 10

module sampling_channel_tb;

parameter NO_OF_SAMPLES = 2;   //Default number of samples
parameter CLK_DIV       = 50;   //Configurable parameter to adjust the clock divider
parameter DATA_WIDTH    = 16;   // RAM data width
parameter DATA_DEPTH    = 2;    // Number of 16-bit data entries
parameter ADDRESS_SIZE  = 2;    // Address size 
parameter ALMOST_EMPTY_THRESH = 5;          // Threshold for almost empty flag
parameter ALMOST_FULL_THRESH = 10;          // Threshold for almost full flag

//Inputs
reg clk;
reg reset;
//  sampling_controller inputs:
reg channelEnable;           
reg trigger;
//memory buffer inputs:
reg write_data;                      // From the input interface
reg read_data;                      // From parallel port/memory controller
reg [15:0] input_data_stream;       // From the input interface 
//Outputs
wire [15:0] output_data_stream;
//  sampling_controller ouputs
wire done;                   
wire sampleClock;                //Output from the sampling controller
wire samplingEnable;
//  Fifo outputs                 
wire fifo_full;
wire fifo_empty;
// 

sampling_Channel #(
    .NO_OF_SAMPLES(NO_OF_SAMPLES),    
    .CLK_DIV(CLK_DIV),       
    .DATA_WIDTH(DATA_WIDTH),    
    .DATA_DEPTH(DATA_DEPTH),    
    .ADDRESS_SIZE(ADDRESS_SIZE),  
    .ALMOST_EMPTY_THRESH(ALMOST_EMPTY_THRESH), 
    .ALMOST_FULL_THRESH(ALMOST_FULL_THRESH ) 
) 
uut(
    .clk(clk),
    .reset(reset),
    //  sampling_controller inputs:
    //.channelEnable(channelEnable),           
    .trigger(trigger),
    //memory buffer inputs:
    .write_data(write_data),                    // From the input interface
    .read_data(read_data),                      // From parallel port/memory controller
    .input_data_stream(input_data_stream),      // From the input interface 
    //Outputs
    .output_data_stream(output_data_stream),
    //  sampling_controller ouputs
    .done(done),                   
    .sampleClock(sampleClock),                //Output from the sampling controller
    .samplingEnable(samplingEnable),
    //  Fifo outputs                 
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty)
);

always#(`clk_period/2) clk = ~clk;
integer k = 0;

initial begin
    clk                 = 0;
    reset               = 1;
    //channelEnable       = 0;
    trigger             = 0;
    write_data          = 0;
    read_data           = 0;
    input_data_stream   = 255;
    
    #`clk_period;
    reset               = 0;    //Reset = 0, ready for data sampling
    //channelEnable       = 0;
    trigger             = 0;
    write_data          = 0;
    read_data           = 0;
    //input_data_stream   = 0;
    
    #`clk_period;
    //channelEnable       = 1;
    trigger             = 1;
    write_data          = 0;
    read_data           = 0;
    //input_data_stream   = 0;
    
    for(k = 0; k< 53; k = k+1) #`clk_period;
    #5; //half a clock cycle
    write_data          = 1;
    #`clk_period;
 
    write_data          = 0;
    #`clk_period;

    read_data           = 1;
    #`clk_period;

    read_data           = 0;
    
    for(k = 0; k< 106; k = k+1) #`clk_period; //delay until next sampling clock edge
    input_data_stream   = 128;
    #`clk_period;
    #`clk_period;
    write_data          = 1;
    #`clk_period;
 
    write_data          = 0;
    #`clk_period;

    read_data           = 1;
    #`clk_period;

    read_data           = 0;
    
end

endmodule




