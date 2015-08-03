module main(
	input iCLK_50,
	
	input [3:0] iKEY,
	input [17:0] iSW,
	
	inout [31:0] GPIO_0, GPIO_1,
	
	output [17:0] oLEDR,
	output [8:0] oLEDG
);

wire CLK_40;
CLKPLL	CLKPLL_inst (
	.inclk0 ( iCLK_50 ),
	.c0 ( CLK_40 )
	);
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MBED Microcontroller:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	reg MBED_RDY;
	always @(posedge CLK_40)
		MBED_RDY <= GPIO_1[7];
	
	// Monostable multivibrator to detect positive edge:
	reg SPI_ON, temp_mbed_1, temp_mbed_2;
		
	always @(posedge CLK_40) begin
		temp_mbed_1 <= MBED_FIN;
		temp_mbed_2 <= temp_mbed_1;
	end
	
	// SPI on when MBED is ready or in middle of transmission:
	always @(posedge CLK_40) begin		
		SPI_ON <= MBED_RDY ? 1 : SPI_ON;
		
		case ({temp_mbed_1, temp_mbed_2})
		2'b10:	begin SPI_ON <= 0; end
		default: ;
		endcase
	end	
	
	// MBED SPI Master Module:
	wire 			MBED_FIN;
	SPI_MASTER_DEVICE # (.outBits (32)) mbed_instant(
		.SYS_CLK 	( manual_clk									),
		.ENA 			( manual_en				),  	
		.DATA_MOSI 	( {counter, data}	),
		.MISO 		( GPIO_1[0] 							),		// MISO = SDO 		= 3
		.MOSI 		( GPIO_1[1] 							),		// MOSI = SDI 		= 4
		.SCK 			( GPIO_1[3]								),		// SCK = SCLK 		= 5
		.CSbar 		( GPIO_1[5] 							),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN								),
		.dbg			( oLEDR[0]),
		.dbg2			( manual_fin)
	);
	
	assign oLEDG[0] = MBED_FIN;
	//assign oLEDR[15:0] = dataOUT;
	
	reg [15:0] counter = 16'hFAAF;
	reg [15:0] data 	 = 16'hEBBE;
	
	reg manual_clk;
	always @(posedge CLK_40)
		manual_clk <= ~iKEY[0];
		
	reg manual_en;
	always @(posedge CLK_40)
		manual_en <= iSW[9];
		
	reg [15:0] dataOUT;
	always @(posedge manual_clk)
		dataOUT <= iSW[0] ? data : counter;
		
	assign oLEDG[7] = manual_en;
	assign oLEDG[6] = manual_clk;
	
	reg manual_fin;
	always @(posedge CLK_40)
		manual_fin <= iSW[0];
	
endmodule

