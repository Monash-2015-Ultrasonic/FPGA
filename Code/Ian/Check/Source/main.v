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
// Custom/System clock:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	wire 				CLK_40;
	CLKPLL			CLKPLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_40 	)
	);
	
	
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Interactive connections:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg rst;
	always @(posedge CLK_40)
		rst <= ~iKEY[0];

		

		
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Counter:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	// Counter speed = 625kHz:
	parameter bits = 6;
	reg [bits-1:0] CLK_SLOW;
	always @(posedge CLK_40)
		CLK_SLOW <= CLK_SLOW + 1;
	
	reg [15:0] sample_counter;
	always @(posedge CLK_SLOW[bits-1])
		sample_counter <= ~rst & ~ADC_OFF ? sample_counter + 1 : 0;

	// Edge detector for Slow Clock:
	reg clk_prev;
	always @(posedge CLK_40)
		clk_prev <= CLK_SLOW[bits-1];
	
	// Edge detector for Write to FIFO:
	reg wr;
	always @(posedge CLK_40) 
		wr <= CLK_SLOW[bits-1] & ~clk_prev & ~ADC_OFF ? 1 : 0 ;	
	
	// Turn off counter when FIFO overflows:
	reg FIFO_FULL_PREV, ADC_OFF;
	always @(posedge CLK_40) begin
		FIFO_FULL_PREV <= FIFO_FULL; 
		
		if (rst)
			ADC_OFF <= 0;
		else 
			ADC_OFF <= FIFO_FULL & ~FIFO_FULL_PREV ? 1 : ADC_OFF;
	end	
		
		
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// FIFO:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg manual_rd, manual_rd_prev, manual_rd_edge;
	always @(posedge CLK_40) begin
		manual_rd = ~iKEY[3];
		manual_rd_prev <= manual_rd;
		manual_rd_edge <= ~manual_rd_prev & manual_rd ? 1 : 0;
	end
		
	reg manual_wr, manual_wr_prev, manual_wr_edge;
	always @(posedge CLK_40) begin
		manual_wr <= ~iKEY[2];	
		manual_wr_prev <= manual_wr;
		manual_wr_edge <= ~manual_wr_prev & manual_wr ? 1 : 0;
	end
	
	wire [15:0] FIFO_OUT;
	wire FIFO_EMPTY, FIFO_FULL;
	assign oLEDR[16] = FIFO_EMPTY;
	assign oLEDR[17] = FIFO_FULL;
	
	FIFO_IP	FIFO_IP_inst (
		.clock 	( CLK_40 							),
		.sclr 	( rst 								),
		.rdreq 	( MBED_FIN_EDGE | manual_rd_edge ),
		.wrreq 	( wr 	| manual_wr_edge			),
		.data 	( sample_counter 					),
		.empty 	( FIFO_EMPTY 						),
		.full 	( FIFO_FULL 						),
		.q 		( FIFO_OUT 							)
	);

	
 
	 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
	reg manual_wr_mbed, manual_wr_mbed_edge, manual_wr_mbed_prev;
	always @(posedge CLK_40) begin
		manual_wr_mbed <= ~iKEY[1];
		manual_wr_mbed_prev <= manual_wr_mbed;
		manual_wr_mbed_edge <= ~manual_wr_mbed_prev & manual_wr_mbed ? 1 : 0;
	end
	
	// Periodically write to MBED @ 2kHz:
	parameter out_clk_bits = 14;
	reg [out_clk_bits-1:0] out_clk;
	always @(posedge CLK_40)
		out_clk <= ~rst ? out_clk + 1 : 0;
		
	reg out_clk_prev, out_clk_edge;
	always @(posedge CLK_40) begin
		out_clk_prev <= out_clk[out_clk_bits-1];
		out_clk_edge <= ~out_clk_prev & out_clk[out_clk_bits-1] ? 1 : 0;
	end
	
	reg MBED_FIN_PREV, MBED_FIN_EDGE;
	always @(posedge CLK_40) begin
		MBED_FIN_PREV <= MBED_FIN;
		MBED_FIN_EDGE <= ~MBED_FIN_PREV & MBED_FIN ? 1 : 0;
	end
		
	reg SPI_ON;
	always @(posedge CLK_40) begin
		//if (manual_wr_mbed_edge)
		//if (MBED_RDY_EDGE | manual_wr_mbed_edge)
		if (out_clk_edge | manual_wr_mbed_edge)
			SPI_ON <= ~FIFO_EMPTY ? 1 : 0;
		else 
			SPI_ON <= ~MBED_FIN ? SPI_ON : 0;	
	end
	
	// MBED SPI Master Module:
	wire 			MBED_FIN;
	SPI_MASTER_UC # (.outBits (16)) mbed_instant(
		.SYS_CLK 	( CLK_40						),
		.RST			( 								),
		.ENA 			( SPI_ON & ~FIFO_EMPTY ),  	
		.DATA_MOSI 	( FIFO_OUT 					),		
		.MISO 		( GPIO_1[0] 				),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 				),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]					),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 				),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN					)
	); 
	 
	assign oLEDG[8] = MBED_FIN;
	 
	 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// 7-Seg Outputs:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	hex_encoder hex3(sample_counter[15:12], 	oHEX3_D);
	hex_encoder hex2(sample_counter[11:8], 	oHEX2_D);
	hex_encoder hex1(sample_counter[7:4], 		oHEX1_D);
	hex_encoder hex0(sample_counter[3:0], 		oHEX0_D);
	
	hex_encoder hex7(FIFO_OUT[15:12], 			oHEX7_D);
	hex_encoder hex6(FIFO_OUT[11:8], 			oHEX6_D);
	hex_encoder hex5(FIFO_OUT[7:4], 				oHEX5_D);
	hex_encoder hex4(FIFO_OUT[3:0], 				oHEX4_D);

endmodule
