//=================================================
// ULTRASONIC TRANSMITTER MODULE
//=================================================
module ultrasonicTransmitter # (parameter initial_delay = 0)(
	input 			SYS_CLK,
	input 			CLK_40,
	input 			RST, ON,

	output 			burstStart,
	output [1:0] 	pulseOutput
);

	// Generate 40.21139746kHz pulse for the Ultrasonic Transmitter:
	reg [9:0] usonic;
	always @(posedge CLK_40)
		usonic <= & (~RST & ON) ? usonic + 1 : 0;
	
	// Generate a burst of 32 pulses, then wait approx 14ms:
	reg [9:0] counter_burst;
	always @(posedge usonic[9]) begin
		if (RST | ~ON) begin
			counter_burst <= initial_delay;
		end 
		else begin
			counter_burst <= (counter_burst < 574) ? counter_burst + 1 : 0;
		end
	end		
	
	reg startPREV, startEDGE;
	always @(posedge SYS_CLK) begin
		startPREV <= (counter_burst == 0);
		startEDGE <= ~startPREV & (counter_burst == 0) & ~RST & ON ? 1 : 0;	
	end
	
	assign burstStart = startEDGE;
	
	reg usonicpulse;
	always @(posedge CLK_40)
		usonicpulse <= usonic[9] & (counter_burst < 32) & ~RST & ON;
	
	//assign GPIO_1[24] = usonicpulse;	
	//assign GPIO_1[25] = ~usonicpulse;
	assign pulseOutput = {~usonicpulse, usonicpulse};
	
endmodule
