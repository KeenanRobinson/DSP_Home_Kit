`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Univeristy of Cape Town
// Created by: Keenan Robinson
// Supervised by: Dr Simon Winberg
// 
// Create Date: 04.05.2021 11:07:17
// Design Name: 
// Module Name: sync_dual_port_ram36Kb
// Project Name: DSP@Home Kit_EEE4022F
// Target Devices: Nexys A7 100T
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

module dual_sync_ram //Dual port synchronous RAM module 
    //I/O ports used
    (
        input wire i_clk,                                       //Input clock
        input wire i_rst,                                       //Read reset. Not used, just for inference.
        input wire i_write_en,                                  //For starting write
        input wire i_read_en,                                   //For starting read
        input wire [ADDRESS_SIZE-1:0] i_write_addr, i_read_addr,//Dual port address
        input wire [DATA_WIDTH-1:0] i_write_data,               //Data to be written in
        output reg [DATA_WIDTH-1:0] o_read_data 
        //output wire [DATA_WIDTH-1:0]o_write_data   //Data to be read from memory. o_write_data not used, just for inference
    ); 
    parameter DATA_WIDTH = 16;                      // RAM data width
    parameter DATA_DEPTH = 16;                      // Number of data entries
    parameter ADDRESS_SIZE = 4;                     // Address size 
    
    // Internal signal
    reg [DATA_WIDTH-1:0] memory [DATA_DEPTH-1:0];       //Creates the 36Kb memory module
    reg [ADDRESS_SIZE-1:0] r_read_addr, r_write_addr;   //For assignment later
    reg [DATA_WIDTH-1:0] r_read_data;                   //Data to be output when read enables
    //reg [DATA_WIDTH-1:0] r_read_data;                 //REGISTER OUTPUT VERSION
    
    always@(posedge i_clk)
        begin
            if(i_write_en) //If write_en = 1
                memory[i_write_addr] <= i_write_data; //Write data at write_addr
            if(i_read_en)
                o_read_data <= memory[i_read_addr];
            r_read_addr  <= i_read_addr; //Store read_addr to a register
            r_write_addr <= i_write_addr;//Store write_addr to a register        
        end
endmodule