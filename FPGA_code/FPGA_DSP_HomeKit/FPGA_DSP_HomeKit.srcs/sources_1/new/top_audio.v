`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Cape Town
// Student: Keenan Robinson
// Supervisor: Dr Simon Winberg
// 
// Create Date: 09.06.2021 02:15:49
// Design Name: 
// Module Name: top_ir_receiver
// Project Name: DSP@Home Kit_EEE4022F
// Target Devices: Nexys A7 100T
// Tool Versions: 
// Description: 
// This code is a top module that utilises the digital_sampler_converter as well as
// the EPP_controller module to sample the IR receiver and transmit the data over 
// the parallel port to the host PC.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_audio(
    //EPP side IO
    input wire clk,
    input wire pp_write,                //Pin 1 parallel port         
    input wire pp_nDataStrobe,          //Pin 14 parallel port
    input wire pp_nReset,               //Pin 16 parallel port
    input wire pp_nAddrStrobe,          //Pin 17 parallel port
    output wire pp_wait_inv,            //Pin 11 parallel port
    output wire pp_select_emptyFifo_inv,//This is the output wire that indicates if 
                                        //the memory buffer fifo is empty.
                                        //Pin 13 parallel port
    inout wire [7:0] pp_data,           //Pins 2-9 parallel port   
    input wire boardReset,              //Use CPU reset button in case
    //PERIPHERAL INPUT & ADDITIONAL OUTPUTS
    inout wire scl,
    inout wire sda,
    output wire ch1_done,                //Assigned to an LED to indicate when the channel is full
    //DEBUGGING WIRES - REMOVE BEFORE SYNTHESIS
    //output wire w_ch1_sampleClock,
    //output wire w_ch1_trigger
    input wire sw0,
    output wire [11:0] fromI2C
);
//Due to the layout of the external circuitry, pp_wait has to be inverted 
wire pp_wait;
wire pp_select_emptyFifo;
assign pp_wait_inv = ~pp_wait; 
assign pp_select_emptyFifo_inv = ~pp_select_emptyFifo; 

//Internal registers & wires - EPP multiplexer
reg [15:0] input_data_stream;
reg channel_empty;
wire data_req;            //EPP read request pusle to channel's FIFO buffer
wire channelReset;
wire [7:0] w_channelSelected;


/*  ADDING CHANNEL INSTRUCTION
    *****************************
To add an additional channel, copy and paste the following lines of code.
Then adjust the prefix 'ch1_' to 'ch_x' where x is the value of the desired
channel identifier. 

Note, the prefacing module should be switched out according to the user 
specifications. Channel 1 below utilises the digital_sampler_converter
for digital sampling. This should be replaced when a different module
is to be used. When doing so, ensure the necessary wires connecting the
modules are connected and properly defined.
*/

reg trigger;        //There is a single trigger for all the channels in this example
                    //As it is requested that all channels start recording at the same
                    //time
//Channel wires: (ADJUSTMENT REQUIRED FOR ADDITIONAL CHANNELS)
//********************Channel 1 Configuration********************
reg ch1_reset;
wire ch1_enable;
//reg ch1_trigger;
wire ch1_write_enable;
reg ch1_read_enable;                    //EPP controller    =>  Sampling channel Request data
wire [15:0] ch1_input_data_stream;      //Prefacing module  => sampling channel
wire [15:0] ch1_output_data_stream;     //Sampling channel  => EPP
//wire ch1_done;
wire ch1_sampleClock;
wire ch1_fifo_full;
wire ch1_fifo_empty;
wire ch1_samplingEnable;
wire [15:0] ch1_sampler_output;

//********************Channel 1 Configuration End********************


//********************Channel 1 Module instantiations********************
//////////////////////////////////////////////////////////////////////////////////
//Module instantiations
//////////////////////////////////////////////////////////////////////////////////
//EPP controller
EPP_controller EPP(
    .clk(clk),
    .pp_write(pp_write),                //Pin 1
    .pp_nDataStrobe(pp_nDataStrobe),    //Pin 14
    .pp_nReset(pp_nReset & boardReset), //Pin 16
    .pp_nAddrStrobe(pp_nAddrStrobe),    //Pin 17
    .pp_wait(pp_wait),                  //Pin 11
    .pp_select_emptyFifo(pp_select_emptyFifo),  //Pin 13
    .pp_data(pp_data),                  //Pin 2-9
    //FIFO IO
    .data_from_fpga(input_data_stream),
    .channel_empty(channel_empty),
    .data_req(data_req),
    .w_channelSelected(w_channelSelected), //channel select
    .channelReset(channelReset),
   //DEBUGGING
    /*.w_state(w_state), 
    .w_dataCount(w_dataCount),
    .w_writtenData(w_writtenData)*/
    .sw0(sw0)
);

// Analogue sampling module
sampling_Channel #(             //Channel configuration parameters - CHANGE THESE ACCORDING TO REQUIREMENTS
    .NO_OF_SAMPLES(80000),
    .CLK_DIV(12500),
    .DATA_WIDTH(16),
    .DATA_DEPTH(80000),
    .ADDRESS_SIZE(17),
    .ALMOST_EMPTY_THRESH(16000),
    .ALMOST_FULL_THRESH(64000)
) 
channel1 (
    .clk(clk),
    .reset(ch1_reset),
    //  sampling_controller inputs:
    //.channelEnable(ch1_enable),           
    .trigger(trigger),                              //User defined startSampling input.
    // memory buffer inputs:
    .write_data(ch1_write_enable),                      // From the input interface
    .read_data(ch1_read_enable),                        // From parallel port/memory controller
    .input_data_stream(ch1_sampler_output),             // From the prefacing module 
    // Outputs
    .output_data_stream(ch1_output_data_stream),
    //  sampling_controller ouputs
    .done(ch1_done),                   
    .sampleClock(ch1_sampleClock),                      //Output from the sampling controller, for indications. 
    .samplingEnable(ch1_samplingEnable),
    //  Fifo outputs                 
    .fifo_full(ch1_fifo_full),
    .fifo_empty(ch1_fifo_empty)
);
//Prefacing module/IO  Handler
analog_sampler_converter IR1_channel(
    .clk_100MHz(clk),
    .reset(ch1_reset),
    .clk_sampling(ch1_sampleClock),             //input sampling clock
    .samplingEnable(ch1_samplingEnable),        //input to start sampling
    .writeEnable(ch1_write_enable),                  //Signals to the sampling_channel memory buffer to write data
    .output_data_stream(ch1_sampler_output),     //16 bit output from digital sampler
    .scl(scl),
    .sda(sda),
    .fromI2C(fromI2C)
    //DEBUGGING
    //output wire w_cState
);


//////////////////////////////////////////////////////////////////////////////////
//END Module instantiations
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
//Channel multiplexer: (ADJUSTMENT REQUIRED FOR ADDITIONAL CHANNELS)
//////////////////////////////////////////////////////////////////////////////////
//  ADDING CHANNEL INSTRUCTIONS
//  ***************************
// To add an additional channel, first copy and paste the 3 lines indicated in the
// sensitivity list and adjust the 'ch1_' prefix, or according to your own definitions.

// Then, add an additional case according to the value of w_channelSelected value that
// will uniquely identify the channel. The default is set to channel 1. 
always@(
                                    // * * * * * * * * * * * * * * * * * * * * * * * * * 
        ch1_output_data_stream or   // COPY AND ADJUST THESE 2 LINES FOR MORE CHANNELS
        ch1_fifo_empty or           // * * * * * * * * * * * * * * * * * * * * * * * * *
                                    //Add channel sensitivities here
        
        w_channelSelected or data_req or channelReset) begin 
        
    case (w_channelSelected) 
        8'b00000001 : begin
            input_data_stream   = ch1_output_data_stream;   //Channel => EPP controller
            channel_empty       = ch1_fifo_empty;           //Channel => EPP controller
            ch1_read_enable     = data_req;                 //EPP controller => channel sampler
            ch1_reset           = channelReset;             //EPP controller => ch1_reset
        end
        //ADD CHANNEL CASES HERE
        default : begin //Default is connected to channel 1
            input_data_stream   = ch1_output_data_stream;   //Channel => EPP controller
            channel_empty       = ch1_fifo_empty;           //Channel => EPP controller
            ch1_reset           = channelReset;             //EPP controller => ch1_reset
        end 
    endcase
end

//////////////////////////////////////////////////////////////////////////////////
//END Channel multiplexer
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// Module behaviour
//////////////////////////////////////////////////////////////////////////////////
//
// Use this following segment to define additional characteristics. For example,
// triggers should be defined here according to the format required. For this example
// an onboard switch is responsible for triggering the recording, sw0.

always@(posedge clk) begin
    if(sw0==0) begin //if switch is pulled low, start recording
        trigger <= 1;
    end
    else trigger <= 0;
end
//////////////////////////////////////////////////////////////////////////////////
// END Module behaviour
//////////////////////////////////////////////////////////////////////////////////

//DEBUGGING WIRES - comment out or remove before synthesis
//assign w_ch1_sampleClock = ch1_sampleClock;
//assign w_ch1_trigger = ch1_trigger;
endmodule