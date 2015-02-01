module UART_TX( USART_Clk, DataIn[7:0], startTx, serout, finishedTx);
`define STATE_IDLE 0
`define STATE_INIT 1
`define STATE_ACTIVE 2

input USART_Clk;
input [7:0]DataIn;
input startTx;

output serout;
output finishedTx;

reg [7:0] state;
reg [7:0] bitCtr;
reg [9:0] outputReg;

wire txEnable;
assign finishedTx = (state == `STATE_IDLE);
assign txEnable = startTx & finishedTx;
assign serout = (state == `STATE_ACTIVE) ? outputReg[0] : 1'b1;

always @(posedge USART_Clk, posedge txEnable) begin
    if(txEnable) begin
	outputReg[9:0] <= {1'b1, DataIn[7:0], 1'b0};
	bitCtr <= 8'h0;
	state <= `STATE_INIT;
    end else begin
	if(state == `STATE_INIT)
	    state <= `STATE_ACTIVE;
	else if(state == `STATE_ACTIVE) begin
	    if(bitCtr < 8'h09) begin
		outputReg <= {1'b1, outputReg[9:1]};
		bitCtr <= bitCtr + 1;
	    end else begin
		state <= `STATE_IDLE;
	    end
	end
    end 
end
endmodule
