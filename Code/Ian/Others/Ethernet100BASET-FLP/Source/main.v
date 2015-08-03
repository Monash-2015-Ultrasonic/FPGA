module main (
	input iCLK_50,
	
	inout [31:0] GPIO_0, GPIO_1
	);
	
	wire CLK_100, CLK_20, CLK_16;
	
	CLK_PLL	CLK_PLL_inst (
		.inclk0 	( iCLK_50 	),
		.c0 		( CLK_100 	),
		.c1 		( CLK_16 	)
	);

	Ethernet100BASET ethernet_instant( 
		.CLK100 	( CLK_100	),
		.CLK16	( CLK_16		),
		.TXp		( GPIO_1[0]	),
		.TXm		( GPIO_1[1]	)
	);

endmodule
