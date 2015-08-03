module main(
	input 				iCLK_50,
	
	input		[17:0]	iSW,
	input 	[3:0]		iKEY,
	
	output	[17:0]	oLEDR,
	output	[8:0]		oLEDG,
	
	output	[6:0]		oHEX0_D, oHEX1_D, oHEX2_D, oHEX3_D, oHEX4_D, oHEX5_D, oHEX6_D, oHEX7_D,
	
	inout		[31:0]	GPIO_0, GPIO_1
);




//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Custom/System clock:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 				CLK_65, CLK_40;
	CLKPLL			CLKPLL_inst (
		.inclk0 		( iCLK_50 	),
		.c0 			( CLK_65 	),
		.c1			( CLK_40		)
	);
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Interactive connections:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg RST;
	always @(posedge CLK_65)
		RST <= ~iKEY[0];

	reg ON;
	always @(posedge CLK_65)
		ON <= iSW[9];
		

		
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Counter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			
	// Auto-sample at approx. 63kHz:
	parameter sampler_bits = 10;
	parameter sampler_topbit = sampler_bits - 1;
	reg [sampler_topbit:0] clk_sample;
	always @(posedge CLK_65)
		clk_sample <= ~RST ? clk_sample + 1 : 0;
		
	reg [15:0] check_counter;
	always @(posedge clk_sample[sampler_topbit])
		check_counter <= ~RST & ON & ~sampler_off ? (check_counter + 1) : 0;
	
	// Edge Detector for WR sinal to FIFO:
	reg WR_PREV, WR_EDGE;
	always @(posedge CLK_65) begin
		WR_PREV <= clk_sample[sampler_topbit];
		WR_EDGE <= ~WR_PREV & clk_sample[sampler_topbit] & ~sampler_off & ~RST & ON ? 1 : 0;
	end

	// Turn off all sampling when FIFO overflows:
	reg sampler_off, FIFO_FULL_PREV;
	always @(posedge CLK_65) begin
		FIFO_FULL_PREV <= FIFO_FULL;
		
		if (RST | ~ON)
			sampler_off <= 0;
		else 
			sampler_off <= ~FIFO_FULL_PREV & FIFO_FULL ? 1 : sampler_off;
	end
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIFO: 16-bits width, 16384-words depth
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	wire		[15:0]	FIFO_OUT;	
	wire 					FIFO_EMPTY, FIFO_FULL;
	
	// Altera IP FIFO Module:
	FIFO_IP	FIFO_IP_inst (
		.clock 	( CLK_65 				),
		.sclr 	( RST 					),				// Synchronous Clear
		.rdreq 	( MBED_FIN_EDGE 		),				// Read when MBED has finished
		.wrreq 	( WR_EDGE 				),				// Write when a sample is ready			
		.data 	( check_counter		),
		.empty 	( FIFO_EMPTY 	),
		.full 	( FIFO_FULL 		),
		.q 		( FIFO_OUT 		)
	);
	
	// Connect signals to Red LEDs:	
	assign oLEDR[16] = FIFO_EMPTY;
	assign oLEDR[17] = FIFO_FULL;
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			
	// Generate clock to output data to MBED periodically: 
	parameter mbed_clk_bits = 15;
	reg [mbed_clk_bits-1:0] MBED_CLK;
	always @(posedge CLK_65)
		MBED_CLK 		<= ~RST & ON ? MBED_CLK + 1 : 0;
	
	// Edge Detector for MBED periodic data output clock:
	reg MBED_CLK_PREV, MBED_CLK_EDGE;
	always @(posedge CLK_65) begin
		MBED_CLK_PREV 	<= MBED_CLK[mbed_clk_bits-1];
		MBED_CLK_EDGE 	<= ~MBED_CLK_PREV & MBED_CLK[mbed_clk_bits-1] ? 1 : 0;
	end
	
	// Edge Detector for when single write to MBED finishes:
	wire MBED_FIN;
	reg MBED_FIN_PREV, MBED_FIN_EDGE;
	always @(posedge CLK_65) begin
		MBED_FIN_PREV <= MBED_FIN;
		MBED_FIN_EDGE <= ~MBED_FIN_PREV & MBED_FIN ? 1 : 0;
	end
	
	// Control logic to enable SPI to MBED:
	reg MBED_ON;
	always @(posedge CLK_65) begin
		//if (MBED_CLK_EDGE | manual_wr_mbed_edge)
		if (MBED_CLK_EDGE)
			MBED_ON 		<= ~FIFO_EMPTY ? 1 : 0;
		else 
			MBED_ON 		<= ~MBED_FIN ? MBED_ON : 0;	
	end
	
	// MBED SPI Master Module:
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_65				),
		.RST			( 						),
		.ENA 			( MBED_ON & ~FIFO_EMPTY  ),  	
		.DATA_MOSI 	( FIFO_OUT	),		
		.MISO 		( GPIO_1[0] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]			),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 		),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN			)
	); 

	// Connect signals to Green LEDs:
	assign oLEDG[8] 	= MBED_FIN;
	 
	 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// 7-Seg Outputs:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	hex_encoder hex3(check_counter[15:12], 	oHEX3_D);
	hex_encoder hex2(check_counter[11:8], 	oHEX2_D);
	hex_encoder hex1(check_counter[7:4], 		oHEX1_D);
	hex_encoder hex0(check_counter[3:0], 		oHEX0_D);
	
	hex_encoder hex7(FIFO_OUT[15:12], 			oHEX7_D);
	hex_encoder hex6(FIFO_OUT[11:8], 			oHEX6_D);
	hex_encoder hex5(FIFO_OUT[7:4], 				oHEX5_D);
	hex_encoder hex4(FIFO_OUT[3:0], 				oHEX4_D);

endmodule
