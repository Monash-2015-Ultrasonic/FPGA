module main(
	input 				iCLK_50,
	
	input		[17:0]	iSW,
	input 	[3:0]		iKEY,
	
	output	[17:0]	oLEDR,
	output	[8:0]		oLEDG,
	
	output	[6:0]		oHEX0_D, oHEX1_D, oHEX2_D, oHEX3_D, oHEX4_D, oHEX5_D, oHEX6_D, oHEX7_D,
	
	inout		[31:0]	GPIO_0, GPIO_1
);

	wire 					CLK_40;
	CLKPLL	CLKPLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	),
	);
	
	reg clk20;
	always @(posedge CLK_40)
		clk20 <= ~clk20;
	
	reg rst;
	always @(posedge CLK_40)
		rst <= ~iKEY[0];
		
	reg rd;
	//always @(posedge CLK_40)
		//rd <= ~iKEY[3];
	
	reg manual_rd;
	always @(posedge CLK_40)
		manual_rd = ~iKEY[3] & ~FIFO_EMPTY;
		
	reg wr, manual_wr;
	always @(posedge CLK_40)
		manual_wr <= ~iKEY[2];
	
	//always @(posedge CLK_40)
		//wr <= SPI_ON | manual_wr ? 0 : 1;
		
	reg [6:0] CLK_312k5HZ;
	always @(posedge CLK_40)
		CLK_312k5HZ <= CLK_312k5HZ + 1;
		
	reg [15:0] sample_counter;
	always @(posedge CLK_312k5HZ[6])
		sample_counter <= ~rst? sample_counter + 1 : 0;
	
	// Edge detector:
	reg ff_1;
	always @(posedge CLK_40)
		ff_1 <= CLK_312k5HZ[6];
		
	always @(posedge CLK_40)
		wr <= CLK_312k5HZ[6] & ~ff_1 ? 1:0 ;
			
		
	wire [15:0] FIFO_OUT;
	
	wire FIFO_EMPTY, FIFO_FULL;
	assign oLEDR[16] = FIFO_EMPTY;
	assign oLEDR[17] = FIFO_FULL;
	
	FIFO # (.abits (14), .dbits (16)) FIFO_instant(
		.SYS_CLK 	( CLK_40						),
		.reset 		( rst							),
		.wr 			( wr | manual_wr 				),
		.rd 			( MBED_FIN | manual_rd				),
		.din			( sample_counter				),		//fin_counter
		.empty		( FIFO_EMPTY			),
		.full			( FIFO_FULL			),
		.dout			( FIFO_OUT					)
    ); 

	 //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	
	reg MBED_RDY;
	always @(posedge CLK_40)
		MBED_RDY <= GPIO_1[7] & ~FIFO_EMPTY;// manual_rd;
	
	//wire MBED_RDY = manual_rd;
		
	reg MBED_RDY_PREV, MBED_RDY_EDGE;
	always @(posedge CLK_40)
		MBED_RDY_PREV <= MBED_RDY;
		
	always @(posedge CLK_40)
		MBED_RDY_EDGE <= MBED_RDY & ~MBED_RDY_PREV ? 1 : 0;
		
	reg SPI_ON;
	reg SPI_RST;
	always @(posedge CLK_40) begin
		if (MBED_RDY_EDGE) begin
			SPI_ON <= 1;
			SPI_RST <= 1;
		end
		else if (SPI_ON) begin
			SPI_ON <= ~MBED_FIN ? 1 : 0;
			SPI_RST <= 0;
		end
		else ;
	end
	
	assign oLEDG[8] = MBED_FIN;
	
	// MBED SPI Master Module:
	wire 			MBED_FIN;
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_40						),
		.RST			( ),
		.ENA 			( SPI_ON & ~FIFO_EMPTY  ),  	
		.DATA_MOSI 	( FIFO_OUT 					),		//
		.MISO 		( GPIO_1[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 				),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN					)
	); 

	 
	 
	 // ADC data:
	hex_encoder hex3(sample_counter[15:12], 	oHEX3_D);
	hex_encoder hex2(sample_counter[11:8], 	oHEX2_D);
	hex_encoder hex1(sample_counter[7:4], 	oHEX1_D);
	hex_encoder hex0(sample_counter[3:0], 	oHEX0_D);
	
	hex_encoder hex7(FIFO_OUT[15:12], 	oHEX7_D);
	hex_encoder hex6(FIFO_OUT[11:8], 	oHEX6_D);
	hex_encoder hex5(FIFO_OUT[7:4], 	oHEX5_D);
	hex_encoder hex4(FIFO_OUT[3:0], 	oHEX4_D);

endmodule

