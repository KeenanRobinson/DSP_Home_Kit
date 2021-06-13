`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2021 15:26:18
// Design Name: 
// Module Name: top_test
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
//Using this module to test the interface with external circuitry for EPP communication.
//There is a lacking FIFO, which is only one register instead for testing.

module top_test(
    input wire clk,
    input wire pp_write,
    input wire pp_nDataStrobe,
    input wire pp_reset,
    input wire boardReset,
    input wire pp_nAddrStrobe,
    input wire resetDetectStrobe,     
    output wire pp_wait_inv,
    output wire pp_select_emptyFifo_inv,
    inout wire [7:0] pp_data,
    output wire [13:0] led    
);

//Internal registers
reg [15:0] r_data_from_fpga = 0; //16'b1111000000001111;
wire [7:0] w_channelSelected;
reg channel_empty = 0; //For test purpose assume there is always data available
wire data_req;
wire pp_wait;
wire pp_select_emptyFifo;
wire channelReset;
reg detectStrobe=0;
assign led [7:0] = pp_data;
assign led[8] = pp_write;
assign led[9] = pp_nDataStrobe;
assign led[10] = pp_nAddrStrobe;
assign led[11] = pp_reset;
assign led[12] = detectStrobe;
assign led[13] = boardReset;

assign pp_wait_inv = ~pp_wait; //Due to the layout of the external circuitry, pp_wait has to be inverted 
assign pp_select_emptyFifo_inv = pp_select_emptyFifo;
    
EPP_controller EPP (
    //Parallel port IO
    .clk(clk),
    .pp_write(pp_write),
    .pp_nDataStrobe(pp_nDataStrobe),
    .pp_nReset(pp_reset),
    .pp_nAddrStrobe(pp_nAddrStrobe),     
    .pp_wait(pp_wait),
    .pp_select_emptyFifo(pp_select_emptyFifo),
    .pp_data(pp_data),
    //FIFO IO
    .data_from_fpga(r_data_from_fpga),
    .channel_empty(channel_empty),
    .data_req(data_req), //Pulse signal to get the FIFO data entry
    .w_channelSelected(w_channelSelected),
    .channelReset(channelReset)
);

always@(posedge clk) begin
    if(pp_nDataStrobe==0) detectStrobe <= 1;
    if(resetDetectStrobe == 0) detectStrobe <= 0; 
end

always@(posedge pp_wait) begin
    r_data_from_fpga <= r_data_from_fpga +1;
end

endmodule
