module Counter(
	iCLK_50, 
	
	iSW,
	
	oLEDR,
	oLEDG);

//======================
// Ports:
//======================
	
	input					iCLK_50;
	
	input		[17:0]	iSW;

	output	[17:0]	oLEDR;
	output 	[7:0]		oLEDG;
	
//======================
// Declaration:
//======================

	parameter clk_1Hz_n = 27;
	parameter clk_1Hz_MSB = clk_1Hz_n - 1;

	reg 		[clk_1Hz_MSB:0]	clk_1Hz;
	reg		[7:0]				counter;
	
	
//======================
// User Code:
//======================

	always @(posedge iCLK_50)
	begin
		if (clk_1Hz[clk_1Hz_MSB])
			clk_1Hz <= 0;
		else
			clk_1Hz <= clk_1Hz + 1;
	end
		
	always @(posedge clk_1Hz[clk_1Hz_MSB])
	begin
		counter <= counter + 1;
	end
		
	assign oLEDG = counter;
	
	assign oLEDR = iSW;

endmodule
