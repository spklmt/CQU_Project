`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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
`include "defines2.vh"
module maindec(
	input wire[31:0] instr,
	output wire memtoreg,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jal,jr,bal,hilo,memen,cp0_wen,
	output reg invalid
    );

	wire [5:0] op;
	assign op = instr[31:26];
	wire [5:0] rt;
	assign rt = instr[20:16];
	wire [5:0] rs;
	assign rs = instr[25:21];
	wire [5:0] funct;
	assign funct = instr[5:0];

    assign cp0_wen = ((op == `SPECIAL3_INST) & (rs == `MTC0))? 1:0;

	reg[10:0] controls;
	assign {regwrite,regdst,alusrc,branch,memtoreg,jump,jal,jr,bal,hilo,memen} = controls;

	 always @(*) begin
		invalid = 0;
		controls <= 11'b00000_00000_0;
	 	case (op)
	 		//4 logic instr
	 		`EXE_ANDI, `EXE_XORI, `EXE_LUI, `EXE_ORI: controls <= 11'b10100_00000_0;

	 		//4 arithmetic instr
	 		`EXE_ADDI, `EXE_ADDIU, `EXE_SLTI, `EXE_SLTIU: controls <= 11'b10100_00000_0;

	 		//8 memory access instr
	 		`EXE_LB, `EXE_LBU, `EXE_LH, `EXE_LHU, `EXE_LW: controls <= 11'b10101_00000_1;
	 		`EXE_SB, `EXE_SH, `EXE_SW: controls <= 11'b00100_00000_1;

	 		//10 jump branch instr
	 		`EXE_J: controls <= 11'b00000_10000_0;
	 		`EXE_JAL: controls <= 11'b10000_01000_0;
	 		`EXE_BEQ, `EXE_BGTZ, `EXE_BLEZ, `EXE_BNE: controls <= 11'b00010_00000_0;
	 		`EXE_REGIMM_INST: case(rt)
	 			`EXE_BLTZ, `EXE_BGEZ: controls <= 11'b00010_00000_0;
	 			`EXE_BLTZAL, `EXE_BGEZAL: controls <= 11'b10010_00010_0;
	 			default: invalid = 1;
	 		endcase

			`SPECIAL3_INST: case(rs)
                `MTC0: controls <= 11'b00000_00000_0;//控制信号;
                `MFC0: controls <= 11'b10001_00000_0;//控制信号;
                `ERET: controls <= 11'b00000_00000_0;//控制信号;
                default: invalid = 1;
            endcase
			
	 		`EXE_NOP: case(funct) 
			    //2 trap instr
                `EXE_BREAK: controls <= 11'b00000_00000_0;
				`EXE_SYSCALL: controls <= 11'b00000_00000_0;

	 			//4 data move instr
	 			`EXE_MFHI, `EXE_MFLO: controls <= 11'b11000_00000_0;
	 			`EXE_MTHI, `EXE_MTLO: controls <= 11'b00000_00001_0;

	 			//10 arithmetic instr
	 			`EXE_MULT, `EXE_MULTU, `EXE_DIV, `EXE_DIVU: controls <= 11'b00000_00001_0;
				`EXE_ADD, `EXE_ADDU, `EXE_SUB, `EXE_SUBU, `EXE_SLT, `EXE_SLTU: controls <= 11'b11000_00000_0;

	 			//2 jump instr 
	 			`EXE_JR: controls <= 11'b00000_10100_0;
	 			`EXE_JALR: controls <= 11'b11000_00100_0;
                
				//4 logic instr
				`EXE_AND, `EXE_OR, `EXE_XOR, `EXE_NOR: controls <= 11'b11000_00000_0;
				
				//6 shift instr
				`EXE_SLL, `EXE_SRL, `EXE_SRA, `EXE_SLLV, `EXE_SRLV, `EXE_SRAV: controls <= 11'b11000_00000_0;


	 			default: invalid = 1;
	 		endcase

	 		default: invalid = 1;
	 	endcase
	 end
endmodule