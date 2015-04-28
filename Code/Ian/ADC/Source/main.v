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
	
	inout		[31:0]	GPIO_0, GPIO_1,
	
	input					iUART_RTS,
	output				oUART_TXD
	);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Connections from ADC Board:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 		[15:0] 	ADC0_data, ADC1_data, ADC2_data, ADC3_data, ADC4_data;
	wire		[4:0]		ADC_fin;
	wire		[15:0]	ADC0_cmd = {4'b0001, 1'b1, iSW[3:0], 7'b1000000};
	wire		[15:0]	ADC1_cmd = {4'b0001, 1'b1, iSW[3:0], 7'b1000000};
	wire		[15:0]	ADC2_cmd = {4'b0001, 1'b1, iSW[3:0], 7'b1000000};
	wire		[15:0]	ADC3_cmd = {4'b0001, 1'b1, iSW[3:0], 7'b1000000};
	wire		[15:0]	ADC4_cmd = {4'b0001, 1'b1, iSW[3:0], 7'b1000000};
	
	assign GPIO_1[31:26] = 6'bzzzzzz;				// Impedance Matching on Enable/CSbar

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Custom Clock:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 					CLK_50, CLK_40, CLK_25, CLK_20;
	CLK_PLL	CLK_PLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	),
		.c1		( CLK_25		),
		.c2		( CLK_20		)
	);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// SPI:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// Auto-sample at 1MHZ for 1 Channel:
	reg	[5:0]	auto_sample = 6'b0;
	always @(posedge CLK_40) begin		
		auto_sample <= (auto_sample[5]) ? 6'b0: auto_sample + 1;
	end
	
	// 20MHz Clock: Separate bit for each ADC Module
	reg	[4:0]	counter = 5'b0;
	always @(posedge CLK_40) begin			
			counter <= (counter==5'b11111) ? 5'b00000 : 5'b11111;
	end
			
	SPI_MASTER_DEVICE ADC0_instant(
		.SPI_CLK 	( counter[0] 		),
		.ENA 			( ~auto_sample[5]	),  	
		.DATA_MOSI 	( ADC0_cmd 			),
		.MISO 		( GPIO_0[0] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[1] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[3]			),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[5] 		),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[0] 		),
		.DATA_MISO 	( ADC0_data 		)
	);
	
	SPI_MASTER_DEVICE ADC1_instant(
		.SPI_CLK 	( counter[1]		),
		.ENA 			( ~auto_sample[5]	),  	
		.DATA_MOSI 	( ADC1_cmd 			),
		.MISO 		( GPIO_0[9] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[11] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[13]		),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[14] 		),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[1] 		),
		.DATA_MISO 	( ADC1_data 		)
	);
	
	SPI_MASTER_DEVICE ADC2_instant(
		.SPI_CLK 	( counter[2]		),
		.ENA 			( ~auto_sample[5]	),  	
		.DATA_MOSI 	( ADC2_cmd 			),
		.MISO 		( GPIO_0[15] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[17] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[19]		),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[21] 		),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[2]		),
		.DATA_MISO 	( ADC2_data 		)
	);
	
	SPI_MASTER_DEVICE ADC3_instant(
		.SPI_CLK 	( counter[3]		),
		.ENA 			( ~auto_sample[5]	),  	
		.DATA_MOSI 	( ADC3_cmd 			),
		.MISO 		( GPIO_0[25] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[27] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[29]		),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[31] 		),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[3]		),
		.DATA_MISO 	( ADC3_data 		)
	);
	
	SPI_MASTER_DEVICE ADC4_instant(
		.SPI_CLK 	( counter[4]		),
		.ENA 			( ~auto_sample[5]	),  	
		.DATA_MOSI 	( ADC4_cmd 			),
		.MISO 		( GPIO_0[24] 		),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_0[26] 		),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_0[28]		),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_0[30] 		),		// CSbar = CSbar 	= 6
		.FIN 			( ADC_fin[4]		),
		.DATA_MISO 	( ADC4_data 		)
	);
	
	TENBASET_TxD ethernet_instant(
		.clk20 		( CLK_20				),
		.clkan		( CLK_20				),
		.Ethernet_TDp	( GPIO_1[0]		), 
		.Ethernet_TDm	( GPIO_1[1]		),
		.data0			( ADC0_data 	),
		.data1			( ADC1_data		),
		.data2			( ADC2_data		),
		.data3			( ADC3_data		),
		.data4			( ADC4_data		)
	);
	
	
	// Data output to HEX 3:0 [MSB first]
	reg		[15:0]	ADC_data = 16'b0;
	
	always @(posedge CLK_20) begin
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
	hex_encoder(5'b11111, 				oHEX7_D);
	hex_encoder(5'b11111, 				oHEX5_D);
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// DEBUG:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
//	reg manual_clk;
//	always @(posedge CLK_10)
//		manual_clk <= ~iKEY[0];
	
	
endmodule
//=================================================
// END TOPLEVEL MODULE
//=================================================
