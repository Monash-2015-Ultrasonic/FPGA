//=================================================
// ULTRASONIC RECEIVER MODULE
//=================================================
module ultrasonicReceiver # (parameter sampler_bits = 8, parameter FIR_COEFFS = 770)(
	input 						SYS_CLK,
	input 						RST, ON,
	
	input 						ADC_MISO,
	output  						ADC_MOSI,
	output  						ADC_CSbar,
	output 						ADC_SCK,
	input 	 	[1:0] 		ADC_channel_sel,
	
	input							burstSent,
	output		[9:0]			ARRIVAL_TIME
);
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Timer:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	detectionTimer timer_instant(
		.SYS_CLK			( SYS_CLK		),
		.SYS_RST			( RST 			), 
		.ON				( ON				),
		.timerRST		( burstSent		),
		.timerSTOP		( MATCH			),
		.timerOUTPUT	( ARRIVAL_TIME	)
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
	reg [sampler_bits - 1:0] clk_sample;
	always @(posedge SYS_CLK)
		clk_sample <= ~RST & ON ? clk_sample + 1 : 0;
				
	wire ADC_EN = ~clk_sample[sampler_bits - 1] & ~RST & ON & ~ADC_OFF;
	// When Sampling frequency is very high:
	//wire ADC0_EN = ~&clk_sample[sampler_bits - 1:sampler_bits - 2] & ~RST & ON & ~ADC_OFF; 	// Variable duty cycle
	
	// Edge Detector for WR sinal to FIFO:
	reg WR_PREV, WR_EDGE;
	always @(posedge SYS_CLK) begin
		WR_PREV <= ADC_FIN;
		WR_EDGE <= ~WR_PREV & ADC_FIN & ~ADC_OFF & ~RST & ON ? 1 : 0;
	end
	
	// Turn off all sampling when FIFO overflows:
	reg ADC_OFF,FIFO_FULL_PREV;
	always @(posedge SYS_CLK) begin
		FIFO_FULL_PREV <= FIFO_FULL;
		
		if (RST | ~ON)
			ADC_OFF <= 0;
		else 
			ADC_OFF <= ~FIFO_FULL_PREV & FIFO_FULL ? 1 : ADC_OFF; 
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
// FIFO: 16-bits width, 8192-words depth
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	wire 					FIFO_EMPTY, FIFO_FULL;
	wire		[15:0]	FIFO_OUT;	
	
	// Altera IP FIFO Module:
	FIFO_IP	FIFO_IP_inst (
		.clock 	( SYS_CLK 			),
		.sclr 	( RST 				),				// Synchronous Clear
		.rdreq 	( FIFO_READ 		),				
		.wrreq 	( WR_EDGE 			),				// Write when a sample is ready
		.data 	( ADC_DATA			),				
		.empty 	( FIFO_EMPTY 		),
		.full 	( FIFO_FULL 		),
		.q 		( FIFO_OUT 			)
	);	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIR Filter
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg FIFO_READ;
	always @(posedge SYS_CLK) begin
		FIFO_READ <= (~FIR_SINK_RDY | FIFO_EMPTY | RST | ~ON) ? 0 : 1;
	end

	wire FIR_SINK_RDY, FIR_SOURCE_VALID;
	wire [27:0] FIR_SOURCE;
	
	fir_filter	FIR_inst(
		.clk					( SYS_CLK 							),
		.reset_n				( ~RST 								),
		.ast_sink_ready	( FIR_SINK_RDY 					),
		.ast_sink_data		( FIFO_OUT[11:0] - 12'h5FA		),		
		.ast_sink_valid	( FIFO_READ							),
		.ast_sink_error	( 2'b00 								),
		.ast_source_ready	( 1'b1 								),
		.ast_source_data	( FIR_SOURCE 						),
		.ast_source_valid	( FIR_SOURCE_VALID				),
		.ast_source_error	( )
	);
		
	reg [9:0] FIFO_NORM_WR_COUNTER;
	always @(posedge SYS_CLK) begin
		FIFO_NORM_WR_COUNTER <= FIR_SOURCE_VALID & (FIFO_NORM_WR_COUNTER < FIR_COEFFS) ? FIFO_NORM_WR_COUNTER + 1 : FIFO_NORM_WR_COUNTER;
	end
	
	reg FIFO_NORM_READ;
	always @(posedge SYS_CLK) begin
		FIFO_NORM_READ <= FIR_SOURCE_VALID & (FIFO_NORM_WR_COUNTER > (FIR_COEFFS-1)) ? 1 : 0;
	end
	
	wire [23:0] FIFO_NORM_OUT;
	wire [23:0] currentXsquared = (FIFO_OUT[11:0] - 12'h5FA) * (FIFO_OUT[11:0] - 12'h5FA);
	wire FIFO_NORM_WR = FIFO_READ;
	FIFO_NORM FIFO_NORM_inst(
		.clock 	( SYS_CLK					),
		.data		( currentXsquared			),
		.rdreq	( FIFO_NORM_READ 			),
		.wrreq	( FIFO_NORM_WR				),
		.empty	( ),
		.full		( ),
		.q			( FIFO_NORM_OUT			)
	);	
	
	reg [23:0] sumXsquared;
	always @(posedge SYS_CLK) begin
		sumXsquared <= (FIR_SOURCE_VALID) ? sumXsquared + currentXsquared - FIFO_NORM_OUT : sumXsquared;
	end
	
	wire FIR_SOURCE_NEGATIVE;
	COMPARE_NEGATIVE compare_neg_inst(
		.dataa 	( FIR_SOURCE				),
		.alb 		( FIR_SOURCE_NEGATIVE	)
	);
	
	wire FIR_SOURCE_THRESHOLD;
	COMPARE_HUGE compare_huge_inst(
		.dataa 	( FIR_SOURCE * FIR_SOURCE	),
		.datab	( 10082342 * sumXsquared 	), // 0.5*20164685
		.agb		( FIR_SOURCE_THRESHOLD		)
	);
	
	reg FIR_MATCH;
	always @(posedge SYS_CLK) begin		
		FIR_MATCH <= (FIR_SOURCE_VALID & ~FIR_SOURCE_NEGATIVE & FIR_SOURCE_THRESHOLD) ? 1 : 0;
	end
	
	reg matchPREV, MATCH;
	always @(posedge SYS_CLK) begin
		matchPREV <= FIR_MATCH;
		
		if (burstSent | RST | ~ON) begin
			MATCH <= 0;
		end
		else begin
			MATCH <= ~matchPREV & FIR_MATCH ? 1 : MATCH;
		end
	end
	
endmodule
