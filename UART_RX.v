module UART_RX( Clk, Serin, DataOut, ReadyFlag, ErrorFlag, Reset, SampleFlag );
`define STATE_LISTENING 0
`define STATE_VERIFY 1
`define STATE_DELAY 1
`define STATE_RECEIVING 2
`define STATE_VERIFY_STOP 3

input Clk;
input Serin;
input Reset;

output [7:0] DataOut;
output ReadyFlag;
output ErrorFlag;
output SampleFlag;

reg [7:0] dataReg;
reg [7:0] delayCtr;
reg [7:0] stateMachine;
reg [7:0] bitCtr;
reg readyFlag, errorFlag, sampleFlag;

assign DataOut = dataReg;
assign ReadyFlag = readyFlag;
assign ErrorFlag = errorFlag;
assign SampleFlag = sampleFlag;

always@(posedge Clk, negedge Reset) begin
    if( ~Reset ) begin
	delayCtr <= 8'h0;
	dataReg <= 8'h0;
	stateMachine <= `STATE_LISTENING;
	bitCtr <= 8'h0;
	readyFlag <= 1'b0;
	errorFlag <= 1'b0;
    end else begin
    case(stateMachine)
	`STATE_LISTENING: begin
	    sampleFlag <= 1'b0;
	    if( ~Serin ) begin
		delayCtr <= 8'h7; // Wait for half a bit
		stateMachine <= `STATE_VERIFY;
	    end
	end
	`STATE_VERIFY: begin
	    delayCtr <= delayCtr - 8'h1;
	    // If we have reached half the bit, check if it is still low
	    if( delayCtr == 8'h0 ) begin
		// If so, wait for an entire bit and start receiving
		if( ~Serin ) begin
		    sampleFlag <= 1'b1;
		    stateMachine <= `STATE_RECEIVING;
		    readyFlag <= 1'b0;
		    errorFlag <= 1'b0;
		    delayCtr <= 8'hf;
		    bitCtr <= 8'h7;
		// Else, start listening again
		end else begin
		    stateMachine <= `STATE_LISTENING; 
		    errorFlag <= 1'b1;
		end
	    end
	end
	`STATE_RECEIVING: begin
	    sampleFlag <= 1'b0;
	    delayCtr <= delayCtr - 8'h1;
	    if( delayCtr == 8'h0 ) begin
		sampleFlag <= 1'b1;
		dataReg <= {Serin, dataReg[7:1]};
		bitCtr <= bitCtr - 8'h1; 
		delayCtr <= 8'hf;
		if( bitCtr == 8'h0 ) begin
		    stateMachine <= `STATE_VERIFY_STOP;
		end
	    end
	end
	`STATE_VERIFY_STOP: begin
	    sampleFlag <= 1'b0;
	    delayCtr <= delayCtr - 8'h1;
	    if(delayCtr == 8'h0) begin
		sampleFlag <= 1'b1;
		if( Serin == 1'b1 )
		    readyFlag <= 1'b1;
		else
		    errorFlag <= 1'b1;
		stateMachine <= `STATE_LISTENING;
	    end
	end
    endcase
    end
end

endmodule
