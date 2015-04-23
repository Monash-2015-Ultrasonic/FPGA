module TOPLEVEL(
	input 				iCLK_50,
	
	inout	reg	[31:0]	GPIO_0, GPIO_1,
	
	input 	[3:0]		iKEY,
	input		[17:0]	iSW,
	
	output	reg [8:0]		oLEDG,
	output 	[17:0]	oLEDR,
	output 	[7:0]		oHEX0_D, oHEX1_D, oHEX2_D, oHEX3_D, oHEX4_D, oHEX5_D, oHEX6_D, oHEX7_D
	);


	always @(posedge iCLK_50)
	begin
		if (~iKEY[3])
			GPIO_0[0] <= 1'b1;
		else 
			GPIO_0[0] <= 1'b0;
	end
	
	reg [11:0] 	counter;
	reg [1:0] 	iEcho;
	always @(posedge iCLK_50)
	begin
		iEcho <= {iEcho[0], GPIO_0[1]};
		
		if (~iEcho[1] & iEcho[0])
			counter <= 1;
		else if (iEcho[1] & iEcho[0])
			counter <= counter + 1;
		else ;
	end
	
	reg [31:0] temp_Time, temp_Distance;
	always @(posedge iCLK_50)
	begin
		if (~iEcho[1] & ~iEcho[0]) begin
			temp_Time <= counter * 20;	//nS
			temp_Distance <= temp_Time /58;
		end
		else ;
	end
	
	always @(posedge iCLK_50)
	begin	
		if (temp_Distance <10000)
			oLEDG[0] <= 1'b1;
		else;
		oLEDG[7] <= ~iKEY[3];
	end

endmodule
