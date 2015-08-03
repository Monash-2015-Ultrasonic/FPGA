//=================================================
// SPI SLAVE MODULE
//=================================================
module SPI_SLAVE_DEVICE(
	input 	[15:0]	DATA,
	input					SCK,
	input					MOSI,
	input					CSbar,
	output reg			MISO,
	);
	
	reg	[15:0]	data_out = 16'b0;
	reg	[5:0]		ocounter = 5'b0;	
	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// MISO Component (Slave Output/Master Input):
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	always @(posedge SCK) begin
		case (CSbar)
		1'b1: begin
			finished[0] 	<= 1'b0;
			ocounter			<= 5'b0;
			data_out			<= DATA;
			MISO 				<= 1'bz;
		end
		1'b0: begin
			case (finished[0])
			1'b0: begin
				MISO 			<= data_out[15];
				data_out 	<= {data_out[14:0], 1'b0};
			
				ocounter 	<= ocounter + 1;
				finished[0] <= ocounter[4];
			end
			1'b1:			
				MISO			<= 1'bz;
			endcase
		end
		endcase
	end

endmodule
//=================================================
// END SPI SLAVE MODULE
//=================================================	
