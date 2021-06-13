//////////////////////////////////////////////////////////////////////////////////
// Company: University of Cape Town
// Student: Keenan Robinson
// Supervisor: Dr Simon Winberg
// 
// Create Date: 18.05.2021 23:45:50
// Design Name: 
// Module Name: EPP_controller
// Project Name: DSP@Home Kit_EEE4022F
// Target Devices: Nexys A7 100T
// Tool Versions: 
// Description: 
// This module handles the EPP transfer protocol between the FPGA and the host PC.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module EPP_controller(
    //Parallel port IO
    input wire clk,                     //100MHz system clock
    input wire pp_write,                //Pin 1 parallel port         
    input wire pp_nDataStrobe,          //Pin 14 parallel port
    input wire pp_nReset,               //Pin 16 parallel port
    input wire pp_nAddrStrobe,          //Pin 17 parallel port
    output wire pp_wait,                //Pin 11 parallel port
    output wire pp_select_emptyFifo,    //This is the output wire that indicates if 
                                        //the memory buffer fifo is empty.
                                        //Pin 13 parallel port
    inout wire [7:0] pp_data,           //Pins 2-9 parallel port
    
    //FPGA side IO
    //Channel memory buffer
    input wire [15:0] data_from_fpga,
    input wire channel_empty,
    output reg data_req, //Pulse signal to get the FIFO data entry
    output wire [7:0] w_channelSelected, //channel select
    output wire channelReset,           //Active high reset
    //DEBUGGING
    /*output wire [3:0] w_state, 
    output wire w_dataCount,
    output wire [7:0] w_writtenData*/
    input wire sw0,
    input wire sw1,
    input wire sw2  
);
/*Parallel port notes:
    - pp_write => LOW means WRITE (PC to FPGA). HIGH means READ (FPGA => PC)
    
*/

//Internal registers
reg [7:0] r_data_out;
reg [7:0] r_data_in;
reg [7:0] r_channelSelected = 8'b00000001; //When an address write is made, it is latched on this. Default = 1
reg [7:0] r_writtenData = 8'b0;
reg r_nDataStrobe;
reg r_nAddrStrobe;
reg r_write;    
reg r_reset;    //active low
//reg r_done;
reg r_wait;
reg r_dataCount=0; //Used to determine when to read from channel or read the next byte from 16-bit buffer
reg r_outputEnable=0;

//Tristate buffer 
assign pp_data = r_outputEnable ? r_data_out : 8'bz;
assign pp_wait = r_wait;
assign w_channelSelected = r_channelSelected;
assign pp_select_emptyFifo = channel_empty;

//Assign inputs to registers
always@(posedge clk) begin
    r_data_in <= pp_data;
    r_nDataStrobe <= pp_nDataStrobe;
    r_nAddrStrobe <= pp_nAddrStrobe;
    r_write <= pp_write;    
    r_reset <= pp_nReset;
end

// State machine
parameter [3:0] IDLE          = 4'b0000; //State 0
parameter [3:0] DATA_READ_1   = 4'b0001; //State 1: Data read cycle
parameter [3:0] DATA_READ_2   = 4'b0010; //State 2
parameter [3:0] DATA_WRITE_1  = 4'b0011; //State 3: Data write cycle
parameter [3:0] DATA_WRITE_2  = 4'b0100; //State 4
parameter [3:0] ADDR_READ_1   = 4'b0101; //State 5: Address read cycle
parameter [3:0] ADDR_READ_2   = 4'b0110; //State 6
parameter [3:0] ADDR_WRITE_1  = 4'b0111; //State 7: Address write cycle
parameter [3:0] ADDR_WRITE_2  = 4'b1000; //State 8

reg [3:0] state;    //Stores current state

assign channelReset = ~r_reset; //Resets the channel depending on the selectedChannel
//DEBUGGING - remove these when synthesizing
/*assign w_state = state;
assign w_dataCount = r_dataCount;
assign w_writtenData = r_writtenData;*/


//State machine
always@(posedge clk) begin
    if(r_reset == 1'b0) begin
        state <= IDLE;
        r_wait <= 0;
        data_req <= 0;
        r_dataCount<=0;
    end
    else begin
        case(state)
            IDLE: begin
                if      (r_nDataStrobe==1'b0 && r_write == 1'b0) state <= DATA_WRITE_1; //Writing data PC  =>FPGA
                else if (r_nDataStrobe==1'b0 && r_write == 1'b1) state <= DATA_READ_1;  //Reading data FPGA=>PC
                else if (r_nAddrStrobe==1'b0 && r_write == 1'b0) state <= ADDR_WRITE_1; //Writing addr PC  =>FPGA
                else if (r_nAddrStrobe==1'b0 && r_write == 1'b1) state <= ADDR_READ_1;  //Reading addr FPGA=>PC
                r_wait <= 0;    //reset wait to low
            end
            
            //Start: Data read cycle
            DATA_READ_1: begin
                state <= DATA_READ_2;
                r_outputEnable <= 1;    //Set data lines to OUTPUT
                if(r_dataCount == 0) data_req <= 1; //Fetch data from channel
            end
            DATA_READ_2: begin
                data_req <= 0;
                r_wait <= 1;                        //set WAIT high
                if(r_nDataStrobe) begin             //PC indicates that it has acknowledged that WAIT is HIGH
                    state <= IDLE;
                    r_dataCount <= ~r_dataCount;    //On next Data Read Cycle, read the other byte order
                    r_outputEnable <= 0;            //Set data lines to default INPUT
                    r_wait <= 0;                    //set WAIT high
                end
                if(r_dataCount == 0) r_data_out <= ~data_from_fpga[15:8];  //output the first byte, inverse here due to open collector connection
                else if(r_dataCount) r_data_out <= ~data_from_fpga[7:0]; //output the last byte, inverse here due to open collector connection
            end
            //End: Data read cycle
            
            //Start: Data write cycle
            DATA_WRITE_1: begin
                r_wait <= 1;
                if(r_nDataStrobe) state <= DATA_WRITE_2;  
            end
            DATA_WRITE_2: begin
                r_wait <= 0;
                r_writtenData <= r_data_in;  //Store the input data
                state <= IDLE;
            end
            //End: Data write cycle
            
            //Start: Address read cycle
            ADDR_READ_1: begin
                state <= ADDR_READ_2;
                r_outputEnable <= 1;
                r_wait <= 1;
                r_data_out <= r_channelSelected; //output the current channel being read from
            end
            ADDR_READ_2: begin
                if(r_nAddrStrobe) begin //PC indicates that it has acknowledged that WAIT is HIGH
                    state <= IDLE;
                    r_outputEnable <= 0;    //Set data lines to default INPUT
                    r_wait <= 0;            //set WAIT high
                end
            end
            //End: Address read cycle
            
            //Start: Address write cycle
            ADDR_WRITE_1: begin
                r_wait <= 1;
                if(r_nAddrStrobe) state <= ADDR_WRITE_2;  
            end
            ADDR_WRITE_2: begin
                state <= IDLE;
                r_wait <= 0;
                //r_channelSelected <= r_data_in;
            end
            //Start: Address write cycle
        endcase
    end
end

always@(posedge clk) begin
    if(sw1 == 0 && sw0 && sw2) r_channelSelected <= 8'b00000010;
    else if(sw2 == 0 && sw1 && sw0) r_channelSelected <= 8'b00000011;
    else r_channelSelected <= 8'b00000001;
        
end

endmodule