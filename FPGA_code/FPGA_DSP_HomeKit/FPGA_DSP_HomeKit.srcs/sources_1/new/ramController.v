`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.05.2021 15:27:55
// Design Name: 
// Module Name: newRamController
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


module ramController(
    //Control interface
    input   wire i_clk,             //100MHz clock
    input   wire i_rst,             //Active high reset
    input   wire i_startRam,        //Starts transaction pulse
    input   wire i_read,            //Start read transaction
    input   wire i_write,           //Start read transaction
    input   wire [26:0] i_addr,     //Memory address
    input   wire [15:0] i_data,     //Data to write to RAM
    output  reg [15:0] o_data,      //Data read from RAM
    //output  reg  o_readAck,         //Flag indicating busy reading/writing
    //output  reg  o_writeAck,        //Flag indicating busy reading/writing
    //output  reg o_startRamAck,
    output  reg o_ramBusy, 
    //output  reg [3:0] cState,
    //output  wire o_debugging,     //just to test something
    
    //RAM Memory signals
    output  reg  [26:0] ram_addr,
    output  reg  [15:0] ram_dq_i,
    input   wire [15:0] ram_dq_o,
    output  reg ram_cen,            //RAM chip enable
    output  reg ram_oen,            //RAM output enable
    output  reg ram_wen,            //RAM write enable
    output  reg ram_ub = 0,             //RAM upper byte select
    output  reg ram_lb = 0               //RAM lower byte select
);

//////////////////////////////////////////////////////////////////////////////////
//////              Local declarations
//////////////////////////////////////////////////////////////////////////////////

//States
parameter IDLE      = 4'b0000; //0
parameter ASSERT    = 4'b0001; //1
parameter WAIT      = 4'b0010; //2
parameter DEASSERT  = 4'b0011; //3
parameter ACK       = 4'b0100; //4
parameter DONE      = 4'b0101; //5
reg [3:0] cState    = IDLE;        //current state
reg [3:0] nState    = IDLE;        //next state   

//Internal registers
reg r_read;                     //Stored read transaction at the start of transaction
reg r_write;                    //Stored write transaction at the start of transaction
reg [26:0] r_addr;                     //Stored addrress transaction at the start of transaction
reg [15:0] r_data2Write;               //Data at start of the write operation
reg [15:0] r_dataRead;
reg r_reset;
reg [4:0] r_delayCounter=0;

//////////////////////////////////////////////////////////////////////////////////
//////              Module Behaviour
//////////////////////////////////////////////////////////////////////////////////

//****Read inputs
//When IDLE, store values in input registers.
//NOTE: on the posedge of when i_start will the data to be
// read into the RAM. So in other modules, set this will
// capture the data to be written or to write to. 
always@(posedge i_clk) begin 
    if(cState == IDLE) begin
        r_read <= i_read;
        r_write <= i_write;
        r_addr <= i_addr;
        r_data2Write <= i_data;
        r_reset <= i_rst;       
    end
end

//****Start the state machine, causing state transitions

//****State machine transisition handling
always@(posedge i_clk) begin
    if(r_reset) begin
        cState <= IDLE;
        o_ramBusy <= 0;
    end
    case(cState) 
        IDLE: begin
            if(i_startRam) begin
                cState <= ASSERT;
                //o_startRamAck <= 1;
                o_ramBusy <= 1;
            end
            else cState <= IDLE;
        end
        ASSERT: begin
            cState <= WAIT;
        end
        WAIT: begin
            if(r_delayCounter >= 26) cState <= DEASSERT; //Delays for this long to ensure read/write
        end
        DEASSERT: begin
            cState <= ACK;
        end
        ACK: begin
            cState <= DONE;
            o_ramBusy <= 0;
        end
        DONE: begin
            if(i_startRam == 0) cState <= IDLE;
        end
    endcase
end

//****Delay counter for WAIT
always@(posedge i_clk) begin
    if(cState == WAIT) r_delayCounter <= r_delayCounter+1;
    else r_delayCounter <= 0;
end

//****Assert the transaction
always@(posedge i_clk) begin
    if((cState == WAIT) || (cState == DEASSERT)) begin
        if(r_read && (r_write == 0 )) begin //Read transaction
            ram_cen <= 0;
            ram_oen <= 0;
            ram_wen <= 1;    
        end
        else if (r_write && (r_read == 0 )) begin //Write transaction
            ram_cen <= 0;
            ram_oen <= 1; 
            ram_wen <= 0;
        end
    end
    else begin
        ram_cen <= 1;
        ram_oen <= 1; 
        ram_wen <= 1;
    end
end

//****Assign the address for read and write
always@(posedge i_clk) begin
    if(r_reset) ram_addr <= 0; //Reset RAM address to zero
    else if ((cState==ASSERT) || (cState==WAIT) || (cState==DEASSERT)) begin
        ram_addr <= r_addr; 
    end
end
    
//****Assign data to write to RAM
always@(posedge i_clk) begin
    if((cState==ASSERT) || (cState==WAIT) || (cState==DEASSERT)) begin
        ram_dq_i <= r_data2Write;
    end
    else ram_dq_i <= 0;
end

//****Read data from RAM
always@(posedge i_clk) begin
    if(r_reset) r_dataRead <= 0;
    else if (cState == DEASSERT) r_dataRead <= ram_dq_o;
end

//****Output data on the line to be received by top module
always@(posedge i_clk) begin
    if(cState == ACK) begin
        o_data <= r_dataRead;
    end
end

//****Send out data acknowledge
always@(posedge i_clk) begin
    if(cState == ACK) begin 
        /*if(r_read && (r_write == 0)) begin //Read transaction
            o_readAck   <= 1;
            o_writeAck  <= 0;   
        end
        else if (r_write && (r_read == 0 )) begin //Write transaction
            o_writeAck  <= 1;
            o_readAck   <= 0;
        end
    end
    else begin
        o_writeAck  <= 0;
        o_readAck   <= 0;
    end*/
    end
end

endmodule


