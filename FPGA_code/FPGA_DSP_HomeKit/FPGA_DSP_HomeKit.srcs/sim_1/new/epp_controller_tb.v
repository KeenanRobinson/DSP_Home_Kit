`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2021 03:08:33
// Design Name: 
// Module Name: epp_controller_tb
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
//This test bench ensures that the EPP works as intended. Simulation to analyse the 
//parallel port behaviour
`define clk_period 10

module epp_controller_tb;

reg clk;
reg pp_write;
reg pp_nDataStrobe;
reg pp_nReset;
reg pp_nAddrStrobe;    
wire pp_wait;
wire [7:0] pp_data;
wire pp_select_emptyFifo;
    //FIFO IO
reg [15:0] data_from_fpga;
reg channel_empty;
wire data_req; //Pulse signal to get the FIFO data entry
wire [7:0] w_channelSelected;
wire channelReset;
   //DEBUGGING
//wire [3:0] w_state; 
//wire w_dataCount;
//wire w_writtenData;
reg sw0;
reg sw1;
reg sw2;

//For the inout port pp_data
reg [7:0] data_from_pc;
assign pp_data = (pp_write) ? 8'bz : data_from_pc;  //Since pp_data is driven as output from the module
                                                    // when pp_write goes high. Otherwise, pp_data is coming
                                                    // from the PC side.
EPP_controller uut(
    .clk(clk),
    .pp_write(pp_write),                //Pin 1
    .pp_nDataStrobe(pp_nDataStrobe),    //Pin 14
    .pp_nReset(pp_nReset),              //Pin 16
    .pp_nAddrStrobe(pp_nAddrStrobe),    //Pin 17
    .pp_wait(pp_wait),                  //Pin 11
    .pp_select_emptyFifo(pp_select_emptyFifo),  //Pin 13
    .pp_data(pp_data),                  //Pin 2-9
    //FIFO IO
    .data_from_fpga(data_from_fpga),
    .channel_empty(channel_empty),
    .data_req(data_req),
    .w_channelSelected(w_channelSelected), //channel select
    .channelReset(channelReset),
   //DEBUGGING
    //.w_state(w_state), 
    //.w_dataCount(w_dataCount),
    //.w_writtenData(w_writtenData)
    .sw0(sw0),
    .sw1(sw1),
    .sw2(sw2)
);

always#(`clk_period/2) clk = ~clk;

initial begin
    //Initial testbench states
    clk             = 0;
    pp_write        = 1;
    pp_nDataStrobe  = 1;
    pp_nReset       = 0; //Active low
    pp_nAddrStrobe  = 1;
    data_from_pc    = 8'b10101010; //Arbitrary value
    data_from_fpga     = 16'b0;
    channel_empty      = 1;
    sw0             = 1;
    sw1             = 1;
    sw2             = 1;
        

    #5;
    #`clk_period;
    
    pp_nReset = 1;
    #`clk_period;

//Test 0: Changing channels
//////////////////////////////////////////////////////////////////////////////////
    sw0 = 0;
    #100
    sw0 = 0;
    sw1 = 0;
    #100
    sw0 = 1;
    sw1 = 0;
    #100
    sw0 = 1;
    sw1 = 0;
    sw2 = 0;
    #100
    sw0 = 1;
    sw1 = 1;
    sw2 = 0;
    
    #1000                    //Delay by arbitrary amount
//////////////////////////////////////////////////////////////////////////////////    
    
    //Test 1: Address write
//////////////////////////////////////////////////////////////////////////////////
    pp_write = 0;           //Write operation
    pp_nAddrStrobe = 0;     //Address operation
    #100                    //Delay arbitrary amount
    pp_nAddrStrobe = 1;     //Assuming the PC acknowledges the wait signal being asserted
    
    #1000                    //Delay by arbitrary amount
//////////////////////////////////////////////////////////////////////////////////
    
    //Test 2: Address read
//////////////////////////////////////////////////////////////////////////////////
    pp_write = 1;           //Read operation
    pp_nAddrStrobe = 0;     //Address operation
    #100                    //Delay by arbitrary amount
    pp_nAddrStrobe = 1;     //Assuming the PC acknowledges the wait signal being asserted
    //Ouput should be what data_from_pc was when the address was written in Test 1,
    //which is 00001111
    
    #1000                   //Delay by arbitrary amount
//////////////////////////////////////////////////////////////////////////////////

    //Test 3: Data read (2 cycles for each byte)
//////////////////////////////////////////////////////////////////////////////////
    //Cycle 1
    data_from_fpga <= 16'b0000111111110000;
    channel_empty = 0;
    //First byte: 00001111
    //Last byte:  11110000
    pp_write = 1;           //Read operation
    pp_nDataStrobe = 0;     //Data operation
    #100                    //Delay by arbitrary amount
    pp_nDataStrobe = 1;     //Assuming the PC acknowledges the wait signal being asserted
    //There should be a pulse to the FIFO memory, dataCount should change to 1 and the data
    //should be the first byte
    
    #1000                   //Delay by arbitrary amount
    
    pp_write = 1;           //Read operation
    pp_nDataStrobe = 0;     //Data operation
    #100                    //Delay by arbitrary amount
    pp_nDataStrobe = 1;     //Assuming the PC acknowledges the wait signal being asserted
   //There should be no pulse to the FIFO memory, dataCount should change to 0 and the data
    //should be the last byte
    #1000                   //Delay by arbitrary amount
//////////////////////////////////////////////////////////////////////////////////

    //Test 4: Data write
//////////////////////////////////////////////////////////////////////////////////
    pp_write = 0;           //Write operation
    data_from_pc = 8'b01100110;
    pp_nDataStrobe = 0;     //Data operation
    #100                    //Delay arbitrary amount
    pp_nDataStrobe = 1;     //Assuming the PC acknowledges the wait signal being asserted
    //The w_writtenData bus should indicate a change to the value on data_from_pc
    #1000;                    //Delay by arbitrary amount
//////////////////////////////////////////////////////////////////////////////////

end


endmodule
