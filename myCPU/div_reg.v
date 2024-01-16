`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/1/4 21:47:50
// Design Name: 
// Module Name: div_reg
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


module div_reg(
    input wire clk,start_div,
    input wire [31:0] diva_i,divb_i,
    output reg [31:0] diva_o,divb_o,
	output reg start_div_o
    );
    reg flag;
    always @(posedge clk) begin
		if (~start_div) begin
			diva_o <= diva_i;
            divb_o <= divb_i;
			start_div_o <= start_div;
            flag <= 1;
		end
		else if(flag & start_div) begin
            diva_o <= diva_i;
            divb_o <= divb_i;
			start_div_o <= start_div;
			flag <= 0;
        end 
    end
endmodule