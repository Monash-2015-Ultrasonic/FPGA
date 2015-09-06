//=================================================
// MICROCONTROLLER MODULE
//=================================================
module uController # (parameter mbed_clk_bits = 8) (
	input 			SYS_CLK,
	input 			RST, ON,
	
	input 			CHANNEL_EMPTY,
	input [15:0]	CHANNEL_DATA,
	
	input 			UC_MISO,
	output  			UC_MOSI,
	output  			UC_CSbar,
	output 			UC_SCK,
	
	output reg 		UC_FIN_EDGE
);

	// Data rate output limiter:
	reg [1:0] counter_report;
	reg [16:0] counter_wait;
	reg MBED_ALLOWED = 0;
	always @(posedge SYS_CLK) begin
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
			counter_report <= UC_FIN_EDGE ? counter_report + 1 : counter_report;
			MBED_ALLOWED <= 1;
		end 
		endcase
	end 
	
	// Generate clock to output data to MBED periodically: same rate as sampler
	reg [mbed_clk_bits-1:0] MBED_CLK;
	always @(posedge SYS_CLK)
		MBED_CLK 		<= ~RST & ON ? MBED_CLK + 1 : 0;
	
	// Edge Detector for MBED periodic data output clock:
	reg MBED_CLK_PREV, MBED_CLK_EDGE;
	always @(posedge SYS_CLK) begin
		MBED_CLK_PREV 	<= MBED_CLK[mbed_clk_bits-1];
		MBED_CLK_EDGE 	<= ~MBED_CLK_PREV & MBED_CLK[mbed_clk_bits-1] ? 1 : 0;
	end
	
	// Edge Detector for when single write to MBED finishes:
	wire MBED_FIN;
	reg MBED_FIN_PREV;
	always @(posedge SYS_CLK) begin
		MBED_FIN_PREV <= MBED_FIN;
		UC_FIN_EDGE <= ~MBED_FIN_PREV & MBED_FIN ? 1 : 0;
	end
	
	// Control logic to enable SPI to MBED:
	reg MBED_ON;
	always @(posedge SYS_CLK) begin
		//if (MBED_CLK_EDGE | manual_wr_mbed_edge)
		if (MBED_CLK_EDGE)
			MBED_ON 		<= ~CHANNEL_EMPTY & MBED_ALLOWED ? 1 : 0;
		else 
			MBED_ON 		<= ~MBED_FIN ? MBED_ON : 0;	
	end
	
	// MBED SPI Master Module:
	SPI_MASTER_UC # (.outBits (16)) mbed_SPI_instant(
		.SYS_CLK 	( SYS_CLK			),
		.RST			( 						),
		.ENA 			( MBED_ON   		),  	
		.DATA_MOSI 	( CHANNEL_DATA		),		
		.MISO 	( UC_MISO 			),		// MISO = SDO 		= 3
		.MOSI 	( UC_MOSI 			),		// MOSI = SDI 		= 4
		.SCK 		( UC_SCK				),		// SCK = SCLK 		= 5
		.CSbar 	( UC_CSbar 			),		// CSbar = CSbar 	= 6
		.FIN			( MBED_FIN			)
	); 

	// Connect signals to Green LEDs:
	//assign oLEDG[8] 	= MBED_FIN;
	
endmodule
