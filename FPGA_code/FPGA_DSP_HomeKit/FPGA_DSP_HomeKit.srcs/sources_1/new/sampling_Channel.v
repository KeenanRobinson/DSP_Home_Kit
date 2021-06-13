`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Cape Town
// Student: Keenan Robinson 
// 
// Create Date: 31.05.2021 17:50:46
// Design Name: 
// Module Name: sampling_Channel
// Project Name: DSP@Home Kit EEE4022F
// Target Devices: Nexys A7 100T
// Tool Versions:
////////////////////////////////////////////////////////////////////////////////// 
// Description: 
// This module incorporates the sampling_controller module with the memory
// buffer interface, while providing connections for the input channel and the 
// parallel port channel communication. 
// 
//////////////////////////////////////////////////////////////////////////////////
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sampling_Channel(
    //Inputs
    input wire clk,
    input wire reset,
    //  sampling_controller inputs:         
    input wire trigger,
    //input wire channelSelect,
    //memory buffer inputs:
    input wire write_data,                      // From the input interface
    input wire read_data,                       // From parallel port/memory controller
    input wire [15:0] input_data_stream,        // From the input interface 
    //Outputs
    output wire [15:0] output_data_stream,
    //  sampling_controller ouputs
    output wire done,                   
    output wire sampleClock,                //Output from the sampling controller
    output wire samplingEnable,
    //  Fifo outputs                 
    output wire fifo_full,
    output wire fifo_empty
);
//Channel parameters
parameter NO_OF_SAMPLES = 32;   //Default number of samples
parameter CLK_DIV       = 100;  //Configurable parameter to adjust the clock divider
parameter DATA_WIDTH    = 16;   // RAM data width
parameter DATA_DEPTH    = 2;    // Number of 16-bit data entries
parameter ADDRESS_SIZE  = 2;    // Address size 
parameter ALMOST_EMPTY_THRESH = 5;          // Threshold for almost empty flag
parameter ALMOST_FULL_THRESH = 10;          // Threshold for almost full flag

//Instantiate the block ram buffer/memory unit
fifo #(
    .DATA_WIDTH(DATA_WIDTH),      // RAM data width
    .DATA_DEPTH(DATA_DEPTH),      // Number of 16-bit data entries
    .ADDRESS_SIZE(ADDRESS_SIZE),    // Address size 
    .ALMOST_EMPTY_THRESH(ALMOST_EMPTY_THRESH), // Threshold for almost empty flag
    .ALMOST_FULL_THRESH(ALMOST_FULL_THRESH)    // Threshold for almost full flag
)
memory_buffer
(
    .i_clk(clk),                        //Input clock
    .i_rst(reset),                      //Read reset. Not used, just for inference.
    .i_write(write_data),               //For starting write
    .i_read(read_data),                 //For starting read
    .i_write_data(input_data_stream),   //Data to be written in
    .o_almost_empty(), 
    .o_almost_full(),                   //Flags for data bursting
    .o_empty(fifo_empty),                    
    .o_full(fifo_full),                      //Flags for signalling stop read or write
    .o_read_data(output_data_stream)            //Data to be read from memory. o_write_data not used, just for inference
);

//Instantiate the sampling_controller module
sampling_controller 
#(
    .NO_OF_SAMPLES(NO_OF_SAMPLES),
    .CLK_DIV(CLK_DIV)
) 
controller(
    .clk(clk),                     
    .reset(reset),                   
    //.channelSelect(channelSelect),           
    .trigger(trigger),                 
    .done(done),                   
    .sampleClock(sampleClock)
);

assign samplingEnable = trigger; 

endmodule
