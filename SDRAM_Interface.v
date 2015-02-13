/*
 * This module interfaces to a SDRAM chip. It requires that all incoming
 * datalines are stable on the rising edge of the Clk. If this is not the
 * case, make it.
 */
module SDRAM_Interface( input Clk, // The 100 MHz clock, internal logic on rising edge, SDRAM clock is negedge
    input wire [15:0]DataIn,	    // Input data, must be stable on rising edge of clock
    output reg [15:0]DataOut,	    // Output data
    input [21:0]Address,  // Input address of data
    input Req,	    // Request a read/write from the controller
    input WnR,	    // Write not Read
    input Reset,	    // Reset, synchronous
    output wire Busy,	    // Output: Busy flag, controller is doing something (perhaps some global refresh)
    output reg Ack,	    // Output: Acknowledgement of the request
    output reg Err,	    // Output: Error flag, perhaps the state machine entered an unspecified state
    // The following are input/outputs to the SDRAM chip, simple wire them
    // through
    output reg [11:0]DRAM_ADDR, 
    inout [15:0]DRAM_DQ, 
    output reg DRAM_BA_0, 
    output reg DRAM_BA_1, 
    output reg DRAM_LDQM, 
    output reg DRAM_UDQM, 
    output reg DRAM_WE_N, 
    output reg DRAM_CAS_N, 
    output reg DRAM_RAS_N, 
    output wire DRAM_CS_N, 
    output wire DRAM_CLK, 
    output wire DRAM_CKE);

`define STATE_IDLE		    0	    // Doing nothing at all, just waiting for stuff to happen
`define STATE_START_WRITE	    1
`define STATE_START_READ	    2
`define STATE_INIT		    255	    // First phase of the init, wait for 250us with no command
`define STATE_INIT_PCHGA	    254	    // Precharge all banks in the init routine
`define STATE_INIT_RAS_TIMEOUT	    253	    // Wait a while after opening a row (tRAS timeout)
`define STATE_INIT_ISSUE_PCHG	    252
`define STATE_INIT_TRP_TIMEOUT	    251
`define STATE_INIT_CMD		    250
//`define STATE_PRECHARGE_ALL 20

`define REFRESH_TIME	32'h810000	// A little less than 64ms @ 133MHz
`define INIT_TIME	16'h8000	// A little more than 250us @ 133MHz

`define tRAS		16'h7		// t_RAS @ 133MHz
`define tRP		16'h3		// t_PD (row precharge time)


reg [15:0]  shadowData;	// Local copy of the data to write
reg [11:0]  row;	// The row part of the address
reg [7:0]   col;	// The column part of the address
reg [1:0]   bank;	// The bank of the SDRAM
reg [7:0]   state;	// The state-machine register
reg [31:0]  refreshCtr;	// This counts backward, when zero a global refresh is necessary
reg [15:0]  timeCtr;	// This counts backwards to time the initialization time (PLL lock for SDRAM?)
reg [3:0]   initCtr;	// This counts the number of global refreshes to go (start from 8)

// We don't need these for the DE0 SDRAM, else... mod my code ;-)
assign DRAM_CKE = 1'b1;
assign DRAM_CS_N = 1'b0;

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

always @(posedge Clk) begin
    if( refreshCtr != 0 )
	refreshCtr <= refreshCtr - 32'h1;
end

always @(posedge Clk) begin
    if(Reset) begin
	state	    <= `STATE_INIT;
	Err	    <= 1'b0;
	refreshCtr  <= `REFRESH_TIME;
	timeCtr	    <= `INIT_TIME;
	initCtr	    <= 4'h8;
	DRAM_RAS_N  <= 1'b1;
	DRAM_CAS_N  <= 1'b1;
	DRAM_WE_N   <= 1'b1;
    end else begin
    case(state)
	`STATE_INIT: begin
	    // Asserting everything high/idle, we wait for 250us 
	    if( timeCtr == 16'h0000 ) begin
		state	<= `STATE_INIT_PCHGA; // Start to precharge all the banks
		row	<= 12'hFFF;
	    end else begin
		timeCtr <= timeCtr - 16'b1;
	    end
	end
	// In this state we first open each row to successively precharge it
	`STATE_INIT_PCHGA: begin
	    // If we did it 8 times, we can set up the command register
	    if( initCtr == 4'h0 ) begin
		state <= `STATE_INIT_CMD;
	    end else begin
		// This is the "OPEN ROW" command
		DRAM_RAS_N  <= 1'b0;
		DRAM_CAS_N  <= 1'b1;
		DRAM_WE_N   <= 1'b1;
		DRAM_ADDR   <= row;
		// Wait for a time t_RAS
		state	    <= `STATE_INIT_RAS_TIMEOUT;
		timeCtr	    <= `tRAS;
		// Check if this was the last row of a series
		if( row == 12'h000 ) begin
		    // If so, mark one down (we need eight in total)
		    initCtr <= initCtr - 4'h1;
		    // Reset the row to the starting point
		    row	    <= 12'hFFF;
		end else
		    // It wasn't the last row, simply decrease
		    row <= row - 12'h1;
	    end
	end
	// This state simply sets the NOP command and waits for time t_RAS
	`STATE_INIT_RAS_TIMEOUT: begin
	    // "NOP" command
	    DRAM_RAS_N	<= 1'b1;
	    DRAM_CAS_N	<= 1'b1;
	    DRAM_WE_N	<= 1'b1;

	    if(timeCtr ==  16'h0) begin
		// After waiting long enough, we can now issue the precharge
		// all command 
		state <= `STATE_INIT_ISSUE_PCHG;
	    end else begin
		timeCtr <= timeCtr - 16'h1;
	    end
	end
	// This state issues the "PRECHARGE ALL BANKS" command
	`STATE_INIT_ISSUE_PCHG: begin
	    DRAM_ADDR[10]   <= 1'b1; // Precharge all banks, makes life just a little easier
	    // This is the precharge all command
	    DRAM_RAS_N	    <= 1'b0;
	    DRAM_CAS_N	    <= 1'b1;
	    DRAM_WE_N	    <= 1'b0;
	    // Wait for a time t_RP
	    state	    <= `STATE_INIT_TRP_TIMEOUT;
	    timeCtr	    <= `tRP;
	end
	// This state waits for a time t_RP, leaving the command untouched
	// (allowed as by the datasheet)
	`STATE_INIT_TRP_TIMEOUT: begin
	    // "NOP" command
	    DRAM_RAS_N	<= 1'b1;
	    DRAM_CAS_N	<= 1'b1;
	    DRAM_WE_N	<= 1'b1;
	    if(timeCtr == 16'h0) begin
		// If the time has expired we return the state that counts
		// down rows and checks if they need to be precharged
		state <= `STATE_INIT_PCHGA;
	    end else
		timeCtr <= timeCtr - 16'h1;
	end
	`STATE_IDLE: begin
	    Ack <= 1'b0;
	    if( refreshCtr == 32'h0 ) begin
		//state <= `STATE_PRECHARGE_ALL;
		state <= `STATE_IDLE;
	    end else if(Req) begin
		Ack <= 1'b1;
		shadowData <= DataIn;
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
	default: begin
	    state <= `STATE_IDLE;
	    Err <= 1'b1;
	end
    endcase
    end
end

endmodule
