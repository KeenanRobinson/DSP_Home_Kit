`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2021 14:08:32
// Design Name: 
// Module Name: top_ir_receiver_tb
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
`define ir_period 5000

module top_ir_receiver_tb;

//EPP side IO
reg clk;
reg pp_write;                //Pin 1 parallel port         
reg pp_nDataStrobe;          //Pin 14 parallel port
reg pp_nReset;               //Pin 16 parallel port
reg pp_nAddrStrobe;          //Pin 17 parallel port
wire pp_wait_inv;               //Pin 11 parallel port. NOTE: On PC side this will be inverted
wire pp_select_emptyFifo_inv;   //This is the output wire that indicates if 
                                //the memory buffer fifo is empty.
                                //Pin 13 parallel port. NOTE: On PC side this will be inverted
wire [7:0] pp_data;             //Pins 2-9 parallel port   
//PERIPHERAL INPUT & ADDITIONAL OUTPUTS
reg ch1_ir_input;               //Pmod input for the IR receiver circuit
wire ch1_done;                  //Assigned to an LED to indicate when the channel is full
//DEBUGGING
wire w_ch1_sampleClock;
wire w_ch1_trigger;

//Internal registers
reg [7:0] data_from_pc = 8'b11111111;    
assign pp_data = (pp_write) ? 8'bz : data_from_pc;

top_ir_receiver uut(
    .clk(clk),
    .pp_write(pp_write),                //Pin 1 parallel port         
    .pp_nDataStrobe(pp_nDataStrobe),          //Pin 14 parallel port
    .pp_nReset(pp_nReset),               //Pin 16 parallel port
    .pp_nAddrStrobe(pp_nAddrStrobe),          //Pin 17 parallel port
    .pp_wait_inv(pp_wait_inv),                //Pin 11 parallel port
    .pp_select_emptyFifo_inv(pp_select_emptyFifo_inv),    //This is the output wire that indicates if 
                                        //the memory buffer fifo is empty.
                                        //Pin 13 parallel port
    .pp_data(pp_data),           //Pins 2-9 parallel port   
    //PERIPHERAL INPUT & ADDITIONAL OUTPUTS
    .ch1_ir_input(ch1_ir_input),            //Pmod input for the IR receiver circuit
    .ch1_done(ch1_done),                //Assigned to an LED to indicate when the channel is full
    //DEBUGGING
    //.w_ch1_sampleClock(w_ch1_sampleClock),
    .w_ch1_trigger(w_ch1_trigger)
);

always#(`clk_period/2) clk = ~clk;
always#(`ir_period/2) ch1_ir_input = ~ch1_ir_input;
integer k = 0;

initial begin
    clk                 = 0;
    pp_write            = 1;               
    pp_nDataStrobe      = 1;          
    pp_nReset           = 0;                 
    pp_nAddrStrobe      = 1;            
    ch1_ir_input        = 1;
    
    //Read first data entry
    #1000 //after 1us
    pp_nReset           = 1; //Deassert reset
    #190000 //after 190 useconds
    pp_nDataStrobe      = 0; //Begin a read transaction
    
    #10000 //after 10us
    pp_nDataStrobe      = 1;
    
    #200000 //after 200 useconds
    pp_nDataStrobe      = 0; //Begin a read transaction
    
    #10000 //after 10us
    pp_nDataStrobe      = 1;
    
    //Read 2nd data entry
    #200000 //after 200 useconds
    pp_nDataStrobe      = 0; //Begin a read transaction
    
    #10000 //after 10us
    pp_nDataStrobe      = 1;
    
    #200000 //after 200 useconds
    pp_nDataStrobe      = 0; //Begin a read transaction
    
    #10000 //after 10us
    pp_nDataStrobe      = 1;
    
    
    #10000; //after 10us
    
end

endmodule
