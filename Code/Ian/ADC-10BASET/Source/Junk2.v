//	SPI_MASTER_DEVICE ADC1_instant(
//		.SPI_CLK 	( counter[1]		),
//		.ENA 			( ~auto_sample[24]	),  	
//		.DATA_MOSI 	( ADC1_cmd 			),
//		.MISO 		( GPIO_0[9] 		),		// MISO = SDO 		= 3
//		.MOSI 		( GPIO_0[11] 		),		// MOSI = SDI 		= 4
//		.SCK 			( GPIO_0[13]		),		// SCK = SCLK 		= 5
//		.CSbar 		( GPIO_0[14] 		),		// CSbar = CSbar 	= 6
//		.FIN 			( ADC_fin[1] 		),
//		.DATA_MISO 	( ADC1_data 		)
//	);
//	
//	SPI_MASTER_DEVICE ADC2_instant(
//		.SPI_CLK 	( counter[2]		),
//		.ENA 			( ~auto_sample[24]	),  	
//		.DATA_MOSI 	( ADC2_cmd 			),
//		.MISO 		( GPIO_0[15] 		),		// MISO = SDO 		= 3
//		.MOSI 		( GPIO_0[17] 		),		// MOSI = SDI 		= 4
//		.SCK 			( GPIO_0[19]		),		// SCK = SCLK 		= 5
//		.CSbar 		( GPIO_0[21] 		),		// CSbar = CSbar 	= 6
//		.FIN 			( ADC_fin[2]		),
//		.DATA_MISO 	( ADC2_data 		)
//	);
//	
//	SPI_MASTER_DEVICE ADC3_instant(
//		.SPI_CLK 	( counter[3]		),
//		.ENA 			( ~auto_sample[24]	),  	
//		.DATA_MOSI 	( ADC3_cmd 			),
//		.MISO 		( GPIO_0[25] 		),		// MISO = SDO 		= 3
//		.MOSI 		( GPIO_0[27] 		),		// MOSI = SDI 		= 4
//		.SCK 			( GPIO_0[29]		),		// SCK = SCLK 		= 5
//		.CSbar 		( GPIO_0[31] 		),		// CSbar = CSbar 	= 6
//		.FIN 			( ADC_fin[3]		),
//		.DATA_MISO 	( ADC3_data 		)
//	);
//	
//	SPI_MASTER_DEVICE ADC4_instant(
//		.SPI_CLK 	( counter[4]		),
//		.ENA 			( ~auto_sample[24]	),  	
//		.DATA_MOSI 	( ADC4_cmd 			),
//		.MISO 		( GPIO_0[24] 		),		// MISO = SDO 		= 3
//		.MOSI 		( GPIO_0[26] 		),		// MOSI = SDI 		= 4
//		.SCK 			( GPIO_0[28]		),		// SCK = SCLK 		= 5
//		.CSbar 		( GPIO_0[30] 		),		// CSbar = CSbar 	= 6
//		.FIN 			( ADC_fin[4]		),
//		.DATA_MISO 	( ADC4_data 		)
//	);