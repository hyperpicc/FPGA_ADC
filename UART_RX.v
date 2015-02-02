module UART_RX( Sample_Clk, Divider, serin, flag, Data_Out);

`define STATE_LISTENING 0
`define STATE_VERIFY 1
`define STATE_DELAY 1
`define STATE_RECEIVING 2

input Sample_Clk, serin;
input [7:0] Divider;

output flag;
output [7:0] Data_Out;

reg [7:0] dataReg;
reg [7:0] state;
reg [7:0] bitCtr;
reg [8:0] delayReg;
reg dataRcvd;

reg [8:0] delayVal;

wire frameStart;

assign Data_Out = dataReg;
assign flag = dataRcvd;
assign frameStart = ((state == `STATE_LISTENING) && (~serin));

always @(posedge Sample_Clk ) begin
    if(state == `STATE_LISTENING && !serin ) begin
	// We were listening, and now the level has gone low
	// Before sampling the first bit, we have to wait 3/2 T
	// and sample at half the first bit to avoid bounce and other stuff
	state <= `STATE_VERIFY;
	delayReg <= 9'h00;
	delayVal <= Divider + (Divider >> 1);
	dataReg <= 8'h0;
	bitCtr <= 8'h0;
	dataRcvd <= 1'b0;
    // If we were instructed to delay for 3/2 T...
    end else if( state == `STATE_DELAY ) begin
	    // Increase the delay timer
	    delayReg <= delayReg + 1'b1;
	    // and check if we are at or beyond the delay time
	    if(delayReg >= delayVal) begin
		// If so, we receive the first bit and set the delay timer
		// back to zero
		delayReg <= 9'h00;
		delayVal <= Divider;
		state <= `STATE_RECEIVING;	
	    end
	// We are in the active phase of receiving
    end else if ( state == `STATE_RECEIVING ) begin
	// If the timer has been reset to zero, it is time to sample a bit
	if( delayReg == 9'h00 ) begin

	    bitCtr <= bitCtr + 1'b1;
	    if(bitCtr <= 8'h8)
		dataReg <= {serin, dataReg[7:1]};
	    // Check if we have received all 8 bits
	    if( bitCtr > 8'h9 ) begin
		state <= `STATE_LISTENING; 
		dataRcvd <= 1'b1;
	    end else begin
		// If not, increase the delay timer again
		delayReg <= delayReg + 1'b1;	
	    end
	// We increase the timer and check for overflows 
	end else begin
	    delayReg <= delayReg + 1'b1;
	    if(delayReg >= delayVal)
		delayReg <= 9'h0;
	end
    end
end

endmodule
