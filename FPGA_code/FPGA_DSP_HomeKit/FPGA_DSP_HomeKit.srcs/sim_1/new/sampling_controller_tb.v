`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2021 09:33:26
// Design Name: 
// Module Name: sampling_controller_tb
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
//Testbench for the sampling_controller module.
//Configure the run time for 2000ns.Tools > Settings > Simulation

`define clk_period 10

module sampling_controller_tb;

reg clk=0;                     //Input clock 100MHz
reg reset;                   //Restarts the channel, clearing counter
reg channelEnable;           //Enables the channel. Disabling it prevents data recording.
reg trigger;                 //While this is high, begin sampling
wire done;                    //Indicates whether the channel has reached max sample number
wire sampleClock;             //This indicates when the data should be collected.
    //Debugging
wire [31:0] w_clockCount;
wire [31:0] w_sampleCount;
wire w_trigger;
wire w_channelEnable;
wire w_startSampling;
//Test parameters:
parameter NO_OF_SAMPLES = 5;
parameter CLK_DIV = 10;

sampling_controller #(
    .NO_OF_SAMPLES(NO_OF_SAMPLES),
    .CLK_DIV(CLK_DIV)
) 
uut(
    .clk(clk),                     //Input clock 100MHz
    .reset(reset),                   //Restarts the channel, clearing counter
    //.channelEnable(channelEnable),           //Enables the channel. Disabling it prevents data recording.
    .trigger(trigger),                 //While this is high, begin sampling
    .done(done),                    //Indicates whether the channel has reached max sample number
    .sampleClock(sampleClock),             //This indicates when the data should be collected.
    //Debugging
    .w_clockCount(w_clockCount),
    .w_sampleCount(w_sampleCount),
    .w_trigger(w_trigger),
    .w_channelEnable(w_channelEnable),
    .w_startSampling(w_startSampling)
);

/*
    LIST OF TEST CONDITIONS:
    ***********************
    ER: expected result
    - reset = 1                         => ER: no sampling action
    - reset = 0:
    - channelEnable = 0, trigger = 0    => ER: no sampling action
    - channelEnable = 0, trigger = 1    => ER: no sampling action
    - channelEnable = 1, trigger = 0    => ER: no sampling action
    - channelEnable = 1, trigger = 1    => ER: sampling action
    - Examine when done goes HIGH       => ER: no sampling action
*/
integer k = 0;

always#(`clk_period/2) clk = ~clk;

initial begin  
    reset = 0;                   //Restarts the channel, clearing counter
    //channelEnable = 0;           //Enables the channel. Disabling it prevents data recording.
    trigger = 0;
    #5
    #`clk_period
    //Reset = 1                     
    reset = 1;                   
    //channelEnable = 0;           
    trigger = 0;
    for(k = 0; k < 10; k=k+1) #`clk_period;
    
    //Reset = 0                    
    reset = 0;                   
    //channelEnable = 0;           
    trigger = 0;
    for(k = 0; k < 10; k=k+1) #`clk_period;
    
    //trigger = 1                 
    reset = 0;                   
    //channelEnable = 0;           
    trigger = 1;
    for(k = 0; k < 10; k=k+1) #`clk_period;
    
    //channelEnable = 1                    
    reset = 0;                   
    //channelEnable = 0;           
    trigger = 1;
    for(k = 0; k < 10; k=k+1) #`clk_period;
    
    //channelEnable = 1                    
    reset = 0;                   
    //channelEnable = 1;           
    trigger = 0;
    for(k = 0; k < 10; k=k+1) #`clk_period;
    
    //channelEnable = 1, Trigger = 1
    //Also view if done goes HIGH after 5 rising edges of sampleClock                    
    reset = 0;                   
    //channelEnable = 1;           
    trigger = 1;
    for(k = 0; k < 100; k=k+1) begin
        #`clk_period;
    end
    
    //Reset = 1                     
    reset = 1;
    
    #50
    reset = 0;
     
    //channelEnable = 0;           
    trigger = 0;
    #100
    trigger = 1;
    for(k = 0; k < 10; k=k+1) #`clk_period;
    
end
endmodule