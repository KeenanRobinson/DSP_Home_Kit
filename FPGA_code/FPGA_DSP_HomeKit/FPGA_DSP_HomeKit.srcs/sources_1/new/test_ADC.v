`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2021 22:26:16
// Design Name: 
// Module Name: test_ADC
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
// This module simply tests that the data output from the Pmod AD2 unit
// produces the correct outputs. The test includes using a potentiometer to vary
// the voltage on the input of the Pmod V1. The output of the ADC is printed straight
// to the LEDs

//This works.

module test_ADC(
    input wire clk,
    input wire reset_n,
    inout wire scl,
    inout wire sda,
    output wire i2c_ack_err,
    output wire [11:0] adc_output_ch0 
);
reg [1:0] clk_divider=0;
wire clk_50MHz;

assign clk_50MHz = clk_divider[1];
    
pmod_adc_ad7991 ADC (
    .clk(clk_50MHz),
    .reset_n(reset_n),
    .scl(scl),
    .sda(sda),
    .i2c_ack_err(i2c_ack_err),
    .adc_ch0_data(adc_output_ch0),
    .adc_ch1_data(),
    .adc_ch2_data(),
    .adc_ch3_data()
);

always@(posedge clk) begin
    clk_divider <= clk_divider+1;
end
endmodule
