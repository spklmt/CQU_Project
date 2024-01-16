`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[31:0] instrD,
	input wire equalD,
	output wire pcsrcD,branchD,jumpD,jalD,jrD,balD,
	output wire invalidD,
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,hiloE,
	output wire jalE,jrE,balE,
	output wire[7:0] alucontrolE,
	//mem stage
	input wire flushM,stallM,
	output wire memtoregM,regwriteM,memenM,cp0_wenM,
	//write back stage
	input wire stallW,
	output wire memtoregW,regwriteW
    );
	
	//decode stage
	wire memtoregD,alusrcD,
		regdstD,regwriteD,hiloD,memenD,cp0_wenD;
	wire[7:0] alucontrolD;
	//execute stage
	wire memenE,cp0_wenE;

	maindec md(
		instrD,
		memtoregD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,jalD,jrD,balD,
		hiloD,memenD,cp0_wenD,invalidD
	);
	aludec ad(instrD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(18) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,alusrcD,regdstD,regwriteD,alucontrolD,jalD,jrD,balD,hiloD,memenD,cp0_wenD},
		{memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,jalE,jrE,balE,hiloE,memenE,cp0_wenE}
	);
	flopenrc #(4) regM(
		clk,rst,~stallM,flushM,
		{memtoregE,regwriteE,memenE,cp0_wenE},
		{memtoregM,regwriteM,memenM,cp0_wenM}
	);
	flopenr #(2) regW(
		clk,rst,~stallW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
	);
endmodule
