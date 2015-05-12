//=================================================
// SPI MASTER MODULE
//=================================================
module SPI_MASTER_DEVICE(
	input					SYS_CLK,
	input 				ENA,
	input		[15:0]	DATA_MOSI,
	input 				MISO,
	output  				MOSI,
	output  				CSbar,
	output 				SCK,
	output  				FIN,
	output  	[15:0]	DATA_MISO
	);	

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// Initial setup:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg	[15:0]	data_in 			= 16'b0;			// Temp storage for MISO data
	reg	[15:0]	data_in_final 	= 16'b0;			// Storage (HOLD) for MISO data 
	reg	[15:0]	data_out 		= 16'b0;			// Temp storage for MOSI data
	reg	[4:0]		icounter 		= 5'b0;			// counter for MISO data
	reg	[4:0]		ocounter 		= 5'b0;			// counter for MOSI data
	
	reg					SPI_CLK;
	always @(posedge SYS_CLK)
		SPI_CLK <= ~SPI_CLK;
	
	assign SCK 				= SPI_CLK;
	assign CSbar 			= ~ENA;
	assign DATA_MISO 		= data_in_final<<1;
	assign FIN 				= (ocounter>15) & (icounter>15);
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// MISO Component (Master Input/Slave Output):
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	always @(posedge SPI_CLK) begin
		case (CSbar)
		1'b1: begin
			icounter 	<= 5'b0;
			data_in		<= 16'b0;
		end

		1'b0: begin			
			case (icounter>15)
			1'b0: begin
				data_in 		<= {data_in[14:0], MISO};
				
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
	assign MOSI 				= data_out[15];
	
	always @(posedge SPI_CLK) begin
		case (CSbar)
		1'b1: begin				
			ocounter				<= 5'b0;
			data_out 			<= DATA_MOSI;	
		end
		1'b0: begin
			case (ocounter>15)
			1'b0: begin
				data_out 		<= {data_out[14:0], 1'b0};
				
				ocounter 		<= ocounter + 1;
			end
			1'b1:	begin
				data_out			<= 16'b0;
			end
			endcase
		end
		endcase
	end

endmodule
//=================================================
// END SPI MASTER MODULE
//=================================================
