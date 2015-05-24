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
// Custom/System Clock:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 					CLK_40;
	CLKPLL				CLKPLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	),
	);
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Connections from GPIO:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg rst;
	always @(posedge CLK_40)
		rst <= ~iKEY[0];

	reg on;
	always @(posedge CLK_40)
		on <= iSW[9];
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Transmitter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Generate 39.0625kHz pulse for the Ultrasonic Transmitter:
	reg [9:0] usonic;
	always @(posedge CLK_40)
		usonic <= usonic + 1;
	
	reg [9:0] counter_burst;
	always @(posedge usonic[9])
		counter_burst <= ~rst & on & (counter_burst < 574) ? counter_burst + 1 : 0;
	
	reg usonicpulse;
	always @(posedge CLK_40)
		usonicpulse <= usonic[9] & (counter_burst < 32);

	assign GPIO_1[24] = usonicpulse & ~rst & on;	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Connections from ADC Board:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 		[15:0] 	ADC0_data, ADC1_data, ADC2_data, ADC3_data, ADC4_data;
	wire		[4:0]		ADC_fin;
	wire		[15:0]	ADC0_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC1_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC2_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC3_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC4_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	
	assign 				GPIO_1[31:26] = 6'bzzzzzz;				// Impedance Matching on Enable/CSbar
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// ADC Modules:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	// Auto-sample at 625kHz: //312.5kHZ:
	parameter BITS = 6;
	parameter TOPBIT = BITS-1;
	
	reg [TOPBIT:0] CLK_SAMPLE;
	always @(posedge CLK_40)
		CLK_SAMPLE <= ~rst & on? CLK_SAMPLE + 1 : 0;
		
	//wire ADC0_en = ~&CLK_SAMPLE[TOPBIT] & ~rst & on;
	wire ADC0_en = ~&CLK_SAMPLE[TOPBIT:TOPBIT-1] & ~rst & on & ~ADC_OFF;
	
	assign oLEDG[7] = ADC0_en;
	
	SPI_MASTER_ADC # (.outBits (16)) ADC0_instant(
		.SYS_CLK 	( CLK_40						),
		.ENA 			( ADC0_en 					),  	
		.DATA_MOSI 	( ADC0_cmd 					),
		.MISO 		( GPIO_0[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[5] 				),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[0] 				),
		.DATA_MISO 	( ADC0_data 				)
	);

	//wire wr = ADC_fin[0] & ~ADC_OFF;
	//wire wr = ADC_fin[0];
	
	reg wr, wr_prev, wr_edge;
	always @(posedge CLK_40)
		wr_prev <= ADC_fin[0];
		
	always @(posedge CLK_40)
		wr_edge <= ~wr_prev & ADC_fin[0] & ~ADC_OFF & ~rst & on ? 1 : 0;
	
	
	reg FIFO_FULL_prev;
	always @(posedge CLK_40)
		FIFO_FULL_prev <= FIFO_ADC0_FULL;
	
	reg ADC_OFF = 0;
	always @(posedge CLK_40) begin
		if (rst | ~on)
			ADC_OFF <= 0;
		else 
			ADC_OFF <= FIFO_ADC0_FULL & ~FIFO_FULL_prev ? 1 : ADC_OFF;
	end
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIFO: 16bits width, 16384 Words depth
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	wire		[15:0]	FIFO_OUT;	
	
	wire 					FIFO_ADC0_EMPTY;
	assign				oLEDR[16] = FIFO_ADC0_EMPTY;
	
	wire 					FIFO_ADC0_FULL;
	assign				oLEDR[17] = FIFO_ADC0_FULL;

	FIFO_IP	FIFO_IP_inst (
		.clock 	( CLK_40 							),
		.sclr 	( rst 								),
		.rdreq 	( MBED_FIN_EDGE ),
		.wrreq 	( wr_edge 			),
		.data 	( ADC0_data>>1 					),
		.empty 	( FIFO_ADC0_EMPTY 						),
		.full 	( FIFO_ADC0_FULL 						),
		.q 		( FIFO_OUT 							)
	);
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	//reg MBED_RDY;
	//always @(posedge CLK_40)
	//	MBED_RDY <= GPIO_1[7] & ~FIFO_ADC0_EMPTY;		
			
	//reg MBED_RDY_PREV, MBED_RDY_EDGE;
	//always @(posedge CLK_40)
	//	MBED_RDY_PREV <= MBED_RDY;
		
	//always @(posedge CLK_40)
	//	MBED_RDY_EDGE <= MBED_RDY & ~MBED_RDY_PREV ? 1 : 0;
		
	parameter out_clk_bits = 14;
	reg [out_clk_bits-1:0] out_clk;
	always @(posedge CLK_40)
		out_clk <= ~rst ? out_clk + 1 : 0;
		
	reg out_clk_prev, out_clk_edge;
	always @(posedge CLK_40)
		out_clk_prev <= out_clk[out_clk_bits-1];
		
	always @(posedge CLK_40)
		out_clk_edge <= ~out_clk_prev & out_clk[out_clk_bits-1] ? 1 : 0;
	
	reg SPI_ON;
	always @(posedge CLK_40) begin
		//if (manual_wr_mbed_edge)
		//if (MBED_RDY_EDGE | manual_wr_mbed_edge)
		if (out_clk_edge)
			SPI_ON <= ~FIFO_ADC0_EMPTY ? 1 : 0;
		else 
			SPI_ON <= ~MBED_FIN ? SPI_ON : 0;	
	end
	
	assign oLEDG[8] = MBED_FIN;
	
	// MBED SPI Master Module:
	wire 			MBED_FIN;
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_40						),
		.RST			( 								),
		.ENA 			( SPI_ON & ~FIFO_ADC0_EMPTY  ),  	
		.DATA_MOSI 	( FIFO_OUT 					),		//
		.MISO 		( GPIO_1[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 				),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN					)
	); 

	reg MBED_FIN_PREV, MBED_FIN_EDGE;
	 always @(posedge CLK_40)
		MBED_FIN_PREV <= MBED_FIN;
		
	always @(posedge CLK_40)
		MBED_FIN_EDGE <= ~MBED_FIN_PREV & MBED_FIN ? 1 : 0;

	
	 
