//=================================================
// ULTRASONIC RECEIVER MODULE
//=================================================
module ultrasonicReceiver # (parameter sampler_bits = 8)(
	input 						SYS_CLK,
	input 						RST, ON,
	
	input 						ADC_MISO,
	output  						ADC_MOSI,
	output  						ADC_CSbar,
	output 						ADC_SCK,
	
	input 	 	[1:0] 		ADC_channel_sel,
	
	input 						READ_REQ,
	output 						EMPTY, FULL,
	output		[15:0]		OUTPUT

);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// ADC Module:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Command sent to ADC:
	reg		[15:0]	ADC_CMD;
	always @(posedge SYS_CLK) begin
		ADC_CMD = {4'b0001, 1'b1, 2'b0, ADC_channel_sel, 7'b1000000}; 
	end
	
	// Auto-sample at 68.359375 (10bits) / 273.4375 (8bits) kHz:
	parameter sampler_topbit = sampler_bits - 1;
	reg [sampler_topbit:0] clk_sample;
	always @(posedge SYS_CLK)
		clk_sample <= ~RST & ON ? clk_sample + 1 : 0;
				
	wire ADC_EN = ~clk_sample[sampler_topbit] & ~RST & ON & ~ADC_OFF;
	// When Sampling frequency is very high:
	//wire ADC0_EN = ~&clk_sample[sampler_topbit:sampler_topbit-1] & ~RST & ON & ~ADC_OFF; 	// Variable duty cycle
	
	// Edge Detector for WR sinal to FIFO:
	reg WR_PREV, WR_EDGE;
	always @(posedge SYS_CLK) begin
		WR_PREV <= ADC_FIN;
		WR_EDGE <= ~WR_PREV & ADC_FIN & ~ADC_OFF & ~RST & ON ? 1 : 0;
	end
	
	// Turn off all sampling when FIFO overflows:
	reg ADC_OFF,FIFO_FULL_PREV;
	always @(posedge SYS_CLK) begin
		FIFO_FULL_PREV <= FULL;
		
		if (RST | ~ON)
			ADC_OFF <= 0;
		else 
			ADC_OFF <= ~FIFO_FULL_PREV & FULL ? 1 : ADC_OFF; 
	end
	
	wire 		[15:0] 	ADC_DATA;
	wire					ADC_FIN;	
	// ADC SPI Master Module:
	SPI_MASTER_ADC #(.outBits (16)) ADC_instant(
		.SYS_CLK 	( SYS_CLK		),
		.ENA 			( ADC_EN 		),  	
		.DATA_MOSI 	( ADC_CMD 		),		// Command written to ADC
		.MISO 		( ADC_MISO 		),		// MISO  = SDO 		= 3
		.MOSI 		( ADC_MOSI		),		// MOSI  = SDI 		= 4
		.SCK 			( ADC_SCK		),		// SCK   = SCLK 		= 5
		.CSbar 		( ADC_CSbar 	),		// CSbar = CSbar 	   = 6
		.FIN 			( ADC_FIN 		),		
		.DATA_MISO 	( ADC_DATA 		)		// Sample from ADC
	);	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIFO: 16-bits width, 16384-words depth
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	wire		[15:0]	FIFO_OUT;	
	
	// Altera IP FIFO Module:
	FIFO_IP	FIFO_IP_inst (
		.clock 	( SYS_CLK 			),
		.sclr 	( RST 				),				// Synchronous Clear
		.rdreq 	( READ_REQ 			),				
		.wrreq 	( WR_EDGE 			),				// Write when a sample is ready
		.data 	( ADC_DATA			),				
		.empty 	( EMPTY 				),
		.full 	( FULL 				),
		.q 		( OUTPUT 			)
	);	
	
endmodule
