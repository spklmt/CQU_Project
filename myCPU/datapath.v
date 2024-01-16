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

module datapath(
	input wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,jalD,jrD,balD,
	input wire invalidD,
	output wire equalD,
	output wire[31:0] instrD,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire hiloE,
	input wire jalE,jrE,balE,
	input wire[7:0] alucontrolE,
	output wire flushE,stallE,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	input wire memenM,cp0_wenM,
	output wire[31:0] aluoutM,writedata2M,
	input wire[31:0] readdataM,
	output wire flushM,stallM,
	output wire[3:0] memwriteM,
	output wire[31:0] except_typeM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire stallW,
	//debug
	output wire[31:0] pcW,
	output wire[4:0] writeregW,
	output wire[31:0] resultW,
	input wire stallreq_from_if,stallreq_from_mem
    );

	wire [63:0] hilo_i, hilo_o;		//hilo_i read from hilo, hilo_o write to hilo
	wire start_div, div_ready, signed_div, stall_div, start_div_o;
	wire [31:0] diva, divb;
	wire [63:0] div_result;

	//fetch stage
	wire flushF,stallF,is_in_delayslotF;
	wire [7:0]exceptF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcnextjrFD,pcplus4F,pcbranchD;
	//decode stage
	wire syscallD,breakD,eretD;
	wire is_in_delayslotD;
	wire [7:0]exceptD;
	wire [31:0] pcD;
	wire [31:0] pcplus4D;
	wire [31:0] pcplus8D;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rtD,rdD;
	wire [4:0] saD;
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	//execute stage
	wire is_in_delayslotE,expE;
	wire [7:0]exceptE;	
	wire [31:0] pcE;
	wire [31:0] pcplus8E;
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] saE;
	wire [4:0] writeregE,writereg2E;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE,aluout2E;
	wire zero,overflow;
	//mem stage
	wire is_in_delayslotM;
	wire [7:0]exceptM;
	wire adelM,adesM;
	wire [4:0] rdM;
	wire [31:0] pcM;
	wire [4:0] writeregM;
	wire [7:0] alucontrolM;
	wire [31:0] writedataM;
	wire [31:0] readdata2M,readdata3M;
	wire [31:0] bad_addrM;
	wire [31:0] cp0_wdataM,cp0_rdataM,newpcM;
	
	wire [31:0] count_o,cause_o,compare_o,status_o,epc_o,config_o,prid_o,badvaddr;
	wire timer_int_o;
	//writeback stage
	wire [31:0] aluoutW,readdataW;
	wire flushW;

	//hazard detection
	hazard h( //TODO
		//fetch stage
		flushF,stallF,
		//decode stage
		rsD,rtD,
		branchD,balD,jumpD,jrD,
		exceptD,
		forwardaD,forwardbD,
		flushD,stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		stall_div,
		flushE,stallE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		flushM,stallM,
		except_typeM,epc_o, 
		newpcM,		 		
		//write back stage
		writeregW,
		regwriteW,
		stallreq_from_if,stallreq_from_mem,
		flushW,stallW
	);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD | jalD,pcnextFD);
	mux2 #(32) pcjrmux(pcnextFD,srca2D,jrD,pcnextjrFD);
	
	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,flushF,pcnextjrFD,newpcM,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);

	assign exceptF = (pcF[1:0] == 2'b00) ? 8'b00000000 : 8'b10000000;
	assign is_in_delayslotF = (jumpD|balD|jrD|jalD|branchD);

	//decode stage
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~stallD,flushD,pcF,pcD);
	flopenrc #(8) r4D(clk,rst,~stallD,flushD,exceptF,exceptD);
	flopenrc #(1) r5D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	signext se(instrD[15:0],instrD[29:28],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	adder pcadd3(pcplus4D,32'b100,pcplus8D);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,instrD[31:26],instrD[20:16],equalD);

	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];

	assign syscallD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001100);
	assign breakD = (instrD[31:26] == 6'b000000 && instrD[5:0] == 6'b001101);
	assign eretD = (instrD == 32'b01000010000000000000000000011000);

	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(32) r4E(clk,rst,~stallE,flushE,pcplus8D,pcplus8E);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r8E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(32) r9E(clk,rst,~stallE,1'b0,pcD,pcE);
	flopenrc #(1) r10E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);

	//judge except instr
	flopenrc #(8) r11E(clk,rst,~stallE,flushE,//& (exceptD == 8'b0)
	{exceptD[7],syscallD,breakD,eretD,invalidD,exceptD[2:0]},
	exceptE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,saE,alucontrolE,aluoutE,hilo_i,hilo_o,div_ready,div_result,start_div,signed_div,stall_div,overflow,zero);
	div_reg div_reg(clk,start_div,srca2E,srcb3E,diva,divb,start_div_o);
	div div(clk,rst,signed_div,diva,divb,start_div_o,1'b0,div_result,div_ready);
	assign expE = (except_typeM != 0);
	hilo_reg hilo_reg(clk,rst,hiloE,hilo_o[63:32],hilo_o[31:0],hilo_i[63:32],hilo_i[31:0]);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	mux2 #(5) wrmux2(writeregE,5'b11111,jalE|balE,writereg2E); //reuse push forward module
	mux2 #(32) wrmux3(aluoutE,pcplus8E,jalE|jrE|balE,aluout2E);

	//mem stage
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluout2E,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writereg2E,writeregM);
	flopenrc #(8) r4M(clk,rst,~stallM,flushM,alucontrolE,alucontrolM);
	flopenrc #(32) r5M(clk,rst,~stallM,flushM,pcE,pcM);
	flopenrc #(32) r6M(clk,rst,~stallM,flushM,{exceptE[7:3],overflow,exceptE[1:0]},exceptM);
	flopenrc #(32) r7M(clk,rst,~stallM,flushM,srcb3E,cp0_wdataM);
	flopenrc #(5) r8M(clk,rst,~stallM,flushM,rdE,rdM);
	flopenrc #(1) r9M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
	load_mux load_mux(alucontrolM,aluoutM,readdataM,readdata2M);
	store_mux store_mux(alucontrolM,aluoutM,writedataM,memwriteM,writedata2M);
	mux2 #(32) read_mux(cp0_rdataM,readdata2M,memenM,readdata3M); 
    exception ept(rst,exceptM,adelM,adesM,status_o,cause_o,except_typeM);
    cp0_reg cp0 (.clk(clk), .rst(rst), .we_i(cp0_wenM), .waddr_i(rdM), .raddr_i(rdM), .data_i(cp0_wdataM), .int_i(6'b0),
			.excepttype_i(except_typeM), .current_inst_addr_i(pcM), .is_in_delayslot_i(is_in_delayslotM), .bad_addr_i(bad_addrM),
            .data_o(cp0_rdataM), .count_o(count_o), .compare_o(compare_o), .status_o(status_o), .cause_o(cause_o),
			.epc_o(epc_o), .config_o(config_o), .prid_o(prid_o), .badvaddr(badvaddr), .timer_int_o(timer_int_o));
	memept mem (pcM,alucontrolM,aluoutM,adelM,adesM,bad_addrM);

	//writeback stage
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,readdata3M,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	flopenrc #(32) r4W(clk,rst,~stallW,flushW,pcM,pcW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
endmodule
