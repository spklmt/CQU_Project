`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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

module memept(
    input wire[31:0] pc,
    input wire[7:0] alucontrolM,
    input wire[31:0] addrM,
    output reg adelM,
    output reg adesM,
    output reg[31:0] bad_addr
    );


    always @(*) begin
        bad_addr <= pc;
        adelM <= 1'b0;
        adesM <= 1'b0;
        case(alucontrolM)
            `EXE_LB_OP, `EXE_LBU_OP: case(addrM[1:0]) 
                2'b00, 2'b01, 2'b10, 2'b11: begin
                    bad_addr <= pc;
                    adelM <= 1'b0;
                end
                default: begin
                    bad_addr <= addrM;
                    adelM <= 1'b1;
                end
            endcase
            `EXE_LH_OP, `EXE_LHU_OP: case(addrM[1:0]) 
                2'b00, 2'b10: begin
                    bad_addr <= pc;
                    adelM <= 1'b0;
                end
                default: begin
                    bad_addr <= addrM;
                    adelM <= 1'b1;
                end
            endcase
            `EXE_LW_OP: case(addrM[1:0]) 
                2'b00: begin
                    bad_addr <= pc;
                    adelM <= 1'b0;
                end
                default: begin
                    bad_addr <= addrM;
                    adelM <= 1'b1;
                end
            endcase
            `EXE_SB_OP: case(addrM[1:0])
                2'b00, 2'b01, 2'b10, 2'b11: begin
                    bad_addr <= pc;
                    adesM <= 1'b0;
                end
                default: begin
                    bad_addr <= addrM;
                    adesM <= 1'b1;
                end
            endcase
            `EXE_SH_OP: case(addrM[1:0])
                2'b00, 2'b10: begin
                    bad_addr <= pc;
                    adesM <= 1'b0;
                end
                default: begin
                    bad_addr <= addrM;
                    adesM <= 1'b1;
                end
            endcase
            `EXE_SW_OP: case(addrM[1:0])
                2'b00: begin
                    bad_addr <= pc;
                    adesM <= 1'b0;
                end
                default: begin
                    bad_addr <= addrM;
                    adesM <= 1'b1;
                end
            endcase
        endcase
    end

endmodule