`timescale 1ns / 1ps

module mycpu_top(
    input aclk,
    input aresetn,  //low active
    input [5:0]ext_int, //interrupt,high active

	// axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[7:0] arlen,     //read request transfer length(beats), fixed 4'b0
    output wire[2:0] arsize,    //read request transfer size(bytes per beats)
    output wire[1:0] arburst,   //transfer type, fixed 2'b01
    output wire[1:0] arlock,    //atomic lock, fixed 2'b0
    output wire[3:0] arcache,   //cache property, fixed 4'b0
    output wire[2:0] arprot,    //protect property, fixed 3'b0
    output wire arvalid,        //read request address valid
    input wire arready,         //slave end ready to receive address transfer
    //r              
    input wire[3:0] rid,        //equal to arid, can be ignored
    input wire[31:0] rdata,     //read data
    input wire[1:0] rresp,      //this read request finished successfully, can be ignored
    input wire rlast,           //the last beat data for this request, can be ignored
    input wire rvalid,          //read data valid
    output wire rready,         //master end ready to receive data transfer
    //aw           
    output wire[3:0] awid,      //write request id, fixed 4'b0
    output wire[31:0] awaddr,   //write request address
    output wire[3:0] awlen,     //write request transfer length(beats), fixed 4'b0
    output wire[2:0] awsize,    //write request transfer size(bytes per beats)
    output wire[1:0] awburst,   //transfer type, fixed 2'b01
    output wire[1:0] awlock,    //atomic lock, fixed 2'b01
    output wire[3:0] awcache,   //cache property, fixed 4'b01
    output wire[2:0] awprot,    //protect property, fixed 3'b01
    output wire awvalid,        //write request address valid
    input wire awready,         //slave end ready to receive address transfer
    //w          
    output wire[3:0] wid,       //equal to awid, fixed 4'b0
    output wire[31:0] wdata,    //write data
    output wire[3:0] wstrb,     //write data strobe select bit
    output wire wlast,          //the last beat data signal, fixed 1'b1
    output wire wvalid,         //write data valid
    input wire wready,          //slave end ready to receive data transfer
    //b              
    input  wire[3:0] bid,       //equal to wid,awid, can be ignored
    input  wire[1:0] bresp,     //this write request finished successfully, can be ignored
    input wire bvalid,          //write data valid
    output wire bready,          //master end ready to receive write response

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata
);

    wire clk, resetn;
    assign clk = aclk;
    assign resetn = ~aresetn;

    //sram signal
	//cpu inst sram
	wire        inst_sram_en;
	wire [3 :0] inst_sram_wen;
	wire [31:0] inst_sram_addr;
	wire [31:0] inst_sram_wdata;
	wire [31:0] inst_sram_rdata;
	//cpu data sram
	wire        data_sram_en,data_sram_write;
	wire [1 :0] data_sram_size;
	wire [3 :0] data_sram_wen;
	wire [31:0] data_sram_addr;
	wire [31:0] data_sram_wdata;
	wire [31:0] data_sram_rdata;

    //mmu
    wire [31:0] inst_paddr, data_paddr;
	wire no_dcache;

    //IF 
    wire [31:0] pcF,instrF;
    //ID
    wire [31:0] instrD;
    wire equalD,pcsrcD,branchD,jumpD,jalD,jrD,balD;
	wire invalidD;
    //EX
    wire regdstE,alusrcE,memtoregE,regwriteE,hiloE,jalE,jrE,balE;
    wire flushE,stallE;
    wire [7:0] alucontrolE;
    //MEM
    wire memtoregM,regwriteM,memenM,cp0_wenM;
    wire flushM,stallM;
    wire [3:0] memwriteM;
    wire [31:0] aluoutM,writedataM,readdataM;
    //WB
    wire stallW;
    wire[31:0] pcW;
    wire regwriteW,memtoregW;
    wire[4:0] writeregW;
	wire[31:0] resultW;

    //cache mux signal
	wire cache_miss,sel_i;
	wire[31:0] i_addr,d_addr,m_addr;
	wire m_fetch,m_ld_st,mem_access;
	wire mem_write,m_st;
	wire mem_ready,m_i_ready,m_d_ready,i_ready,d_ready;
	wire[31:0] mem_st_data,mem_data;
	wire[1:0] mem_size,d_size;// size not use
	wire[3:0] m_sel,d_wen;
	wire stallreq_from_if,stallreq_from_mem;

	// assign the inst_sram_parameters
	assign inst_sram_en = 1'b1; //always strobe
	assign inst_sram_wen = 4'b0; // always read
	assign inst_sram_addr = inst_paddr; // pc
	assign inst_sram_wdata = 32'b0; // do not need write operation
	assign instrF = inst_sram_rdata; // use your own signal from F stage

	//assign the data_sram_parameters
	assign data_sram_en = memenM;// notice: disable the data strobe when exceptions occur
	assign data_sram_write = memenM & |memwriteM; // 0 read, 1 write
	assign data_sram_size = (memwriteM == 4'b0001 || memwriteM == 4'b0010 || memwriteM == 4'b0100 || memwriteM == 4'b1000) ? 2'b00:
							(memwriteM == 4'b0011 || memwriteM == 4'b1100) ? 2'b01:2'b10;
    assign data_sram_wen = memwriteM;
    assign data_sram_addr = data_paddr;
    assign data_sram_wdata = writedataM;
	assign readdataM = data_sram_rdata; // use your own signal from M stage

	//assign the trace parameters
    assign debug_wb_pc = pcW;
    assign debug_wb_rf_wen = {4{regwriteW}};
    assign debug_wb_rf_wnum = writeregW;
    assign debug_wb_rf_wdata = resultW;

    wire[31:0] excepttypeM;

    controller c(
        clk,resetn,
        //decode stage
        instrD,
        equalD,
        pcsrcD,branchD,jumpD,jalD,jrD,balD,
		invalidD,    
        //execute stage
        flushE,stallE,
        memtoregE,alusrcE,
        regdstE,regwriteE,hiloE,	
        jalE,jrE,balE,
        alucontrolE,
        //mem stage
        flushM,stallM,
        memtoregM,regwriteM,memenM,cp0_wenM,
        //write back stage
        stallW,
        memtoregW,regwriteW
    );
	datapath dp(
		clk,resetn,
		//fetch stage
		pcF,
		instrF,
		//decode stage
		pcsrcD,branchD,
		jumpD,jalD,jrD,balD,
		invalidD,
		equalD,
		instrD,
		//execute stage
		memtoregE,alusrcE,regdstE,regwriteE,hiloE,jalE,jrE,balE,
		alucontrolE,
		flushE,stallE,
		//mem stage
		memtoregM,
		regwriteM,
		memenM,cp0_wenM,
		aluoutM,writedataM,
		readdataM,
		flushM,stallM,
		memwriteM,
		excepttypeM,
		//writeback stage
		memtoregW,
		regwriteW,
        stallW,
		//debug
		pcW,
		writeregW,
		resultW,
        stallreq_from_if,stallreq_from_mem
	);

    mmu mmu(
        .inst_vaddr(pcF),
        .inst_paddr(inst_paddr),
        .data_vaddr(aluoutM),
        .data_paddr(data_paddr),
		.no_dcache(no_dcache)
    );

	// use a inst_miss signal to denote that the instruction is not loadssss
	reg inst_miss;
	always @(posedge clk) begin
		if (~aresetn) begin
			inst_miss <= 1'b1;
		end
		if (m_i_ready & inst_miss) begin // fetch instruction ready
			inst_miss <= 1'b0;
		end else if (~inst_miss & data_sram_en) begin // fetch instruction ready, but need load data, so inst_miss maintain 0
			inst_miss <= 1'b0;
		end else if (~inst_miss & data_sram_en & m_d_ready) begin //load data ready, set inst_miss to 1
			inst_miss <= 1'b1;
		end else begin // other conditions, set inst_miss to 1
			inst_miss <= 1'b1;
		end
	end

	assign sel_i = inst_miss;	// use inst_miss to select access memory(for load/store) or fetch(each instruction)
	assign d_addr = (data_sram_addr[31:16] != 16'hbfaf) ? data_sram_addr : {16'h1faf,data_sram_addr[15:0]}; // modify data address, to get the data from confreg
	assign i_addr = inst_sram_addr;
	assign m_addr = sel_i ? i_addr : d_addr;
	//
	assign m_fetch = inst_sram_en & inst_miss; //if inst_miss equals 0, disable the fetch strobe
	assign m_ld_st = data_sram_en;

	assign inst_sram_rdata = mem_data;
	assign data_sram_rdata = mem_data;
	assign mem_st_data = data_sram_wdata;
	//use select signal
	assign mem_access = sel_i ? m_fetch : m_ld_st;
	assign mem_size = sel_i ? 2'b10 : data_sram_size;
	assign m_sel = sel_i ? 4'b1111 : data_sram_wen;
	assign mem_write = sel_i ? 1'b0 : data_sram_write;

	//demux
	assign m_i_ready = mem_ready & sel_i;
	assign m_d_ready = mem_ready & ~sel_i;

	//
	assign stallreq_from_if = ~m_i_ready;
	assign stallreq_from_mem = data_sram_en & ~m_d_ready;

	axi_interface axi_interface(
		.clk(aclk),
		.resetn(aresetn),
		
		 //cache/cpu_core port
		.mem_a(m_addr),
		.mem_access(mem_access),
		.mem_write(mem_write),
		.mem_size(mem_size),
		.mem_sel(m_sel),
		.mem_ready(mem_ready),
		.mem_st_data(mem_st_data),
		.mem_data(mem_data),
		// add a input signal 'flush', cancel the memory accessing operation in axi_interface, do not need any extra design. 
		.flush(|excepttypeM), // use excepetion type

		.arid      (arid      ),
		.araddr    (araddr    ),
		.arlen     (arlen     ),
		.arsize    (arsize    ),
		.arburst   (arburst   ),
		.arlock    (arlock    ),
		.arcache   (arcache   ),
		.arprot    (arprot    ),
		.arvalid   (arvalid   ),
		.arready   (arready   ),
					
		.rid       (rid       ),
		.rdata     (rdata     ),
		.rresp     (rresp     ),
		.rlast     (rlast     ),
		.rvalid    (rvalid    ),
		.rready    (rready    ),
				
		.awid      (awid      ),
		.awaddr    (awaddr    ),
		.awlen     (awlen     ),
		.awsize    (awsize    ),
		.awburst   (awburst   ),
		.awlock    (awlock    ),
		.awcache   (awcache   ),
		.awprot    (awprot    ),
		.awvalid   (awvalid   ),
		.awready   (awready   ),
		
		.wid       (wid       ),
		.wdata     (wdata     ),
		.wstrb     (wstrb     ),
		.wlast     (wlast     ),
		.wvalid    (wvalid    ),
		.wready    (wready    ),
		
		.bid       (bid       ),
		.bresp     (bresp     ),
		.bvalid    (bvalid    ),
		.bready    (bready    )
	);

    //ascii
    // instdec instdec(
    //     .instr(instrF)
    // );
endmodule