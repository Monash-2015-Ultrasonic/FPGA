//=================================================
// SPI MASTER MODULE
//=================================================
module SPI_MASTER_DEVICE(
	input					SPI_CLK,
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
	
	assign SCK 				= SPI_CLK;
	assign CSbar 			= ~ENA;
	assign DATA_MISO 		= data_in_final;
	assign FIN 				= ocounter[4] & icounter[4];
	
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
			case (icounter==16)
			1'b0: begin
				data_in 		<= {data_in[14:0], MISO};
				
				icounter 	<= icounter + 1;
			end
			default: 
				data_in_final <= {data_in[14:0], MISO};
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
			case (ocounter==16)
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


	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// DEBUG:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
//	assign lights = data_in;
//	
//	hex_encoder(data_out[15:12], 	hex7);
//	hex_encoder(data_out[11:8], 	hex6);
//	hex_encoder(data_out[7:4], 	hex5);
//	hex_encoder(data_out[3:0], 	hex4);
//
//	hex_encoder(data_in[15:12], 	hex3);
//	hex_encoder(data_in[11:8], 	hex2);
//	hex_encoder(data_in[7:4], 		hex1);
//	hex_encoder(data_in[3:0], 		hex0);

// TO BE ADDED TO SPI_MASTER_DEVICE PORTS LIST:
//===============================================	
												//,
	//DEBUG:
	//output	[6:0]		hex7, hex6, hex5, hex4, hex3, hex2, hex1, hex0,
	//output 	[16:0]	lights

// TO BE ADDED TO INSTANTIATION:
//===============================================
//		.hex7			( oHEX7_D		),
//		.hex6			( oHEX6_D		),
//		.hex5			( oHEX5_D		),
//		.hex4			( oHEX4_D		),
//		.hex3			( oHEX3_D		),
//		.hex2			( oHEX2_D		),
//		.hex1			( oHEX1_D		),
//		.hex0			( oHEX0_D		),
//		.lights		( oLEDR[16:0]	)
	
endmodule
//=================================================
// END SPI MASTER MODULE
//=================================================
