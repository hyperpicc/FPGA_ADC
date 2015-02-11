module SDRAM_Interface( Clk, Data[15:0], Address[21:0], Req, WnR, Busy, Ack, Err, DRAM_ADDR[12:0], DRAM_DQ[15:0], DRAM_BA_0, DRAM_BA_1, DRAM_LDQM, DRAM_UDQM, DRAM_WE_N, DRAM_CAS_N, DRAM_RAS_N, DRAM_CS_N, DRAM_CLK, DRAM_CKE);

`define STATE_IDLE 0
`define STATE_START_WRITE 1
`define STATE_START_READ 2
`define STATE_INIT 255
`define STATE_PRECHARGE_ALL 254

input Clk, Req, WnR;
inout [15:0]Data;
input [21:0]Address;

output Busy, Err, Ack;
output [12:0]DRAM_ADDR;
inout [15:0]DRAM_DQ;
output DRAM_BA_0, DRAM_BA_1, DRAM_LDQM, DRAM_UDQM, DRAM_WE_N, DRAM_CAS_N, DRAM_RAS_N, DRAM_CS_N, DRAM_CLK, DRAM_CKE;

reg [15:0] shadowData;	// Local copy of the data to write
reg [11:0] row;		// The row part of the address
reg [7:0] col;		// The column part of the address
reg [1:0] bank;		// The bank of the SDRAM
reg [7:0] state;	// The state-machine register
reg AckReg;		// Register to hold the acknowledgement of command

/*
 * We change pinstates on the rising edge of the clock, but DRAM is looking
 * for stable input at these edges. Therefore, we invert the DRAM clock so our
 * posedge is its negedge and vice versa.
 */
assign DRAM_CLK = ~Clk;
/*
 * If the state is not the IDLE state, we are busy...
 */
assign Busy = (state != `STATE_IDLE);
/*
 * Set this flag when we acknowledge a command (write or read) from the user
 */
assign Ack = AckReg;

always @(posedge Clk) begin
    case(state)
	`STATE_IDLE: begin
	    AckReg <= 1'b0;
	    if(Req) begin
		AckReg <= 1'b1;
		shadowData <= Data;
		row <= Address[11:0];
		col <= Address[19:12];
		bank <= Address[21:20];
		if(WnR)
		    state <= `STATE_START_WRITE;
		else
		    state <= `STATE_START_READ;
	    end
	end
	`STATE_START_WRITE: begin
	    state <= `STATE_IDLE;
	end
	`STATE_START_READ: begin
	    state <= `STATE_IDLE;
	end
    endcase
end

endmodule
