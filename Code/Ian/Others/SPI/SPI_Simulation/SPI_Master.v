//=================================================
// SPI MASTER MODULE
//=================================================
module master(
	input 		RST,
	input 		ENA,
	input 		INTR,
	input 		MISO,
	output reg 	MOSI,
	output reg 	CSbar,
	output reg 	SCK
	);
	
	reg	[15:0]	data_m;
	reg	[15:0]	data_init;
	
	initial begin
		SCK = 1'b0;
		repeat (250) #10 SCK = ~SCK;
	end
	
	initial begin
		data_m = 16'hABCD;
		data_init = data_m;
		
		$display("Initial Data @ MASTER: %b", data_m);
	end
	
	always @(posedge SCK) begin
		if (RST)
			data_m <= data_init;
		else if (ENA && ~INTR) begin
			MOSI <= data_m[15];
			
			data_m <= {data_m[14:0], MISO};
			
			$display("Data at Master: %b", data_m);
		end
	end
	
	always @(posedge SCK) begin
		CSbar = 1'b0;
		
		if (INTR)
			$display("Interrupt is Processing");
	end
	
endmodule
//=================================================
// END SPI MASTER MODULE
//=================================================




//=================================================
// SPI SLAVE MODULE
//=================================================
module slave(
	input 		RST,
	input			ENA,
	input 		INTR,
	input			SCK,
	input			MOSI,
	input			CSbar,
	output reg	MISO
	);
	
	reg	[15:0]	data_s;
	
	integer count = 0;
	
	always @(posedge SCK) begin
		if (~CSbar) begin
			if (RST)
				data_s <= 16'b0;
			else if (ENA && ~INTR) begin
				MISO <= data_s[15];
				
				data_s <= {data_s[14:0], MOSI};
				
				count <= count + 1;
				
				if (count == 16)
					$stop;
					
				$display("Data at SLAVE: %b", data_s);
			end
		end
	end
	
	always @(posedge SCK) begin
		if (INTR)
			$display("Interrupt is Processing");
	end
	
endmodule
//=================================================
// END SPI SLAVE MODULE
//=================================================





//=================================================
// TOP LEVEL MODULE
//=================================================
module stimulus();

	reg RST;
	reg ENA;
	reg INTR;
	wire MISO;
	wire MOSI;
	wire CSbar;
	wire SCK;
	
	initial begin
		RST = 1'b1;
		ENA = 1'b0;
		INTR = 1'b0;
		#1 RST = 1'b0;
		#2 RST = 1'b0;
		#5 RST = 1'b0;
		#2 ENA = 1'b1;
		#12 RST = 1'b1;
		#6 ENA = 1'b0;
		#4 RST = 1'b0;
		#8 ENA = 1'b1;
		#80 INTR = 1'b1;
		#6 INTR = 1'b0;
	end
	
	master SPI_MASTER_INSTANT(
		.RST ( RST ),
		.ENA ( ENA ),
		.SCK ( SCK ),
		.INTR ( INTR ),
		.MOSI ( MOSI ),
		.MISO ( MISO ),
		.CSbar ( CSbar )
		);
		
	slave SPI_SLAVE_INSTANT(
		.RST ( RST ),
		.ENA ( ENA ),
		.SCK ( SCK ),
		.INTR ( INTR ),
		.MOSI ( MOSI ),
		.MISO ( MISO ),
		.CSbar ( CSbar )
		);
		
endmodule
