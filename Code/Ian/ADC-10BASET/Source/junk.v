//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
// UART:
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	
	reg [7:0]	uart_data 			= 8'b0;
	wire [7:0]	uart_data_ascii;
	reg [3:0]	uart_counter 		= 4'b0;
	wire	TX_busy;
	
	always @(posedge CLK_25) begin
		if (~TX_busy & ~iKEY[0]) begin
			case (uart_counter) 
			4'd0: begin 
				uart_data 		<= ADC_data[15:12]; 
				uart_counter 	<= uart_counter + 1; 
			end
			4'd1: begin 
				uart_data		<= ADC_data[11:8]; 
				uart_counter 	<= uart_counter + 1; 
			end
			4'd2: begin 
				uart_data 		<= ADC_data[7:4]; 
				uart_counter 	<= uart_counter + 1; 
			end
			4'd3: begin 
				uart_data 		<= ADC_data[3:0]; 
				uart_counter 	<= uart_counter + 1; 
			end
			4'd4: begin
				uart_data		<= 31;
				uart_counter 	<= 4'b0;
			end
			default: begin 
				uart_data 		<= ADC_data[15:12]; 
				uart_counter 	<= 4'b0; 
			end
			endcase
		end
		else ;
	end
	
	ASCII_encoder ascii_encoder_instant( 
		.clk		( CLK_25 			),
		.number	( uart_data			),
		.code		( uart_data_ascii	)
	);
	
	async_transmitter uartTX_instant( 
		.clk			( CLK_25				),
		.TxD_start	( ~iKEY[0]			),		//input
		.TxD_data	( uart_data_ascii	),
		.TxD			( oUART_TXD 		), //output
		.TxD_busy 	( TX_busy			)//output
	);
	
	assign oLEDG[8] = TX_busy;