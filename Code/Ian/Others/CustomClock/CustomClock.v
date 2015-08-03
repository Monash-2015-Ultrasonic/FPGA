module CustomClock(
	iCLK_50,
	c0,
	
	//iSW,
	
	oLEDR,
	oLEDG
	);

//======================
// Ports:
//======================	
	input					iCLK_50;
	output				c0;
	
	//input		[17:0]	iSW;

	output	[17:0]	oLEDR;
	output 	[7:0]		oLEDG;
	
//======================
// Declaration:
//======================

	parameter clk_1Hz_n = 27;
	parameter clk_1Hz_MSB = clk_1Hz_n - 1;
	
	parameter clk_0Hz8_n = 26;
	parameter clk_0Hz8_MSB = clk_0Hz8_n - 1;

	reg 		[clk_1Hz_MSB:0]	clk_1Hz;
	reg		[clk_0Hz8_MSB:0]	clk_0Hz8;
	
	reg		[7:0]					counter;
	reg		[7:0]					counter2;
	
//======================
// Instantiation:
//======================	
	
	PllClock	PllClock_inst(
		.inclk0 (iCLK_50),
		.c0 (c0)
	);
	
//======================
// User Code:
//======================
	
	//--------------------------------
	//     50MHz, 1.34s counter
	//--------------------------------
	always @(posedge iCLK_50)
	begin
		if (clk_1Hz[clk_1Hz_MSB])
			clk_1Hz = 0;
		else
			clk_1Hz = clk_1Hz + 1;
	end
		
	always @(posedge clk_1Hz[clk_1Hz_MSB])
	begin
		counter = counter + 1;
	end
		
	assign oLEDG = counter;
	
	//--------------------------------
	//     40MHz, 0.84s counter
	//--------------------------------
	always @(posedge c0)
	begin
		if (clk_0Hz8[clk_0Hz8_MSB])
			clk_0Hz8 = 0;
		else
			clk_0Hz8 = clk_0Hz8 + 1;
	end
		
	always @(posedge clk_0Hz8[clk_0Hz8_MSB])
	begin
		counter2 = counter2 + 1;
	end
	
	assign oLEDR = counter2;
	
	//assign oLEDR = iSW;

endmodule
