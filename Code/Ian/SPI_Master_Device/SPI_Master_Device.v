//=================================================
// SPI MASTER MODULE
//=================================================
module SPI_MASTER_DEVICE(
	input			SPI_CLK,
	input 		ENA,
	input	[3:0]	MUX_ADDR,
	input 		MISO,
	output reg 	MOSI,
	output reg 	CSbar,
	output  		SCK,
	output reg 	FIN,
	output reg [15:0]	DATA,
	output reg	INVALID
	);	

	reg	[15:0]	data_in 	= 16'b0;
	reg	[15:0]	data_out = 16'b0;
	reg	[1:0]		finished = 2'b00;			// [INPUT OUTPUT]
	reg	[4:0]		icounter = 5'b0;
	reg	[4:0]		ocounter = 5'b0;
	reg	[2:0]		first_start = 3'b011; 	// [RDY ~INPUTinvalid ~OUTPUTinvalid]
	
	assign SCK = SPI_CLK;
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Initial setup:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	always @(posedge SCK) begin
		if (finished[1])
			first_start[1] <= 0;
		else ;
		
		if (finished[0]) 
			first_start[0] <= 0;
		else ;
		
		first_start[2] 	<= (~first_start[1] & ~first_start[0]);
	end
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MISO Component (Master Input/Slave Output):
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	always @(posedge SCK) begin
		case (CSbar)
		1'b1: begin
			icounter 	<= 1'b0;
			finished[1] <= 1'b0;
			
			if (~first_start[2])
				data_in 	<= 16'b0;
		end

		1'b0: begin
			case (finished[1])
			1'b0: begin
				if (~first_start[2])
					data_in 	<= 16'b0;
				else
					data_in 	<= {data_in[14:0], MISO};
				
				icounter 	<= icounter + 1;
				finished[1]	<= icounter[4];
			end
			1'b1: begin
				finished[1] <= 1'b1;
			end
			endcase
		end
		endcase
	end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MOSI Component (Master Output/Slave Input):
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	always @(posedge SCK) begin
		case (CSbar)
		1'b1: begin
			finished[0] 		<= 1'b0; 				
			ocounter				<= 5'b0;
			data_out 			<= {4'b0001, 1'b0, MUX_ADDR, 7'b1000000};	// 0001 0 1001 1000000 = 14C0
			MOSI 					<= 1'bz;
		end
		1'b0: begin
			case (finished[0])
			1'b0: begin
				MOSI 				<= data_out[15];
				data_out 		<= {data_out[14:0], 1'b0};
			
				ocounter 		<= ocounter + 1;
				finished[0] 	<= ocounter[4];
			end
			1'b1:	begin
				MOSI				<= 1'bz;
			end
			endcase
		end
		endcase
	end
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Module I/O:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	always @(posedge SCK) begin
		CSbar 			<= ~ENA;
		FIN 				<= (finished[1] & finished[0]);
		DATA	 			<= data_in;
		INVALID			<= ~first_start[2];
	end
	
endmodule
//=================================================
// END SPI MASTER MODULE
//=================================================




//=================================================
// TOP LEVEL MODULE
//=================================================
module MAIN(
	input 					iCLK_50,
	input 		[17:0] 	iSW,
	input 		[3:0] 	iKEY,
	
	output  		[17:0]	oLEDR,
	output  		[8:0]		oLEDG,
	
	inout			[31:0]	GPIO_0
	);
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// User declarations & instantiations:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	wire CLK_50;
	wire CLK_20;
	wire CLK_10;
	
	CLK_PLL	CLK_PLL_inst (
		.inclk0 ( iCLK_50 ),
		.c0 (	CLK_50 ),
		.c1 ( CLK_20 ),
		.c2 ( CLK_10 )
	);
	
	SPI_MASTER_DEVICE SPI_MASTER_INSTANT(
		.SPI_CLK 	( CLK_20 	),
		.ENA 			( cnt[19]	),
		//.ENA		( ~iKEY[0] 	),
		.MUX_ADDR 	( iSW[3:0] 	),
		.SCK 			( GPIO_0[5] ),
		.MOSI 		( GPIO_0[0] ),
		.MISO 		( GPIO_0[1] ),
		.CSbar 		( GPIO_0[3] ),
		.FIN 			( oLEDG[7] 	),
		.DATA 		( {oLEDG[3:0], oLEDR[11:0]} ),
		//.DATA		( oLEDR[15:0] ),
		.INVALID		( oLEDG[8] )
		);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// User code:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	reg [19:0] cnt;						// 47.68 Hz update
	
	always @(posedge CLK_50) begin
		cnt <= cnt + 1;
	end

endmodule
