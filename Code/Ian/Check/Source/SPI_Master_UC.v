//=================================================
// SPI MASTER MODULE - MICROCONTROLLER
//=================================================
module SPI_MASTER_UC # (parameter outBits = 16)(
	input					SYS_CLK,
	input					RST,
	input 				ENA,
	input		[15:0]	DATA_MOSI,
	input 				MISO,
	output  reg			MOSI,
	output  reg			CSbar,
	output 				SCK,
	output  reg			FIN,
	output  	[15:0]	DATA_MISO
	);	

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Initial setup:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg	[(outBits-1):0]	data_in 				= 0;			// Temp storage for MISO data
	reg	[(outBits-1):0]	data_in_final 		= 0;			// Storage (HOLD) for MISO data 
	reg	[(outBits-1):0]	data_out 			= 0;			// Temp storage for MOSI data
	reg	[5 			:0]	icounter 			= 0;						// counter for MISO data
	reg	[5 			:0]	ocounter 			= 0;						// counter for MOSI data
	
	//reg					SPI_CLK;
	//always @(posedge SYS_CLK)
		//SPI_CLK <= ~SPI_CLK;
	
	reg [2:0] 		SPI_CLK_5;
	always @(posedge SYS_CLK)
		SPI_CLK_5 <= ~RST ? SPI_CLK_5 + 1 : 0;
	
	wire SPI_CLK = SPI_CLK_5[2];
	
	assign SCK 				= SPI_CLK;
	
	assign DATA_MISO 		= data_in_final<<1;
	
	always @(posedge SPI_CLK)
		CSbar					<= ~ENA;
	
	always @(posedge SPI_CLK)
		FIN 					<= (ocounter > (outBits-1)) & (icounter > (outBits-1));
	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MISO Component (Master Input/Slave Output):
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	always @(posedge SPI_CLK) begin
		case (CSbar)
		1'b1: begin
			icounter 	<= 0;
			data_in		<= 0;
		end

		1'b0: begin			
			case (icounter > (outBits-1))
			1'b0: begin
				data_in 		<= {data_in[(outBits-2):0], MISO};
				
				icounter 	<= icounter + 1;
			end
			default: 
				data_in_final <= data_in;
			endcase
		end
		endcase
	end
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MOSI Component (Master Output/Slave Input):
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	always @(posedge SPI_CLK) begin
		case (CSbar)
		1'b1: begin				
			ocounter				<= 0;
			data_out 			<= DATA_MOSI;	
			MOSI <= 0;
		end
		1'b0: begin
			MOSI <= data_out[(outBits-1)];
			
			case (ocounter > (outBits-1))
			1'b0: begin
				data_out 		<= {data_out[(outBits-2):0], 1'b0};
				
				ocounter 		<= ocounter + 1;
			end
			1'b1:	begin
				;
			end
			endcase
		end
		endcase
	end

endmodule
//=================================================
// END SPI MASTER MODULE
//=================================================
