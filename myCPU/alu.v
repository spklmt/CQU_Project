`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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

`include "defines.vh"
module alu(
	input wire[31:0] a,b,
	input wire[4:0] sa,
	input wire[7:0] alucontrol,
	output reg[31:0] y,
	input wire[63:0] hilo_i,
	output reg[63:0] hilo_o,
	input wire div_ready,
	input wire[63:0] div_result,
	output reg start_div, signed_div, stall_div,
	output reg overflow,
	output wire zero
    );

	always @(*) begin
		case(alucontrol)
			//8 logic instr
			`EXE_AND_OP, `EXE_ANDI_OP: y <= a & b;
			`EXE_OR_OP, `EXE_ORI_OP: y <= a | b;
			`EXE_XOR_OP, `EXE_XORI_OP: y <= a ^ b;
			`EXE_NOR_OP: y <= ~(a | b);
			`EXE_LUI_OP: y <= {b[15:0], 16'b0};

			//6 shift instr
			`EXE_SLL_OP: y <= b << sa;
			`EXE_SRL_OP: y <= b >> sa;
			`EXE_SRA_OP: y <= ({32{b[31]}} << (6'd32 - {1'b0, sa})) | b >> sa;
			`EXE_SLLV_OP: y <= b << a[4:0];
			`EXE_SRLV_OP: y <= b >> a[4:0];
			`EXE_SRAV_OP: y <= ({32{b[31]}} << (6'd32 - {1'b0, a[4:0]})) | b >> a[4:0];

			//4 data move instr
			`EXE_MFHI_OP: y <= hilo_i[63:32];
			`EXE_MFLO_OP: y <= hilo_i[31:0];
			`EXE_MTHI_OP: hilo_o <= {a, hilo_i[31:0]};
			`EXE_MTLO_OP: hilo_o <= {hilo_i[63:32], a};

			//12 arithmetic instr
			`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: y <= a + b;
			`EXE_SUB_OP, `EXE_SUBU_OP: y <= a - b;
			`EXE_SLT_OP, `EXE_SLTI_OP: y <= (($signed(a) < $signed(b)) ? 1 : 0);
			`EXE_SLTU_OP, `EXE_SLTIU_OP: y <= (a < b ? 1 : 0);
			`EXE_MULT_OP: hilo_o <= $signed(a) * $signed(b);
			`EXE_MULTU_OP: hilo_o <= $unsigned(a) * $unsigned(b);

			//8 memory access instr TODO
			`EXE_LB_OP, `EXE_LBU_OP, `EXE_LH_OP, `EXE_LHU_OP, `EXE_LW_OP, `EXE_SB_OP, `EXE_SH_OP, `EXE_SW_OP: y <= a + b;

			//2 arithmetic instr
			`EXE_DIV_OP: begin
				if(div_ready == 1'b0) begin
					{start_div, signed_div, stall_div} = 3'b111;
				end
				else if(div_ready == 1'b1) begin
					{start_div, signed_div, stall_div} = 3'b010;
					hilo_o <= div_result;				
				end
				else {start_div, signed_div, stall_div} = 3'b010;
			end
			`EXE_DIVU_OP: begin
				if(div_ready == 1'b0) begin
					{start_div, signed_div, stall_div} = 3'b101;
				end
				else if(div_ready == 1'b1) begin
					{start_div, signed_div, stall_div} = 3'b000;
					hilo_o <= div_result;
				end
				else {start_div, signed_div, stall_div} = 3'b000;
			end
			
			default: begin
				y <= 32'b0;
				{start_div, signed_div, stall_div} = 3'b000;
			end
		endcase
	end

	assign zero = (y == 32'b0);

	always @(*) begin
		case (alucontrol)
			`EXE_ADD_OP, `EXE_ADDI_OP: overflow <= a[31] & b[31] & ~y[31] | ~a[31] & ~b[31] & y[31];
			`EXE_SUB_OP: overflow <= ~a[31] & b[31] & y[31] | a[31] & ~b[31] & ~y[31];
			default : overflow <= 1'b0;
		endcase
	end
endmodule