module UART_RX( Sample_Clk, Divider, serin, flag, Data_Out);

`define STATE_LISTENING 0
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

wire [8:0] delayVal;

assign Data_Out = dataReg;
assign delayVal = (state == `STATE_DELAY) ? Divider + (Divider >> 1) : (Divider);
assign flag = dataRcvd;

always @(posedge Sample_Clk, negedge serin) begin
    if((state == `STATE_LISTENING) && (~serin)) begin
	// We were listening, and now the level has gone low
	// Before sampling the first bit, we have to wait 3/2 T
	// and sample at half the first bit to avoid bounce and other stuff
	state <= `STATE_DELAY;
	delayReg <= 9'h00;
	bitCtr <= 8'h0;
	dataRcvd <= 1'b0;
    end else if( state != `STATE_LISTENING) begin
	// If we were instructed to delay for 3/2 T...
	if( state == `STATE_DELAY ) begin
	    // Increase the delay timer
	    delayReg <= delayReg + 1'b1;
	    // and check if we are at or beyond the delay time
	    if(delayReg >= delayVal) begin
		// If so, we receive the first bit and set the delay timer
		// back to zero
		delayReg <= 9'h00;
		state <= `STATE_RECEIVING;	
	    end
	// We are in the active phase of receiving
	end else begin
	    // If the timer has been reset to zero, it is time to sample a bit
	    if( delayReg == 9'h00 ) begin
		dataReg <= {serin, dataReg[7:1]};
		bitCtr <= bitCtr + 1'b1;
		// Check if we have received all 8 bits
		if( bitCtr >= 8'h8 ) begin
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
end

endmodule
