module main ( 
	input		iCLK_50,
	
	inout		[31:0]	GPIO_0, GPIO_1
	);
	
	wire CLK_100, CLK_25, CLK_20;
	
	CLK_PLL clk_pll_instant(
		.inclk0 (iCLK_50),
		.c0		(CLK_100),
		.c1		(CLK_25),
		.c2		(CLK_20)
	);
	
	Ethernet_10BASE_TX ethernet_instant( 
		.clk20 ( CLK_20),
		.Ethernet_TDp ( GPIO_1[0] ), 
		.Ethernet_TDm ( GPIO_1[1] )
	);
	
endmodule
