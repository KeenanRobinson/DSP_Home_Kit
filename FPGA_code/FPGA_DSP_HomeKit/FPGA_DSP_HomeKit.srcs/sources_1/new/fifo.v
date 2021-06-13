`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Univeristy of Cape Town
// Created by: Keenan Robinson
// Supervised by: Dr Simon Winberg
// 
// Create Date: 15.05.2021 16:11:17
// Design Name: 
// Module Name: fifo_memory
// Project Name: DSP@Home Kit_EEE4022F
// Target Devices: Nexys A7 100T
// Tool Versions: 
// Description: 
// FIFO module using an instantiated BRAM unit
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - fifo_36KB File Created
// Revision 1.0  - fifo_memory File Created 
//               - Touched up the file, removed unnecessary code  
//
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Code sources used as reference:
// https://www.nandland.com/vhdl/modules/module-fifo-regs-with-flags.html
// https://embeddedthoughts.com/2016/07/13/fifo-buffer-using-block-ram-on-a-xilinx-spartan-3-fpga/

module fifo
    // Calculated from 12bits/36864 bits available = 3072
    //I/O ports used
(
    input wire i_clk,                                   //Input clock
    input wire i_rst,                                   //Read reset. Not used, just for inference.
    input wire i_write,                                 //For starting write
    input wire i_read,                                  //For starting read
    input wire [DATA_WIDTH-1:0] i_write_data,           //Data to be written in
    output reg o_almost_empty, o_almost_full,           //Flags for data bursting
    output reg o_empty, o_full,                         //Flags for signalling stop read or write
    output wire [DATA_WIDTH-1:0] o_read_data            //Data to be read from memory. o_write_data not used, just for inference
    //output wire [ADDRESS_SIZE-1:0] o_fifo_count,      //FOR TESTBENCH TEST DEBUGGING
    //output wire [ADDRESS_SIZE-1:0] o_wr_addr,         //FOR TESTBENCH TEST DEBUGGING
    //output wire [ADDRESS_SIZE-1:0] o_rd_addr          //FOR TESTBENCH TEST DEBUGGING
);
parameter DATA_WIDTH = 16;                  // RAM data width
parameter DATA_DEPTH = 16;                  // Number of data entries
parameter ADDRESS_SIZE = 4;                // Address size 
parameter ALMOST_EMPTY_THRESH = 5;          // Threshold for almost empty flag
parameter ALMOST_FULL_THRESH = 10;          // Threshold for almost full flag
//Internal register/signal declarations
reg [ADDRESS_SIZE-1:0] r_write_addr =0; //Holds the address for write position
reg [ADDRESS_SIZE-1:0] r_read_addr=0;   //Holds the address for read position
/*reg o_full=0; 
reg o_empty=1; 
reg o_almost_full=0; 
reg o_almost_empty=0; */
integer r_fifo_count=0;  //Determines the current FIFO size for flags
wire w_write_en, w_read_en;
    
assign w_write_en = i_write & ~o_full;  //Assigns write enable while write is high and FIFO is not full
assign w_read_en = i_read & ~o_empty;   //Assigns write enable while write is high and FIFO is not full

//Instantiate added modules:
//Creates a block RAM unit to use with the same parameters
dual_sync_ram #(.DATA_WIDTH(DATA_WIDTH), .DATA_DEPTH(DATA_DEPTH), .ADDRESS_SIZE(ADDRESS_SIZE)) BRAM(
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_write_en(w_write_en), 
    .i_read_en(w_read_en),
    .i_write_addr(r_write_addr),
    .i_read_addr(r_read_addr), 
    .i_write_data(i_write_data),
    .o_read_data(o_read_data) 
    //.o_write_data()
);

always@(posedge i_clk) begin
    if(i_rst) //If reset is high
        begin
            r_fifo_count <= 0;
            r_write_addr <= 0; 
            r_read_addr  <= 0;
            //o_empty      <= 1;   
        end
    //If ONLY a write is occuring, increase FIFO count:
    if(w_write_en && (i_read == 1'b0))
        r_fifo_count <= r_fifo_count +1;
    //else if ONLY a read is occuring, decrease FIFO count:
    else if(i_read && (w_write_en == 1'b0))
        if(r_fifo_count != 0) //When fifo is empty, do not change
            r_fifo_count <= r_fifo_count -1;
    //fifo_count is not changed when both are high
    
    //Writing
    if(w_write_en) //i_write & ~r_full
        begin
            if(r_write_addr == DATA_DEPTH-1)//Manage rollover
                begin
                    r_write_addr <= 0;
                end
            else //increase the write address pointer location
                begin
                    r_write_addr <= r_write_addr+1; 
                end
        end
    //Reading:
    if(w_read_en) //i_write & ~r_empty
        begin
            if(r_read_addr == DATA_DEPTH-1)//Manage roll-over
                begin
                    r_read_addr <= 0;
                end
            else
                begin
                    r_read_addr <= r_read_addr+1; 
                end
        end 
    //      
end //always(posedge clk ...)

always@(*) begin
    //Flags
    //Full flag
    if(r_fifo_count == DATA_DEPTH) o_full = 1'b1; //When fifo is full, output the flag
    else o_full = 1'b0;
    //Empty flag
    if(r_fifo_count == 0) o_empty = 1'b1; 
    else o_empty = 1'b0;
    //Almost full flag
    if(r_fifo_count >= ALMOST_FULL_THRESH) o_almost_full   = 1'b1; 
    else o_almost_full = 1'b0;
    //Almost empty flag
    if(r_fifo_count <= ALMOST_EMPTY_THRESH) o_almost_empty = 1'b1; 
    else o_almost_empty = 1'b0;  
end
    
endmodule