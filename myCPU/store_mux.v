`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/01 22:41:27
// Design Name: 
// Module Name: store_mux
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


module store_mux(
    input wire[7:0] alucontrolM,
    input wire[31:0] addrM,
    input wire[31:0] writedataM,
    output reg[4:0] memwriteM,
    output reg[31:0] writedata2M
    );

    always @(*) begin
        case(alucontrolM)
            `EXE_SB_OP: begin
                writedata2M <= {writedataM[7:0],writedataM[7:0],writedataM[7:0],writedataM[7:0]};
                case(addrM[1:0])
                    2'b00: memwriteM <= 4'b0001;
                    2'b01: memwriteM <= 4'b0010;
                    2'b10: memwriteM <= 4'b0100;
                    2'b11: memwriteM <= 4'b1000;
                    default: memwriteM <= 4'b0000;
                endcase
            end
            `EXE_SH_OP: begin 
                writedata2M <= {writedataM[15:0],writedataM[15:0]};               
                case(addrM[1:0])
                    2'b00: memwriteM <= 4'b0011;
                    2'b10: memwriteM <= 4'b1100;
                    default: memwriteM <= 4'b0000; //err TODO
                endcase
            end
            `EXE_SW_OP: begin  
                writedata2M <= writedataM;              
                case(addrM[1:0])
                    2'b00: memwriteM <= 4'b1111;
                    default: memwriteM <= 4'b0000; //err TODO
                endcase
            end
            default: begin
                writedata2M <= writedataM;
                memwriteM <= 4'b0000;
            end
        endcase
    end
endmodule
