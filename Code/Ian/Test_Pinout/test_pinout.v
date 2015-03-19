module test_pinout(
	iCLK_50,
	iSW,
	
	oLEDR,
	oLEDG);

//=======================================
// Ports:
//=======================================
	input						iCLK_50;
	
	input		[17:0]		iSW;
	
	output	[17:0]		oLEDR;
	output	[7:0]			oLEDG;

	
//=======================================
// User Code:
//=======================================
	assign oLEDR = iSW;

	
	
endmodule
