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

reg [11:0] row;
reg [7:0] col;
reg [1:0] bank;
reg [7:0] state;
reg AckReg;

assign DRAM_CLK = Clk;
assign Busy = (state != `STATE_IDLE);
assign Ack = AckReg;

always @(posedge Clk) begin
    case(state)
	`STATE_IDLE: begin
	    AckReg <= 1'b0;
	    if(Req) begin
		AckReg <= 1'b1;
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
