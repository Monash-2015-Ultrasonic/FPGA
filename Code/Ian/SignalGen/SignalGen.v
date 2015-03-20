module SignalGen( 
	iCLK_50,
	CLK_PLL_41MHz0256,
	
	GPIO_0,
	
	iSW,
	
	oLEDG,
	oLEDR
	);

//==================================
// Ports:
//==================================
	input 				iCLK_50;
	
	output 				CLK_PLL_41MHz0256;
	
	input		[17:0]	iSW;
	
	output 	[31:0]	GPIO_0;
	
	output	[7:0]		oLEDG;
	output	[17:0]	oLEDR;


//==================================
// Declarations and Instantiations:
//==================================
	CLK_PLL CLK_PLL_inst(
		iCLK_50,
		CLK_PLL_41MHz0256
		);
	
	parameter 	clk_40kHz_n 			= 10;
	parameter 	clk_40kHz_MSB 			= clk_40kHz_n - 1;
	
	reg			[clk_40kHz_MSB:0]	 	clk_40kHz;		
	reg			[2:0]						counter_pulses = 2'b0;


//==================================
// User code:
//==================================

	// Generate a 40.064kHz Square Wave with 50% duty cycle
	always @(posedge CLK_PLL_41MHz0256)
	begin
			clk_40kHz = clk_40kHz + 1;
	end
	
	always @(negedge clk_40kHz[clk_40kHz_MSB])
	begin
			counter_pulses = counter_pulses + 1;
	end
	
	// Send only bursts of 4 pulses, wait 5 periods: |-|_|-|_|-|_|-|_|-|________________|-|_|-|_|-|_|-|_|-|________________
	assign GPIO_0[0] = clk_40kHz[clk_40kHz_MSB] && ~counter_pulses[2];
	
	// Have 40kHz Square Wave with 50% duty cycle as reference:
	assign GPIO_0[1] = clk_40kHz[clk_40kHz_MSB];
	
endmodule
