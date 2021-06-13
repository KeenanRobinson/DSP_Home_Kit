`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2021 07:33:48
// Design Name: 
// Module Name: testLED
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


/* DATA PORT TESTS
module testLED(
    input wire clk,
    input wire strobe,
    output reg [7:0] led,
    inout wire [7:0] data
);

reg [7:0] data_out = 8'b11111111;

assign data = (strobe) ? data_out : 8'bz;

always@(posedge clk) begin
    led <= data;
end

endmodule
*/

// CONTROL AND STATUS PORT TESTS
module testLED(
    input wire clk,
    input wire boardReset,
    output reg led
);

always@(posedge clk) begin
    led <= boardReset;
end

endmodule


