module SAR_ADC(clk, compIn, convStart, convStop, out[7:0]);

`define STATE_IDLE 0
`define STATE_INIT 1
`define STATE_SETBIT 2
`define STATE_CHECKBIT 3

input clk;
input compIn;
input convStart;
output convStop;

output [7:0]out;
reg [7:0] active_bit;
reg [7:0] ctr;
reg [7:0] state;
reg finished;

assign out = ctr;
assign convStop = finished;

always@(posedge clk, negedge convStart) begin
    // Check if we were requested to start a new conversion
    if(convStart == 1'b0) begin
	state <= `STATE_INIT;
    end else begin
	if(state == `STATE_INIT) begin
	    // In the initial state, the counter/adc/dac value is set to zero
	    // The first bit we will try is the MSB and the state machine
	    // advances to the SETBIT-state
	    ctr <= 8'h00;
	    active_bit <= 8'h80;
	    finished <= 1'b0;
	    state <= `STATE_SETBIT;
	end else if(state == `STATE_SETBIT) begin
	    // In this state we set a specific bit of the counter and advance
	    // to the next state which will check if this bit needs to be set
	    ctr <= ctr | active_bit; 
	    state <= `STATE_CHECKBIT;
	end else if(state == `STATE_CHECKBIT) begin
	    // In this state we compare the value of the DAC with the input to
	    // the ADC. If it too large, the bit we set in the previous step
	    // will need to be unset, else we can leave it as is
	    if(compIn == 1'b0)
		ctr <= ctr & (~active_bit);

	    // If this was the last bit, we can go to idle, else we advance to
	    // the next bit (LSB) and advance the state machine
	    if(active_bit == 8'h01) begin
		finished <= 1'b1;
		state <= `STATE_IDLE;
	    end else begin
		active_bit <= active_bit >> 1;
		state <= `STATE_SETBIT;
	    end
	end
    end
end

endmodule