//	always @(posedge CLK_20) begin
//		case (iSW[17:15])
//		4'b0000: begin
//			ADC_data <= ADC0_data;
//		end
//		
////		4'b0001: begin
////			ADC_data <= ADC1_data;
////		end
////		
////		4'b0010: begin
////			ADC_data <= ADC2_data;
////		end
////		
////		4'b0011: begin
////			ADC_data <= ADC3_data;
////		end
////		
////		4'b0100: begin
////			ADC_data <= ADC4_data;
////		end
//		
//		default: 
//			ADC_data <= 16'hFFFF;
//		endcase
//	end
	
	// ADC data:

	hex_encoder hex3(FIFO_OUT[15:12], 	oHEX3_D);
	hex_encoder hex2(FIFO_OUT[11:8], 	oHEX2_D);
	hex_encoder hex1(FIFO_OUT[7:4], 		oHEX1_D);
	hex_encoder hex0(FIFO_OUT[3:0], 		oHEX0_D);
	
	/*
	hex_encoder hex3(ADC0_data[15:12], 	oHEX3_D);
	hex_encoder hex2(ADC0_data[11:8], 	oHEX2_D);
	hex_encoder hex1(ADC0_data[7:4], 	oHEX1_D);
	hex_encoder hex0(ADC0_data[3:0], 	oHEX0_D);
*/
	
	// ADC #:
	hex_encoder hex6(iSW[17:15], 			oHEX6_D);
	
	// Channel #:
	hex_encoder hex4(iSW[1:0], 			oHEX4_D);
	
	// Turn off unnecessary 7-Seg Displays:
	hex_encoder hex7(5'b11111, 			oHEX7_D);
	hex_encoder hex5(5'b11111, 			oHEX5_D);
	
	assign oLEDG[4:0] = ADC_fin;	
	
endmodule
//=================================================
// END TOPLEVEL MODULE
//=================================================
