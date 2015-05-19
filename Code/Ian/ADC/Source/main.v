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
// Custom Clock:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 					CLK_40;
	CLKPLL	CLKPLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	),
	);

	// 20MHz Clock:
	reg counter;
	always @(posedge CLK_40) begin			
			counter <= ~counter;
	end
	
	
	
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
// Connections from ADC Board:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 		[15:0] 	ADC0_data, ADC1_data, ADC2_data, ADC3_data, ADC4_data;
	wire		[4:0]		ADC_fin;
	wire		[15:0]	ADC0_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC1_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC2_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC3_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	wire		[15:0]	ADC4_cmd = {4'b0001, 1'b1, 2'b0, iSW[1:0], 7'b1000000};
	
	assign GPIO_1[31:26] = 6'bzzzzzz;				// Impedance Matching on Enable/CSbar

	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Ultrasonic Transmitter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Generate 39.0625kHz pulse for the Ultrasonic Transmitter:
	reg [9:0] usonic;
	always @(posedge CLK_40)
		usonic <= usonic + 1;

	reg [19:0] counter_burst;	
	always @(posedge CLK_40) begin
		//counter_burst <= (counter_burst < 588799) & ~rst & on ? counter_burst + 1 : 0;
		if (rst)
			counter_burst <= 0;
		else
			counter_burst <= (counter_burst < 588799) & on ? counter_burst + 1 : counter_burst;
	end
	
	assign GPIO_1[24] = usonic[9] & ~rst & on;// & (counter_burst < 32);
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// ADC Modules:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	// Auto-sample at 312.5kHZ:
	parameter BITS = 6;
	parameter TOPBIT = BITS-1;
	reg	[TOPBIT:0]		auto_sample;
	always @(posedge counter) begin		
		//auto_sample <= ~rst & on & (counter_burst < 588799) ? auto_sample + 1 : 0;
		auto_sample <= ~rst & on ? auto_sample + 1 : 0;
	end
	
	wire ADC0_en;
	assign ADC0_en = ~&auto_sample[TOPBIT] & ~FIFO_ADC0_FULL & ~rst & on;
	assign oLEDG[8] = ADC0_en;
	
	SPI_MASTER_DEVICE # (.outBits (16)) ADC0_instant(
		.SYS_CLK 	( CLK_40						),
		.ENA 			( ADC0_en					),  	
		.DATA_MOSI 	( ADC0_cmd 					),
		.MISO 		( GPIO_0[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[5] 				),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[0] 				),
		.DATA_MISO 	( ADC0_data 				)
	);

	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIFO: 16bits width, 16384 Words depth
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	// Data output to HEX 3:0 [MSB first]
	wire		[15:0]	ADC_data;	
	
	wire 					FIFO_ADC0_EMPTY;
	assign				oLEDR[16] = FIFO_ADC0_EMPTY;
	
	wire 					FIFO_ADC0_FULL;
	assign				oLEDR[17] = FIFO_ADC0_FULL;
	
	FIFO # (.abits (14), .dbits (16)) FIFO_ADC0_instant(
		.SYS_CLK 	( CLK_40						),
		.reset 		( rst							),
		.wr 			( ADC_fin[0] 				),
		.rd 			( MBED_RDY  				),
		.din			( ADC0_data					),
		.empty		( FIFO_ADC0_EMPTY			),
		.full			( FIFO_ADC0_FULL			),
		.dout			( ADC_data					)
    ); 
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg MBED_RDY;
	always @(posedge CLK_40)
		MBED_RDY <= GPIO_1[7];
		
	//assign oLEDG[7] = SPI_ON;

	// Monostable multivibrator to detect positive edge:
	reg SPI_ON, temp_mbed_1, temp_mbed_2;
		
	always @(posedge CLK_40) begin
		temp_mbed_1 <= ~rst ? MBED_FIN 		: 0;
		temp_mbed_2 <= ~rst ? temp_mbed_1 	: 0;
	end
	
	// SPI on when MBED is ready or in middle of transmission:
	always @(posedge CLK_40) begin		
		SPI_ON <= MBED_RDY &~FIFO_ADC0_EMPTY ? 1 : SPI_ON;
		
		// posedge MBED_FIN = SPI Finished
		case ({temp_mbed_1, temp_mbed_2})
		2'b10:	begin SPI_ON <= 0; end
		default: ;
		endcase
	end	
	
	// MBED SPI Master Module:
	wire 			MBED_FIN;
	SPI_MASTER_DEVICE # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_40						),
		.ENA 			( SPI_ON  & ~rst 	),  	
		.DATA_MOSI 	( ADC_data >> 1			),
		.MISO 		( GPIO_1[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 				),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN					)
	);


	
	 
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
	hex_encoder hex3(ADC_data[15:12], 	oHEX3_D);
	hex_encoder hex2(ADC_data[11:8], 	oHEX2_D);
	hex_encoder hex1(ADC_data[7:4], 	oHEX1_D);
	hex_encoder hex0(ADC_data[3:0], 	oHEX0_D);
	
	// ADC #:
	hex_encoder hex6(iSW[17:15], 		oHEX6_D);
	
	// Channel #:
	hex_encoder hex4(iSW[1:0], 			oHEX4_D);
	
	// Turn off unnecessary 7-Seg Displays:
	hex_encoder hex7(5'b11111, 			oHEX7_D);
	hex_encoder hex5(5'b11111, 			oHEX5_D);
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// DEBUG:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
//	reg manual_clk;
//	always @(posedge CLK_40)
//		manual_clk <= ~iKEY[0];

//	reg manual_en;
//	always @(posedge counter)
//		manual_en <= ~iKEY[0];
//
	assign oLEDG[4:0] = ADC_fin;	
	
endmodule
//=================================================
// END TOPLEVEL MODULE
//=================================================
