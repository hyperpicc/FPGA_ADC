module FPGA_ADC( BUTTON[2:0], HEX0_D[6:0], HEX1_D[6:0], CLOCK_50, GPIO0_D[8:0] );

input [2:0]BUTTON;
input CLOCK_50;
inout [8:0]GPIO0_D;

output [6:0]HEX0_D;
output [6:0]HEX1_D;

wire ADC_Clk;
wire [7:0]binaryOut;
wire compIn;

assign GPIO0_D[8:0] = {1'bz, binaryOut[7:0]};
assign compIn = GPIO0_D[8];


assign GPIO0_D[7:0] = binaryOut;

ADC_PLL ADC_pll (, CLOCK_50, ADC_Clk,);

SAR_ADC adc(ADC_Clk, compIn, BUTTON[0], , binaryOut);

segdriver hex0(binaryOut[7:4], HEX0_D[6:0]);
segdriver hex1(binaryOut[3:0], HEX1_D[6:0]);

endmodule
