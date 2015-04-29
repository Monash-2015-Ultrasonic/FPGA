module Ethernet100BASET(
	input			CLK100, CLK16,
	output reg	TXp, TXm
	);
	
	reg [3:0]	LCW = 16'h8100;
	reg [3:0]	i = 4'hFF;
	reg			type1, type2;
	
	reg [10:0]	FLP_clk;
	always @(posedge CLK16)
		FLP_clk <= FLP_clk + 1;

	always @(posedge FLP_clk[10]) begin
		type1 <= ~type1;							// clk 0=off 1=on
		i <= i-1;
	end
	
	always @(negedge FLP_clk[10]) begin
		type2 <= ~type2;							// LCW 0=off 1=on
	end	
		
	reg [17:0] LinkPulseCount; 
	always @(posedge CLK16) 
		LinkPulseCount <= LinkPulseCount + 1;
	
	always @(posedge CLK16) begin
		case (LinkPulseCount[17:15])
		1'b1:
			TXp <= ((type1 ^ type2) ? 1'b1   : LCW[i]) & FLP_clk[10] & ~FLP_clk[9:2] & FLP_clk[1] & ~FLP_clk[0];
		default: 
			TXp <= 1'b0;
		endcase
	end
	
	always @(posedge CLK16) begin
			TXm <= 1'b0;
	end
	
endmodule
