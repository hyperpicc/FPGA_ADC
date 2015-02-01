module FPGA_ADC( BUTTON[2:0], HEX0_D[6:0], HEX1_D[6:0], CLOCK_50, GPIO0_D[8:0], UART_TXD );

input [2:0]BUTTON;
input CLOCK_50;
inout [8:0]GPIO0_D;

output [6:0]HEX0_D;
output [6:0]HEX1_D;
output UART_TXD;

wire ADC_Clk;
wire UART_Clk;
wire [7:0]binaryOut;
wire compIn;

reg [7:0] UART_Data;
reg UART_Start;
wire UART_Done;

assign GPIO0_D[8:0] = {1'bz, binaryOut[7:0]};
assign compIn = GPIO0_D[8];

assign GPIO0_D[7:0] = binaryOut;

ADC_PLL ADC_pll (, CLOCK_50, ADC_Clk, UART_Clk,);

SAR_ADC adc(ADC_Clk, compIn, BUTTON[0], , binaryOut);

segdriver hex0(binaryOut[7:4], HEX0_D[6:0]);
segdriver hex1(binaryOut[3:0], HEX1_D[6:0]);

UART_TX UART_module( UART_Clk, UART_Data, UART_Start, UART_TXD, UART_Done);

always @(posedge CLOCK_50) begin
    if( UART_Done & ~BUTTON[0] ) begin
	UART_Start <= 1'b1;
	case(UART_Data)
	    8'h00: UART_Data <= 8'h41;
	    8'h41: UART_Data <= 8'h42;
	    8'h42: UART_Data <= 8'h0A;
	    8'h0A: UART_Data <= 8'h0D;
	    8'h0D: UART_Data <= 8'h00;
	endcase
    end
end

endmodule
