//=================================================
// SPI MASTER MODULE
//=================================================
module master(
	input			SPI_CLK,
	input 		ENA,
	input 		MISO,
	output reg 	MOSI,
	output reg 	CSbar,
	output  		SCK,
	output reg 	FIN,
	output reg [15:0]	DATA
	);	

	reg	[15:0]	data_in 	= 16'b0;
	reg				finished = 1'b0;
	reg	[4:0]		counter 	= 5'b0;
	
	assign SCK = SPI_CLK;
	
	always @(posedge SCK) begin
		if (CSbar) begin
			counter 		<= 1'b0;
			finished 	<= 1'b0;
		end
		
		else if (~CSbar && ~finished) begin
			//MOSI <= data_m[15];
				
			data_in 		<= {data_in[14:0], MISO};
				
			counter 		<= counter + 1;
				
			if (counter == 16) 
				finished <= 1'b1;
		end
		else if (~CSbar && finished) 	
			finished 	<= 1'b1;
		else
			finished 	<= 1'b0;
	end
	
	always @(posedge SCK) begin
		CSbar 		<= ~ENA;
		FIN 			<= finished;
		DATA	 		<= data_in;
	end
	
endmodule
//=================================================
// END SPI MASTER MODULE
//=================================================




//=================================================
// TOP LEVEL MODULE
//=================================================
module stimulus(
	input 					iCLK_50,
	input 		[17:0] 	iSW,
	input 		[3:0] 	iKEY,
	
	output  		[17:0]	oLEDR,
	output  		[7:0]		oLEDG,
	
	inout			[31:0]	GPIO_0
	);
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// User declarations & instantiations:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	wire CLK_50;
	wire CLK_20;
	wire CLK_10;
	
	CLK_PLL	CLK_PLL_inst (
		.inclk0 ( iCLK_50 ),
		.c0 (	CLK_50 ),
		.c1 ( CLK_20 ),
		.c2 ( CLK_10 )
	);
	
	master SPI_MASTER_INSTANT(
		.SPI_CLK ( CLK_20 	),
		.ENA 		( cnt[19]		),
		.SCK 		( GPIO_0[5] ),
		.MOSI 	( GPIO_0[0] ),
		.MISO 	( GPIO_0[1] ),
		.CSbar 	( GPIO_0[3] ),
		.FIN 		( oLEDG[7] 	),
		.DATA 	( oLEDR[15:0] )
		);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// User code:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	reg [19:0] cnt;						// 47.68 Hz update
	
	always @(posedge CLK_50) begin
		cnt <= cnt + 1;
	end

endmodule
