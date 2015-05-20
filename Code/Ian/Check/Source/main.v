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
		
	always @(posedge CLK_40)
		rd <= SPI_ON ? 0 : 1;
		
	reg wr, manual_wr;
	always @(posedge CLK_40)
		manual_wr <= ~iKEY[2];
		//wr <= ~iKEY[2];
	
	always @(posedge CLK_40)
		wr <= SPI_ON | manual_wr ? 0 : 1;

	wire [15:0] FIFO_OUT;
	
	wire FIFO_EMPTY, FIFO_FULL;
	assign oLEDR[16] = FIFO_EMPTY;
	assign oLEDR[17] = FIFO_FULL;
	
	FIFO # (.abits (14), .dbits (16)) FIFO_instant(
		.SYS_CLK 	( CLK_40						),
		.reset 		( rst							),
		.wr 			( wr 				),
		.rd 			( rd  				),
		.din			( fin_counter				),		//
		.empty		( FIFO_EMPTY			),
		.full			( FIFO_FULL			),
		.dout			( FIFO_OUT					)
    ); 

	 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg on;
	always @(posedge CLK_40)
		on <= iSW[17];
	
	reg MBED_RDY;
	always @(posedge CLK_40)
		MBED_RDY <= GPIO_1[7] & on;
		
	
	//assign oLEDG[7] = SPI_ON;

	// Monostable multivibrator to detect positive edge:
	reg SPI_ON, temp_mbed_1, temp_mbed_2;
		
	always @(posedge CLK_40) begin
		temp_mbed_1 <= ~rst ? MBED_FIN 		: 0;
		temp_mbed_2 <= ~rst ? temp_mbed_1 	: 0;
	end
	
	// SPI on when MBED is ready or in middle of transmission:
	reg [15:0] fin_counter;
	always @(posedge CLK_40) begin			
		// posedge MBED_FIN = SPI Finished
		case ({temp_mbed_1, temp_mbed_2})
		2'b10:	begin 
			SPI_ON <= 0; 
			fin_counter <= ~rst ? fin_counter + 1 : 0;
		end
		default: begin
			SPI_ON <= MBED_RDY & ~FIFO_EMPTY ? 1 : SPI_ON;
		end
		endcase
	end		
	
	assign oLEDG[8] = MBED_FIN;
	
	// MBED SPI Master Module:
	wire 			MBED_FIN;
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_40						),
		.ENA 			( SPI_ON 			),  	
		.DATA_MOSI 	( FIFO_OUT 				),		//
		.MISO 		( GPIO_1[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 				),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN					)
	); 
	 
	 
	 // ADC data:
	hex_encoder hex3(FIFO_OUT[15:12], 	oHEX3_D);
	hex_encoder hex2(FIFO_OUT[11:8], 	oHEX2_D);
	hex_encoder hex1(FIFO_OUT[7:4], 	oHEX1_D);
	hex_encoder hex0(FIFO_OUT[3:0], 	oHEX0_D);

endmodule

