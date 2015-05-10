module Ethernet100BASET(
	input			CLK100, CLK16,
	output reg	TXp, TXm
	);

	reg [9:0] pwmcount;
	reg dutycycle = 1;
	reg pwm;
	
	reg [15:0]	LCW = 16'h8100;
	reg [5:0] 	position;
	reg [3:0] 	LCWposition;
	reg TXout;

	always @(negedge pwmcount[9]) begin
		if (position < 33) begin
			position <= position + 1;
			case (position[0])
			1'b0: begin TXout <= 1; end
			1'b1: begin TXout <= LCW[LCWposition]; LCWposition <= LCWposition + 1; end
			endcase
		end
		else begin
			position <= 0;
			TXout <= 0;
		end
	end
	
	reg [17:0]	counter;
	always @(posedge CLK16) begin
		counter <= counter + 1;
	end
	
	always @ (posedge CLK16) begin
		pwmcount <= pwmcount + 1;
			
		TXp = (dutycycle >= pwmcount) & TXout;// & counter[17];
	end
	
	always @(posedge CLK16) begin
		TXm <= ~TXp;
	end
	
endmodule
