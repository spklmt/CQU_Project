`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/01 22:41:27
// Design Name: 
// Module Name: load_mux
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


module load_mux(
    input wire[7:0] alucontrolM,
    input wire[31:0] addrM,
    input wire[31:0] readdataM,
    output reg[31:0] readdata2M
    );

    always @(*) begin
        case(alucontrolM)
            `EXE_LB_OP: case(addrM[1:0]) 
                2'b00: readdata2M <= {{24{readdataM[7]}}, readdataM[7:0]};
                2'b01: readdata2M <= {{24{readdataM[15]}}, readdataM[15:8]};
                2'b10: readdata2M <= {{24{readdataM[23]}}, readdataM[23:16]};
                2'b11: readdata2M <= {{24{readdataM[31]}}, readdataM[31:24]};
                default: readdata2M <= readdataM;
            endcase
            `EXE_LBU_OP: case(addrM[1:0]) 
                2'b00: readdata2M <= {{24{1'b0}}, readdataM[7:0]};
                2'b01: readdata2M <= {{24{1'b0}}, readdataM[15:8]};
                2'b10: readdata2M <= {{24{1'b0}}, readdataM[23:16]};
                2'b11: readdata2M <= {{24{1'b0}}, readdataM[31:24]};
                default: readdata2M <= readdataM;
            endcase
            `EXE_LH_OP: case(addrM[1:0]) 
                2'b00: readdata2M <= {{16{readdataM[15]}}, readdataM[15:0]};
                2'b10: readdata2M <= {{16{readdataM[31]}}, readdataM[31:16]};
                default: readdata2M <= readdataM; //err TODO
            endcase
            `EXE_LHU_OP: case(addrM[1:0]) 
                2'b00: readdata2M <= {{16{1'b0}}, readdataM[15:0]};
                2'b10: readdata2M <= {{16{1'b0}}, readdataM[31:16]};
                default: readdata2M <= readdataM; //err TODO
            endcase
            `EXE_LW_OP: case(addrM[1:0]) 
                2'b00: readdata2M <= readdataM;
                default: readdata2M <= readdataM; //err TODO
            endcase
            default: readdata2M <= readdataM;
        endcase
    end
endmodule