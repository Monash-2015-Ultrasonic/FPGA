module SPI_Master(
	iCLK_50,
	
	oLEDG,
	oLEDR,
	
	iSW,
	
	GPIO_0
	);
	input iCLK_50;
	
	inout [31:0] GPIO_0;
	
	input [17:0] iSW;
	
	output reg [7:0] oLEDG;
	output  [17:0] oLEDR;
	
	wire CLK_20;
	wire clk = CLK_20;
	CLK_PLL	CLK_PLL_inst (
		.inclk0 ( iCLK_50 ),
		.c0 ( CLK_20 )
	);
	
	assign 	GPIO_0[1] = CLK_20;

	assign 	GPIO_0[0] = CS;
	
	wire 		MISO;
	assign 	MISO = GPIO_0[3];
	
	wire 		MOSI;
	assign 	GPIO_0[5] = MOSI;
	
	
	
	
	// sync SCK to the FPGA clock using a 3-bits shift register

	// same thing for SSEL
	
	// and for MISO
	reg [1:0] MISOr;  
	always @(posedge clk) 
		MISOr <= {MISOr[0], MISO};
	
	wire MISO_data = MISOr[1];		
		
		reg CS;
	always @(posedge clk) begin
			if (~byte_two_received)
					CS <= 0;
			else
				CS <= 1;
	end
		

	assign oLEDR[11:0] = byte_data_received[11:0];
	assign oLEDR[17] = CS;
	assign oLEDR[16] = byte_two_received;
	
	
	
	// we handle SPI in 16-bits format, so we need a 4 bits counter to count the bits as they come in
	reg [3:0] bitcnt;

	reg byte_two_received;  // high when a word has been received
	reg [15:0] byte_data_received;
	
	always @(posedge clk)
	begin
	if (~CS) begin
			if (bitcnt == 4'b1111)
				bitcnt <= 4'b0000;
			else
			 bitcnt <= bitcnt + 4'b0001;

			 // implement a shift-left register (since we receive the data MSB first)
			 byte_data_received <= {byte_data_received[14:0], MISO_data};
	end
	end

	always @(posedge clk) begin
		byte_two_received <= (bitcnt==4'b1111);
	end
		
	always @(posedge clk) begin
		if(byte_two_received) 
			oLEDG[7] <= 1;
		else
			oLEDG[7] <= 0;
			
		oLEDG[3:0] <= byte_data_received[15:12];
	end
	
	
	
	
	
	

//	reg SSEL_startmessage = 1;
//	
//	reg [15:0] configuration = 16'h2A00;
//	reg [15:0] byte_data_sent;
//
//	always @(posedge clk) begin
//	if (CS) begin
//			if(SSEL_startmessage) begin
//				byte_data_sent <= configuration;  // first byte sent in a message is the message count
//			 SSEL_startmessage <= 0;
//			end
//			else 
//				byte_data_sent <= {byte_data_sent[14:0], 1'b0};
//
//			if (bitcnt == 4'b1111)
//				SSEL_startmessage <= 1;
//	end
//	end
//
//	assign MOSI = byte_data_sent[15];  // send MSB first
//	// we assume that there is only one slave on the SPI bus
//	// so we don't bother with a tri-state buffer for MISO
//	// otherwise we would need to tri-state MISO when SSEL is inactive	
	
	
	
		
endmodule
