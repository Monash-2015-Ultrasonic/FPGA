module ASCII_encoder( 
	input						clk,
	input 		[4:0]		number,
	output reg 	[7:0]		code
	);
	
	always @(posedge clk) begin
			case (number)
			5'd0: code <= 8'h30;
			5'd1: code <= 8'h31;
			5'd2: code <= 8'h32;
			5'd3: code <= 8'h33;
			5'd4: code <= 8'h34;
			5'd5: code <= 8'h35;
			5'd6: code <= 8'h36;
			5'd7: code <= 8'h37;
			5'd8: code <= 8'h38;
			5'd9: code <= 8'h39;
			5'd10: code <= 8'h41;
			5'd11: code <= 8'h42;
			5'd12: code <= 8'h43;
			5'd13: code <= 8'h44;
			5'd14: code <= 8'h45;
			5'd15: code <= 8'h46;
			5'd30: code <= 8'h0A;
			5'd31: code <= 8'h0D;
			default: code <= 8'h0D;
			endcase				
	end
	
endmodule
	