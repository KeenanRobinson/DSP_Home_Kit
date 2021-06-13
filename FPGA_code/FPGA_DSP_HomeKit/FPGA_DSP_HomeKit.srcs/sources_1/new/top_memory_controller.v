`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2021 12:41:43
// Design Name: 
// Module Name: top_memory_controller
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


module top_memory_controller(
    input wire clk_m, //Main 100 MHZ clock from board
    //output reg [3:0] testData,
    output reg testWrite,
    output reg testRead,
    output reg [3:0] data_out_test1,
    output reg bootDone,
    output reg cenCheck,
    
    //memory signals
    output wire  [12:0] ddr2_addr,
    output wire  [2:0] ddr2_ba,
    output wire  ddr2_ras_n,
    output wire  ddr2_cas_n,
    output wire  ddr2_we_n,
    output wire  ddr2_ck_p,
    output wire  ddr2_ck_n,
    output wire  ddr2_cke,
    output wire  ddr2_cs_n,
    output wire  [1:0] ddr2_dm,
    output wire  ddr2_odt,
    inout  wire  [15:0] ddr2_dq,
    inout  wire  [1:0] ddr2_dqs_p,
    inout  wire  [1:0] ddr2_dqs_n
);

//////////////////////////////////////////////////////////////////////////////////
/////               Internal register and wire declarations
//////////////////////////////////////////////////////////////////////////////////
reg reset_n = 0;
wire reset;
assign reset = ~reset_n;

//RAM controller to RAM_DDR controller
//****************************************
wire [26:0] ram_a;
//assign mem_a[26] = 1'b0;
//assign mem_a [25:0] = (current_block<<3)+mem_bank; //Address is block*8 + banknumber
//So address cycles through 0 - 1 - 2 - 3 - 4 - 5 - 6 - 7, then current block is inremented by 1 and mem_bank goes back to 0: mem_a = 8
wire [15:0] ram_dq_i;
wire [15:0] ram_dq_o;
wire [15:0] ram_dq;
wire ram_cen;
wire ram_oen;
wire ram_wen;
wire ram_ub;
wire ram_lb;
reg [3:0] testData;
assign ram_ub = 0;
assign ram_lb = 0;

wire o_ramBusy;

//assign data_out = ram_dq_o; //JUST FOR LED TEST

//RAM controller signals
//****************************************
reg startRam =0;         //pulse to indicate a transaction
reg ramRead =0;
reg ramWrite =0;
reg [26:0] ramAddr=0;
reg [15:0] data_in;
//reg [3:0] testData = 0;
wire w_readAck;       //A pulse is returned from the RAM controller when read is completed
wire w_writeAck;      //A pulse is returned from the RAM controller when write is completed
wire [15:0] data_out;

wire clk_100;
wire clk_100MHZ;
wire clk_200MHZ;

//////////////////////////////////////////////////////////////////////////////////
/////               Clock Wizard instantiation 
//////////////////////////////////////////////////////////////////////////////////

clk_wiz_0 clk_src(
  // Clock out ports  
  .clk_out1(clk_100),
  .clk_out2(clk_200MHZ),
  // Status and control signals               
  .locked(),
 // Clock in ports
  .clk_in1(clk_m) //From the constraints file
);

//////////////////////////////////////////////////////////////////////////////////
/////               Ram2DDR_ADCX instantiation
//////////////////////////////////////////////////////////////////////////////////

ramController ramCntrl(
    //RAM interface controller
    .i_clk          (clk_100MHZ),           //100MHz clock
    .i_rst          (reset),           //Active high reset
    .i_startRam     (startRam),        //Starts a transaction
    .i_read         (ramRead),          //Start read transaction
    .i_write        (ramWrite),         //Start read transaction
    .i_addr         (ramAddr),   //Memory address
    .i_data         (data_in),   //Data to write to RAM
    .o_data         (data_out),   //Data read from RAM
    //.o_readAck      (readAck),      //Flag indicating busy reading/writing
    //.o_writeAck     (writeAck),      //Flag indicating busy reading/writing
    //.o_startRamAck  (o_startRamAck),
    .o_ramBusy      (o_ramBusy),
    
    //RAM Memory signals
    .ram_addr(ram_a),
    .ram_dq_i(ram_dq_i),
    .ram_dq_o(ram_dq_o),
    .ram_cen(ram_cen),          //RAM chip enable
    .ram_oen(ram_oen),          //RAM output enable
    .ram_wen(ram_wen),          //RAM write enable
    .ram_ub(),                  //RAM upper byte select
    .ram_lb()                   //RAM lower byte select
);

//////////////////////////////////////////////////////////////////////////////////
/////               Ram2DDR_ADCX instantiation
//////////////////////////////////////////////////////////////////////////////////

Ram2Ddr RAM(
    .clk_200MHz_i          (clk_200MHZ),
    .rst_i                 (reset_n),
    .ui_clk_o               (clk_100MHZ),
    //.device_temp_i         (),
    // RAM interface
    .ram_a                 (ram_a),
    .ram_dq_i              (ram_dq_i),
    .ram_dq_o              (ram_dq_o),
    .ram_cen               (ram_cen),
    .ram_oen               (ram_oen),
    .ram_wen               (ram_wen),
    .ram_ub                (ram_ub),
    .ram_lb                (ram_lb),
    // DDR2 interface
    .ddr2_addr             (ddr2_addr),
    .ddr2_ba               (ddr2_ba),
    .ddr2_ras_n            (ddr2_ras_n),
    .ddr2_cas_n            (ddr2_cas_n),
    .ddr2_we_n             (ddr2_we_n),
    .ddr2_ck_p             (ddr2_ck_p),
    .ddr2_ck_n             (ddr2_ck_n),
    .ddr2_cke              (ddr2_cke),
    .ddr2_cs_n             (ddr2_cs_n),
    .ddr2_dm               (ddr2_dm),
    .ddr2_odt              (ddr2_odt),
    .ddr2_dq               (ddr2_dq),
    .ddr2_dqs_p            (ddr2_dqs_p),
    .ddr2_dqs_n            (ddr2_dqs_n)
);


//////////////////////////////////////////////////////////////////////////////////
/////               Moduel behaviour
//////////////////////////////////////////////////////////////////////////////////
//Basic state machine
parameter BOOT          = 3'b000; // Due to the initial start up, there is one clock edge pulse.
parameter WRITE         = 3'b001;
parameter READ          = 3'b010;
parameter WAIT          = 3'b011; 
parameter FINISH        = 3'b100; 
parameter DELAY         = 3'b101;
parameter BEGIN_TRANS   = 3'b110;
parameter END_TRANS     = 3'b111;

reg [2:0] cState = BOOT;
//reg [2:0] nState = WRITE;
//reg delayEnable = 0;
//reg delayDone = 0;
reg [28:0] delayCounter = 0;     //Arbitrary delay interval
reg [26:0] memCount = 0;

always@(posedge(clk_100MHZ))begin
    data_out_test1 <= ram_dq_o[3:0];
end

always@(posedge(clk_100MHZ))begin
    if(ram_cen==0 && (cState != BOOT)) cenCheck <= 1;
end

always@(posedge(clk_100MHZ)) begin //delayDone, startRam, readAck, writeAck
    if(reset) begin
        cState <= BOOT;
        reset_n <= 1;
        delayCounter <= 0;
        testWrite <= 0;
        testRead <= 0;
    end
    case(cState) 
        BOOT: begin
            if(delayCounter >= 500000000) begin
                cState <= WRITE;
                delayCounter <= 0;
                bootDone <= 1;
            end
            else begin
                delayCounter <= delayCounter+1;
            end   
        end
        /*DELAY: begin
            if(delayCounter >= 26) begin
                cState <= READ;
                delayCounter <= 0;
                ramWrite <= 0;
                //delayEnable <= 0;
            end
            else begin
                delayCounter <= delayCounter+1;
            end   
        end*/
        WRITE: begin
            //startRam <= 1;
            ramWrite <= 1;
            ramAddr  <= 0;
            data_in  <= 16'b0000000000001111;
            cState <= BEGIN_TRANS;
            testWrite <= 1;
        end
        READ: begin
            //startRam <= 1;
            ramRead <= 1;
            ramAddr <= 0;
            cState <= BEGIN_TRANS;
            testRead <= 1;
        end
        BEGIN_TRANS: begin
            startRam <= 1;
            if(o_ramBusy) begin 
                startRam <= 0; 
                cState <= WAIT;
                //nState <= READ;
            end
        end
        WAIT: begin
            /*if(r_writeAck) begin
                startRam <= 0;
                ramWrite <= 0;
                cState <= READ;
                
            end
            else if(r_readAck) begin
                startRam <= 0;
                ramRead <= 0;
                cState <= FINISH;
                testData <= ram_dq_o[3:0];
                
            end
            else cState <= WAIT;*/
            if(o_ramBusy==0) begin
                /*if(ramWrite) begin
                    memCount <= memCount+1;
                end*/
                if(ramRead) begin
                    //memCount <= memCount-1;
                    if(memCount <= 1) begin
                        cState <= FINISH;
                        //data_out_test1 <= data_out[3:0];
                    end
                end
                else cState <= READ;
                ramWrite <= 0;
                ramRead <= 0;
            end
        end
        FINISH: begin
            //Do nothing
        end
    endcase
end

endmodule