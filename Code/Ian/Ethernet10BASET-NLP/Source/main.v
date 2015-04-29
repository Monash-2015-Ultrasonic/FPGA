module main(
	input iCLK_50,
	
	inout	[31:0] GPIO_0, GPIO_1,
	output [8:0] oLEDG,
	input [3:0]	iKEY
	);
	
	wire CLK_20;
	
	CLK_PLL	CLK_PLL_inst (
		.inclk0 	( iCLK_50	),
		.c0 		( CLK_20		)
	);

	Ethernet10BASET ethernet_instant( 
		.clk20 	( CLK_20		),
		.Ethernet_TDp		( GPIO_1[0]	),
		.Ethernet_TDm 		( GPIO_1[1]	)
	);

endmodule
