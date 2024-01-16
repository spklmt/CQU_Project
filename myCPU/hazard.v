`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output wire flushF,stallF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,balD,jumpD,jrD,
	input wire [7:0] exceptD,
	output wire forwardaD,forwardbD,
	output wire flushD,stallD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	output reg[1:0] forwardaE,forwardbE,
	input wire stall_divE,
	output wire flushE,stallE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	output wire flushM,stallM,
	input wire [31:0] except_typeM,epc_o,
	output reg [31:0] newpcM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	input wire stallreq_from_if,stallreq_from_mem,
	output flushW,stallW
    );

	wire lwstallD,branchstallD,branchflushD,jrstallD;

	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	//stalls
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign branchstallD = branchD & (regwriteE & (writeregE == rsD | writeregE == rtD) | 
										memtoregM & (writeregM == rsD | writeregM == rtD));
	assign branchflushD = branchD & !balD;
	assign jrstallD = jrD & (regwriteE & (writeregE == rsD) |
								memtoregM & (writeregM == rsD));

	assign stallD = lwstallD | branchstallD | stall_divE | jrstallD | stallreq_from_if | stallreq_from_mem;
	assign stallF = stallD; //stalling D stalls all previous stages
	
	assign flushE = ((lwstallD | branchstallD | branchflushD | jumpD) & (exceptD == 0) & (~stall_divE))  | (stallreq_from_if & ~stall_divE & (exceptD == 0)) | (except_typeM!=0); //stalling D flushes next stage
	assign stallE = stall_divE | stallreq_from_mem;
	assign flushM = stall_divE | (except_typeM!=0);

	assign stallW = stallreq_from_mem | stall_divE;
	assign stallM = stallW | stall_divE;

	assign flushF=(except_typeM!=0);
	assign flushD=(except_typeM!=0);//| eretD | exceptE[4];
	assign flushW=(except_typeM!=0);

	always@(*) begin   
        if(except_typeM!=32'b0)
        begin 
            case (except_typeM)
                32'h0000_0001,32'h0000_0004,32'h0000_0005,32'h0000_0008,32'h0000_0009,32'h0000_000a,32'h0000_000c:
                    newpcM <= 32'hbfc00380;
                32'h0000_000e:	newpcM <= epc_o;
            endcase
        end
    end
	// Note: not necessary to stall D stage on store
  	//       if source comes from load;
  	//       instead, another bypass network could
  	//       be added from W to M
endmodule