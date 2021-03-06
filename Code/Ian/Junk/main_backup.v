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
// Custom Clock:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 					CLK_40;
	CLKPLL	CLKPLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	),
	);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// SPI:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// Auto-sample at 156kHZ:
	reg	[4:0]	auto_sample;
	reg 	[5:0]		enable;
	reg 				sample;
		
	// 20MHz Clock: Separate bit for each ADC Module
	reg counter;
	always @(posedge CLK_40) begin			
			counter <= ~counter;
	end
	
	always @(posedge counter) begin		
		auto_sample <= auto_sample + 1;
	end
	
	always @(posedge counter) begin
		sample <= &auto_sample[4:3];
	end
	
	reg [8:0] counter_mbed;
	always @(posedge CLK_40)
		counter_mbed <= counter_mbed + 1;
	
	reg [9:0] usonic;
	always @(posedge CLK_40)
		usonic <= usonic + 1;
		
	assign GPIO_1[24] = usonic[9];
	
	SPI_MASTER_DEVICE ADC0_instant(
		.SYS_CLK 	( CLK_40						),
		.ENA 			( ~sample					),  	
		.DATA_MOSI 	( ADC0_cmd 					),
		.MISO 		( GPIO_0[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[5] 				),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[0] 				),
		.DATA_MISO 	( ADC0_data 				)
	);
	
	wire 			MBED_FIN;
	wire [15:0] MBED_RESPONSE;
	wire 			MBED_FIN_IN;
	assign MBED_FIN_IN = GPIO_1[7];
	SPI_MASTER_DEVICE mbed_instant(
		.SYS_CLK 	( CLK_40						),
		.ENA 			( on & ~rst & ~ADC_fin[0] & ~MBED_FIN & ~MBED_FIN_IN 	),  	
		.DATA_MOSI 	( ADC_data>>1				),
		.MISO 		( GPIO_1[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 				),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN					),
		.DATA_MISO	( MBED_RESPONSE			)
	);

	assign oLEDR[15:0] = MBED_RESPONSE;
	
	FIFO # (.abits (12), .dbits (16)) FIFO_ADC0(
		.SYS_CLK 	( CLK_40						),
		.reset 		( rst							),
		.wr 			( ADC_fin[0] 				),
		.rd 			( on & ~MBED_FIN & ~MBED_FIN_IN 		),
		.din			( ADC0_data					),
		.empty		( oLEDR[16]					),
		.full			( oLEDR[17]					),
		.dout			( ADC_data					)
    ); 

	// Data output to HEX 3:0 [MSB first]
	wire		[15:0]	ADC_data;
	
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
	hex_encoder(ADC_data[15:12], 	oHEX3_D);
	hex_encoder(ADC_data[11:8], 	oHEX2_D);
	hex_encoder(ADC_data[7:4], 	oHEX1_D);
	hex_encoder(ADC_data[3:0], 	oHEX0_D);
	
	// ADC #:
	hex_encoder(iSW[17:15], 		oHEX6_D);
	
	// Channel #:
	hex_encoder(iSW[1:0], 			oHEX4_D);
	
	// Turn off unnecessary 7-Seg Displays:
	hex_encoder(5'b11111, 			oHEX7_D);
	hex_encoder(5'b11111, 			oHEX5_D);
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// DEBUG:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
//	reg manual_clk;
//	always @(posedge CLK_40)
//		manual_clk <= ~iKEY[0];
//		
//	reg manual_en;
//	always @(posedge counter)
//		manual_en <= ~iKEY[0];
//	
//	reg rd;
//	always @(posedge counter)
//		rd <= ~iKEY[3];
//	
	reg rst;
	always @(posedge CLK_40)
		rst <= ~iKEY[1];

	reg on;
	always @(posedge CLK_40)
		on <= iSW[9];
	
	
	//assign oLEDR[3:0] = i;
	
	assign oLEDG[4:0] = ADC_fin;
//	
//	assign oLEDG[7] = auto_sample[24];
//	assign oLEDG[6] = &auto_sample[24:6];
	
endmodule
//=================================================
// END TOPLEVEL MODULE
//=================================================
