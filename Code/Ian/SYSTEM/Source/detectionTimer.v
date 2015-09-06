//=================================================
// DETECTION COUNTER MODULE
//=================================================
module detectionTimer (
	input 				SYS_CLK,
	input 				SYS_RST, ON,
	
	input 				timerRST,
	input					timerSTOP,
	output reg [9:0] 	timerOUTPUT
);
	reg [9:0] time_counter;
	always @(posedge SYS_CLK) begin
		if (SYS_RST | timerRST | ~ON) begin
			time_counter <= 0;
		end
		else begin
			time_counter <= timerSTOP ? time_counter : time_counter + 1;
		end
	end
	
	always @(posedge SYS_CLK)
		timerOUTPUT <= time_counter;

endmodule
