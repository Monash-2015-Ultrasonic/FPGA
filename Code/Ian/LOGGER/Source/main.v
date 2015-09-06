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
// Clocks:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// 70MHz and 41.176471MHz clock:
	wire 					CLK_FAST, CLK_40;
	CLKPLL				CLKPLL_inst (
		.inclk0 			( iCLK_50 						),
		.c0 				( CLK_FAST 						),
		.c1				( CLK_40							)
	);
			
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// I/O:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg RST;
	always @(posedge CLK_FAST)
		RST <= ~iKEY[0];

	reg ON;
	always @(posedge CLK_FAST)
		ON <= iSW[9];
			
	// Impedance Matching for Enable/CSbar pin:
	assign 				GPIO_1[31:26] = 6'bzzzzzz;	
			
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Transmitter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	ultrasonicTransmitter 	#(.initial_delay(0)) 		usonicTX_inst(
		.CLK_40 			( CLK_40 							),
		.RST				( RST 								), 
		.ON				( ON									),
		.pulseOutput	( GPIO_1[25:24]  					),
	);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Receiver Channel 0:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	wire 				CHANNEL0_EMPTY, CHANNEL0_FULL;
	wire [15:0]		CHANNEL0_OUTPUT;
	ultrasonicReceiver 		#(.sampler_bits(8)) 		usonicRX_ch0_inst(
		.SYS_CLK				( CLK_FAST						),
		.RST					( RST								), 
		.ON					( ON								),
		.ADC_MISO			( GPIO_0[0]						), // MISO = SDO 		= 3
		.ADC_MOSI			( GPIO_0[1]						),	// MOSI = SDI 		= 4
		.ADC_SCK				( GPIO_0[3]						), // SCK = SCLK 		= 5
		.ADC_CSbar			( GPIO_0[5]						), // CSbar = CSbar 	= 6
		.ADC_channel_sel	( iSW[1:0]						),
		.READ_REQ 			( UC_FIN_EDGE 					),
		.EMPTY				( CHANNEL0_EMPTY				), 
		.FULL					( CHANNEL0_FULL				),
		.OUTPUT				( CHANNEL0_OUTPUT				),
	);
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Microcontroller Output: Send Channel 0 data
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	uController 				#(.mbed_clk_bits(8))		uController_inst(
		.SYS_CLK				( CLK_FAST							),
		.RST					( RST 								), 
		.ON					( ON									),
		.CHANNEL_EMPTY		( CHANNEL0_EMPTY					),
		.CHANNEL_DATA		( CHANNEL0_OUTPUT					),
		.UC_MISO 			( GPIO_1[0] 						),		// MISO = SDO 		= 3
		.UC_MOSI 			( GPIO_1[1] 						),		// MOSI = SDI 		= 4
		.UC_SCK 				( GPIO_1[3]							),		// SCK = SCLK 		= 5
		.UC_CSbar 			( GPIO_1[5] 						),		// CSbar = CSbar 	= 6
		.UC_FIN_EDGE		( UC_FIN_EDGE						)	
	);
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// 7-Seg Displays:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// ADC Data:
	HEX_ENCODER hex3(CHANNEL0_OUTPUT[15:12], 	oHEX3_D);
	HEX_ENCODER hex2(CHANNEL0_OUTPUT[11:8], 	oHEX2_D);
	HEX_ENCODER hex1(CHANNEL0_OUTPUT[7:4], 	oHEX1_D);
	HEX_ENCODER hex0(CHANNEL0_OUTPUT[3:0], 	oHEX0_D);
	
	// ADC #:
	HEX_ENCODER hex6(iSW[17:15], 					oHEX6_D);
	
	// Channel #:
	HEX_ENCODER hex4(iSW[1:0], 					oHEX4_D);
	
	// Turn off unnecessary 7-Seg Displays:
	HEX_ENCODER hex7(5'b11111, 					oHEX7_D);
	HEX_ENCODER hex5(5'b11111, 					oHEX5_D);	
	
endmodule
//=================================================
// END TOPLEVEL MODULE
//=================================================
