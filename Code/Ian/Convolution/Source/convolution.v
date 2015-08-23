module convolution (
	input 				iCLK_50,
	
	input		[17:0]	iSW,
	input 	[3:0]		iKEY,
	
	output	[17:0]	oLEDR,
	output	[8:0]		oLEDG,
	
	output	[6:0]		oHEX0_D, oHEX1_D, oHEX2_D, oHEX3_D, oHEX4_D, oHEX5_D, oHEX6_D, oHEX7_D,
	
	inout		[31:0]	GPIO_0, GPIO_1
);

	wire [31:0] filter_dataOut;

	FIR_FILTER filter_instant(
    .inData		(),
    .CLK			(iCLK_50),
    .outData	(filter_dataOut),
    .reset		(iKEY[0])
);

endmodule
