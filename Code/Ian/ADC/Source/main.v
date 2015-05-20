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
	
//	reg CLK_40;
//	always @(posedge aCLK_40)
//		CLK_40 <= ~iKEY[3];

	// 20MHz Clock:
	reg CLK20;
	always @(posedge CLK_40) begin			
			CLK20 <= ~CLK20;
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
// ADC Modules:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	// Auto-sample at 312.5kHZ:
	parameter BITS = 6;
	parameter TOPBIT = BITS-1;
	reg	[TOPBIT:0]		auto_sample;
	always @(posedge CLK20) begin		
		//auto_sample <= ~rst & on & (counter_burst < 588799) ? auto_sample + 1 : 0;
		auto_sample <= ~rst & on ? auto_sample + 1 : 0;
	end
	
	wire ADC0_en;
	assign ADC0_en = ~&auto_sample[TOPBIT] & ~rst & on; //& ~FIFO_ADC0_FULL; 
	assign oLEDG[8] = ADC0_en;
	
	reg [15:0] sample_count;				//
	always @(posedge ADC0_en) begin			//
		sample_count <= ~rst & on ? sample_count + 1 : 0; //
	end		//
	
	SPI_MASTER_ADC # (.outBits (16)) ADC0_instant(
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


	assign oLEDR[15:0] = sample_count;
	assign oLEDG[7] = on;

	
	 
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
	hex_encoder hex3(ADC0_data[15:12], 	oHEX3_D);
	hex_encoder hex2(ADC0_data[11:8], 	oHEX2_D);
	hex_encoder hex1(ADC0_data[7:4], 	oHEX1_D);
	hex_encoder hex0(ADC0_data[3:0], 	oHEX0_D);
	
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
