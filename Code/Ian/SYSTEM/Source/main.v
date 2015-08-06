//=================================================
// TOPLEVEL MODULE
//=================================================
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
// Custom/System Clock using PLL IP:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// 70MHz and 41.176471MHz clock:
	wire 					CLK_FAST, CLK_40;
	CLKPLL				CLKPLL_inst (
		.inclk0 			( iCLK_50 	),
		.c0 				( CLK_FAST 	),
		.c1				( CLK_40		)
	);
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Connections from GPIO:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg RST;
	always @(posedge CLK_FAST)
		RST <= ~iKEY[0];

	reg ON;
	always @(posedge CLK_FAST)
		ON <= iSW[9];
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Transmitter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Generate 40.21139746kHz pulse for the Ultrasonic Transmitter:
	reg [9:0] usonic;
	always @(posedge CLK_40)
		usonic <= usonic + 1;
	
	// Generate a burst of 32 pulses, then wait approx 14ms:
	reg [9:0] counter_burst;
	always @(posedge usonic[9])
		counter_burst <= ~RST & ON & (counter_burst < 574) ? counter_burst + 1 : 0;
	
	reg usonicpulse;
	always @(posedge CLK_40)
		usonicpulse <= usonic[9] & (counter_burst < 32);

	assign GPIO_1[24] = usonicpulse 	& ~RST & ON;	
	assign GPIO_1[25] = ~usonicpulse & ~RST & ON;

	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// ADC Modules:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	wire		[15:0]	ADC_CMD = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire 		[15:0] 	ADC0_DATA, ADC1_DATA, ADC2_DATA, ADC3_DATA, ADC4_DATA;
	wire		[4:0]		ADC_FIN;

	// Impedance Matching for Enable/CSbar pin:
	assign 				GPIO_1[31:26] = 6'bzzzzzz;				
	
	// Auto-sample at 68.359375 (10bits) / 273.4375 (8bits) kHz:
	parameter sampler_bits = 8;
	parameter sampler_topbit = sampler_bits - 1;
	reg [sampler_topbit:0] clk_sample;
	always @(posedge CLK_FAST)
		clk_sample <= ~RST & ON ? clk_sample + 1 : 0;
		
	wire ADC0_EN = ~clk_sample[sampler_topbit] & ~RST & ON & ~ADC_OFF;
	//wire ADC0_EN = ~&clk_sample[sampler_topbit:sampler_topbit-1] & ~RST & ON & ~ADC_OFF; 	// Variable duty cycle
	
	// Edge Detector for WR sinal to FIFO:
	reg WR_PREV, WR_EDGE;
	always @(posedge CLK_FAST) begin
		WR_PREV <= ADC_FIN[0];
		WR_EDGE <= ~WR_PREV & ADC_FIN[0] & ~ADC_OFF & ~RST & ON ? 1 : 0;
	end
	
	// Turn off all sampling when FIFO overflows:
	reg ADC_OFF, FIFO_FULL_PREV;
	always @(posedge CLK_FAST) begin
		FIFO_FULL_PREV <= FIFO_ADC0_FULL;
		
		if (RST | ~ON)
			ADC_OFF <= 0;
		else 
			ADC_OFF <= ~FIFO_FULL_PREV & FIFO_ADC0_FULL ? 1 : ADC_OFF;
	end
	
	// ADC SPI Master Module:
	SPI_MASTER_ADC # (.outBits (16)) ADC0_instant(
		.SYS_CLK 	( CLK_FAST						),
		.ENA 			( ADC0_EN 					),  	
		.DATA_MOSI 	( ADC_CMD 					),		// Command written to ADC
		.MISO 		( GPIO_0[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[5] 				),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_FIN[0] 				),		// Sample from ADC
		.DATA_MISO 	( ADC0_DATA 				)	
	);
	
	// Connect signals to Green LEDs:
	assign oLEDG[7] 	= ADC0_EN;
	assign oLEDG[4:0] = ADC_FIN;

	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIFO: 16-bits width, 16384-words depth
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	wire		[15:0]	FIFO_ADC0_OUT;	
	wire 					FIFO_ADC0_EMPTY, FIFO_ADC0_FULL;
	
	// Altera IP FIFO Module:
	FIFO_IP	FIFO_IP_inst (
		.clock 	( CLK_FAST 				),
		.sclr 	( RST 					),				// Synchronous Clear
		.rdreq 	( MBED_FIN_EDGE 		),				// Read when MBED has finished
		.wrreq 	( WR_EDGE 				),				// Write when a sample is ready
		.data 	( ADC0_DATA>>1 		),				
		.empty 	( FIFO_ADC0_EMPTY 	),
		.full 	( FIFO_ADC0_FULL 		),
		.q 		( FIFO_ADC0_OUT 		)
	);
	
	// Connect signals to Red LEDs:	
	assign oLEDR[16] = FIFO_ADC0_EMPTY;
	assign oLEDR[17] = FIFO_ADC0_FULL;
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~			
	reg [1:0] counter_report;
	reg [16:0] counter_wait;
	reg MBED_ALLOWED = 0;
	always @(posedge CLK_FAST) begin
		case (counter_report)
		3: begin
				case (counter_wait)
				//63000: begin
				75000: begin
					counter_report <= 0;
					counter_wait <= 0;
					MBED_ALLOWED <= 1;
				end 
				
				default: begin
					counter_wait <= counter_wait + 1;
					MBED_ALLOWED <= 0;
				end 
				endcase 
		end 
		
		default: begin
			counter_report <= MBED_FIN_EDGE ? counter_report + 1 : counter_report;
			MBED_ALLOWED <= 1;
		end 
		endcase
	end 
	
	// Generate clock to output data to MBED periodically: same rate as sampler
	parameter mbed_clk_bits = sampler_bits;
	reg [mbed_clk_bits-1:0] MBED_CLK;
	always @(posedge CLK_FAST)
		MBED_CLK 		<= ~RST & ON ? MBED_CLK + 1 : 0;
	
	// Edge Detector for MBED periodic data output clock:
	reg MBED_CLK_PREV, MBED_CLK_EDGE;
	always @(posedge CLK_FAST) begin
		MBED_CLK_PREV 	<= MBED_CLK[mbed_clk_bits-1];
		MBED_CLK_EDGE 	<= ~MBED_CLK_PREV & MBED_CLK[mbed_clk_bits-1] ? 1 : 0;
	end
	
	// Edge Detector for when single write to MBED finishes:
	wire MBED_FIN;
	reg MBED_FIN_PREV, MBED_FIN_EDGE;
	always @(posedge CLK_FAST) begin
		MBED_FIN_PREV <= MBED_FIN;
		MBED_FIN_EDGE <= ~MBED_FIN_PREV & MBED_FIN ? 1 : 0;
	end
	
	// Control logic to enable SPI to MBED:
	reg MBED_ON;
	always @(posedge CLK_FAST) begin
		//if (MBED_CLK_EDGE | manual_wr_mbed_edge)
		if (MBED_CLK_EDGE)
			MBED_ON 		<= ~FIFO_ADC0_EMPTY & MBED_ALLOWED ? 1 : 0;
		else 
			MBED_ON 		<= ~MBED_FIN ? MBED_ON : 0;	
	end
	
	// MBED SPI Master Module:
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_FAST				),
		.RST			( 						),
		.ENA 			( MBED_ON   		),  	
		.DATA_MOSI 	( FIFO_ADC0_OUT	),		
		.MISO 		( GPIO_1[0] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]			),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 		),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN			)
	); 

	// Connect signals to Green LEDs:
	assign oLEDG[8] 	= MBED_FIN;
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// 7-Seg Displays:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// ADC Data:
	HEX_ENCODER hex3(FIFO_ADC0_OUT[15:12], oHEX3_D);
	HEX_ENCODER hex2(FIFO_ADC0_OUT[11:8], 	oHEX2_D);
	HEX_ENCODER hex1(FIFO_ADC0_OUT[7:4], 	oHEX1_D);
	HEX_ENCODER hex0(FIFO_ADC0_OUT[3:0], 	oHEX0_D);
	
	// ADC #:
	HEX_ENCODER hex6(iSW[17:15], 				oHEX6_D);
	
	// Channel #:
	HEX_ENCODER hex4(iSW[1:0], 				oHEX4_D);
	
	// Turn off unnecessary 7-Seg Displays:
	HEX_ENCODER hex7(5'b11111, 				oHEX7_D);
	HEX_ENCODER hex5(5'b11111, 				oHEX5_D);	
	
	
	
	
endmodule
//=================================================
// END TOPLEVEL MODULE
//=================================================
