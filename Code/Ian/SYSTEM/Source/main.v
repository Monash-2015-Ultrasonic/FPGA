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
	wire burstSent;
	ultrasonicTransmitter 	#(.initial_delay(0)) 		usonicTX_inst(
		.SYS_CLK			( CLK_FAST							),
		.CLK_40 			( CLK_40 							),
		.RST				( RST 								), 
		.ON				( ON									),
		.burstStart		( burstSent							),
		.pulseOutput	( GPIO_1[25:24]  					)
	);
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Receiver Channel 0:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	wire [9:0]		CHANNEL0_OUTPUT;
	ultrasonicReceiver 		#(.sampler_bits(8)) 		usonicRX_ch0_inst(
		.SYS_CLK				( CLK_FAST						),
		.RST					( RST								), 
		.ON					( ON								),
		.ADC_MISO			( GPIO_0[0]						), // MISO = SDO 		= 3
		.ADC_MOSI			( GPIO_0[1]						),	// MOSI = SDI 		= 4
		.ADC_SCK				( GPIO_0[3]						), // SCK = SCLK 		= 5
		.ADC_CSbar			( GPIO_0[5]						), // CSbar = CSbar 	= 6
		.ADC_channel_sel	( iSW[1:0]						),
		.burstSent			( burstSent						),			
		.ARRIVAL_TIME		( CHANNEL0_OUTPUT				)
	);	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// 7-Seg Displays:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// ADC Data:
	//HEX_ENCODER hex3(CHANNEL0_OUTPUT[15:12], 	oHEX3_D);
	HEX_ENCODER hex3(5'b11111, 					oHEX3_D);
	HEX_ENCODER hex2(CHANNEL0_OUTPUT[9:8], 	oHEX2_D);
	HEX_ENCODER hex1(CHANNEL0_OUTPUT[7:4], 	oHEX1_D);
	HEX_ENCODER hex0(CHANNEL0_OUTPUT[3:0], 	oHEX0_D);
	
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


/*
// JUNKYARD
	
	
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
	
	
	*/
