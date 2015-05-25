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
	wire 					CLK_40;
	CLKPLL				CLKPLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	)
	);
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Connections from GPIO:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg RST;
	always @(posedge CLK_40)
		RST <= ~iKEY[0];

	reg ON;
	always @(posedge CLK_40)
		ON <= iSW[9];
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Transmitter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Generate 39.0625kHz pulse for the Ultrasonic Transmitter:
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
	
	// Auto-sample at 625kHz:
	parameter sampler_bits = 6;
	parameter sampler_topbit = sampler_bits - 1;
	reg [sampler_topbit:0] clk_sample;
	always @(posedge CLK_40)
		clk_sample <= ~RST & ON ? clk_sample + 1 : 0;
		
	//wire ADC0_EN = ~&clk_sample[sampler_topbit] & ~RST & ON;
	wire ADC0_EN = ~&clk_sample[sampler_topbit:sampler_topbit-1] & ~RST & ON & ~ADC_OFF; 	// Variable duty cycle
	
	// Edge Detector for WR sinal to FIFO:
	reg WR_PREV, WR_EDGE;
	always @(posedge CLK_40) begin
		WR_PREV <= ADC_FIN[0];
		WR_EDGE <= ~WR_PREV & ADC_FIN[0] & ~ADC_OFF & ~RST & ON ? 1 : 0;
	end
	
	// Turn off all sampling when FIFO overflows:
	reg ADC_OFF, FIFO_FULL_PREV;
	always @(posedge CLK_40) begin
		FIFO_FULL_PREV <= FIFO_ADC0_FULL;
		
		if (RST | ~ON)
			ADC_OFF <= 0;
		else 
			ADC_OFF <= ~FIFO_FULL_PREV & FIFO_ADC0_FULL ? 1 : ADC_OFF;
	end
	
	// ADC SPI Master Module:
	SPI_MASTER_ADC # (.outBits (16)) ADC0_instant(
		.SYS_CLK 	( CLK_40						),
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
		.clock 	( CLK_40 				),
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
	// Generate clock to output data to MBED periodically: 2kHz
	parameter mbed_clk_bits = 14;
	reg [mbed_clk_bits-1:0] MBED_CLK;
	always @(posedge CLK_40)
		MBED_CLK 		<= ~RST & ON ? MBED_CLK + 1 : 0;
	
	// Edge Detector for MBED periodic data output clock:
	reg MBED_CLK_PREV, MBED_CLK_EDGE;
	always @(posedge CLK_40) begin
		MBED_CLK_PREV 	<= MBED_CLK[mbed_clk_bits-1];
		MBED_CLK_EDGE 	<= ~MBED_CLK_PREV & MBED_CLK[mbed_clk_bits-1] ? 1 : 0;
	end
	
	// Edge Detector for when single write to MBED finishes:
	wire MBED_FIN;
	reg MBED_FIN_PREV, MBED_FIN_EDGE;
	always @(posedge CLK_40) begin
		MBED_FIN_PREV <= MBED_FIN;
		MBED_FIN_EDGE <= ~MBED_FIN_PREV & MBED_FIN ? 1 : 0;
	end
	
	// Control logic to enable SPI to MBED:
	reg MBED_ON;
	always @(posedge CLK_40) begin
		//if (MBED_CLK_EDGE | manual_wr_mbed_edge)
		if (MBED_CLK_EDGE)
			MBED_ON 		<= ~FIFO_ADC0_EMPTY ? 1 : 0;
		else 
			MBED_ON 		<= ~MBED_FIN ? MBED_ON : 0;	
	end
	
	// MBED SPI Master Module:
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_40				),
		.RST			( 						),
		.ENA 			( MBED_ON & ~FIFO_ADC0_EMPTY  ),  	
		.DATA_MOSI 	( FIFO_ADC0_OUT	),		
		.MISO 		( GPIO_1[0] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]			),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 		),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN			)
	); 

	// Connect signals to Green LEDs:
	assign oLEDG[8] 	= MBED_FIN;

	
	// Code to enable switching between ADC Modules:
/*	
	always @(posedge CLK_40) begin
		case (iSW[17:15])
		4'b0000: begin
			ADC_data <= ADC0_data;
		end
		
		4'b0001: begin
			ADC_data <= ADC1_data;
		end
		
		4'b0010: begin
			ADC_data <= ADC2_data;
		end
		
		4'b0011: begin
			ADC_data <= ADC3_data;
		end
		
		4'b0100: begin
			ADC_data <= ADC4_data;
		end
		
		default: 
			ADC_data <= 16'hFFFF;
		endcase
	end
*/
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// 7-Seg Displays:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// ADC Data:
	HEX_ENCODER hex3(FIFO_ADC0_OUT[15:12], oHEX3_D);
	HEX_ENCODER hex2(FIFO_ADC0_OUT[11:8], 	oHEX2_D);
	HEX_ENCODER hex1(FIFO_ADC0_OUT[7:4], 	oHEX1_D);
	HEX_ENCODER hex0(FIFO_ADC0_OUT[3:0], 	oHEX0_D);
	
/*
	HEX_ENCODER hex3(ADC0_data[15:12], 	oHEX3_D);
	HEX_ENCODER hex2(ADC0_data[11:8], 	oHEX2_D);
	HEX_ENCODER hex1(ADC0_data[7:4], 	oHEX1_D);
	HEX_ENCODER hex0(ADC0_data[3:0], 	oHEX0_D);
*/
	
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
