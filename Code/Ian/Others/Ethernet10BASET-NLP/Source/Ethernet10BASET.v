module Ethernet10BASET(
	input 		clk20,
	output reg 	Ethernet_TDp, Ethernet_TDm 			// the two differential 10BASE-T outputs
);
	// generate the NLP
	reg [17:0] LinkPulseCount; 
	always @(posedge clk20) 
		LinkPulseCount <= LinkPulseCount + 1;

	reg LinkPulse; 
	always @(posedge clk20) 
		LinkPulse <= &LinkPulseCount[17:1];

	reg qoe; 
	always @(posedge clk20) 
		qoe <= LinkPulse;

	always @(posedge clk20) 
		Ethernet_TDp <= (qoe ? 1'b1 : 1'b0);
		
	always @(posedge clk20) 
		Ethernet_TDm <= (qoe ? 1'b0 : 1'b0);

endmodule
