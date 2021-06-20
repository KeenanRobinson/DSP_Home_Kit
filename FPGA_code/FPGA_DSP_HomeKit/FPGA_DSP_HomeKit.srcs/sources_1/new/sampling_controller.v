`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Cape Town
// Student: Keenan Robinson
// Supervisor: Dr Simon Winberg
// 
// Design Name: 
// Module Name: sampling_controller
// Project Name: DSP@Home Kit
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

// The purpose of this module is to control aspects including the sample rate, number
// of sample and basic control features of the sampling system. 

module sampling_controller(
    input wire clk,                     //Input clock 100MHz
    input wire reset,                   //Restarts the channel, clearing counter
    //input wire channelSelect,           //Enables the channel. Disabling it prevents data recording.
    input wire trigger,                 //While this is high, begin sampling
    output wire done,                   //Indicates whether the channel has reached max sample number
    output reg sampleClock,              //This indicates when the data should be collected.
    //Debugging
    output wire [31:0] w_clockCount,
    output wire [31:0] w_sampleCount,
    output wire w_trigger,
    output wire w_channelEnable,
    output wire w_startSampling
);
parameter NO_OF_SAMPLES = 5;
parameter CLK_DIV = 100;                    //Clock divider value to produce sampling frequency.
                                            //eg. 100MHz/(CLK_DIV=100) = 1 MHz => 1uS between samples
//Internal registers
reg [31:0] clockCount  = 0;         //Part of the clock divider scheme to produce the necessary clock output
reg [31:0] sampleCount = 0;         //Counts the number of samples
reg r_reset = 0;
reg r_channelSelect = 0;
reg r_trigger = 0;
reg r_startSampling = 0;
reg r_done = 0;
assign done = r_done;
//Populating internal registers
always@(posedge clk) begin
    r_reset <= reset;
    //r_channelSelect <= channelSelect;
    r_trigger <= trigger;
end 

//Start sampling process
always@(posedge clk) begin     
    if(r_reset) begin                           //If reset, disable sampling.
        r_startSampling <= 0;
    end
    else begin
        if(r_trigger) begin //If the channel is enabled and trigger is on, start sampling
            if(done==0) r_startSampling  <= 1;
            else r_startSampling  <= 0;         //Do not sample when done has been reached.
        end
        else r_startSampling <= 0;
    end
end

//Clock divider for sampling behaviour                      
always@(posedge clk) begin
    if(r_reset) begin
        clockCount  <= 0;   //reset the clockCount to LOW, restarting clock cycle
        sampleClock <= 0;   //reset sampleClock to LOW
    end
    else if(r_startSampling) begin
        clockCount <= clockCount+1;
        if(clockCount >= CLK_DIV-1) begin
            clockCount  <= 0;
            sampleClock <= ~sampleClock;
        end 
        else sampleClock <= (clockCount<CLK_DIV/2) ? 1'b1:1'b0;
        
    end
end

//Counts number of samples taken to determine when completed.
//sampleClock will only go high when sampling is enabled 
always@(posedge sampleClock or posedge r_reset) begin
    if(r_reset) begin
        r_done <= 0;
        sampleCount <= 0;
    end
    else if(sampleCount >= NO_OF_SAMPLES-1) begin
        r_done <= 1;
    end
    else begin
        sampleCount <= sampleCount+1; //increment the number of samples
        r_done <= 0;
    end
end

//DEBUGGING SIGNALS
assign w_clockCount     = clockCount;
assign w_sampleCount    = sampleCount;
assign w_trigger        = r_trigger;
//assign w_channelEnable  = r_channelEnable;
assign w_startSampling  = r_startSampling;

endmodule