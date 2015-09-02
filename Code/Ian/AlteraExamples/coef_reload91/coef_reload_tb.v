`timescale 1 ns / 1 ps

module coef_reload_tb;

parameter DIN_WIDTH = 16;	//input data bit width
parameter DOUT_WIDTH = 38;	//used to calculate output bit width
parameter COEF_NUM = 19;	//reloadable coefficient bit width
parameter NUM_COEF_IN = 80;	//# of reloadable coefficients in fir91_coef_reload0.txt
parameter ENDDAT = 120 ;	//# of input data in data_in.txt
parameter NUM_OUT = 481 ;
parameter MAXVAL_c = 2**(35)-1;
parameter OFFSET_c = 2**(35);


// input port declaration
reg			clk;
reg			reset_n;
reg	[DIN_WIDTH-1:0]	sink_data;
reg			coef_set;
reg			sink_valid;
reg	[1:0]	sink_error;
reg			source_ready;

// coefficient reload input port declaration
reg			coef_set_reload;
reg			coef_we;
reg	[COEF_NUM-1:0]	coef_in;

// output port declaration
wire	[DOUT_WIDTH-1:0]	source_data;
wire	sink_ready;
wire	source_valid;
wire	[1:0]	source_error;


integer input_file;
integer output_file;
integer coef0_file;
integer coef1_file;


initial	begin
	input_file = $fopen("coef_reload_input.txt","r");
	coef0_file = $fopen("fir91_coef_reload_bandpass.txt","r");
	coef1_file = $fopen("fir91_coef_reload_bandreject.txt","r");
    #0 clk = 1'b0;
    #0 reset_n = 1'b0;
	#0 coef_set = 1'b0;
	#0 sink_error = 2'b00;
    #0 source_ready = 1'b1;
    #90 reset_n = 1'b1;
end


// Clock Generation                                                                         
always begin
	#5 clk = 1'b1;
	#5 clk = 1'b0;
end


// sink_valid control generation                                                                         
initial begin
	// feeding data to compute with the 1st default coefficient set  
	#0	 coef_set = 1'b0;
	#0 	 sink_valid = 1'b1;
	#900 sink_valid = 1'b0;

	// feeding data to compute with the 2nd default coefficient set  
	#200 coef_set = 1'b1;
	#0   sink_valid = 1'b1;
	#800 sink_valid = 1'b0;

	// feeding data to compute with the 1st reloaded coefficient set  
	#200 coef_set = 1'b0;
	#0   sink_valid = 1'b1;
	#800 sink_valid = 1'b0;

	// feeding data to compute with the 2nd reloaded coefficient set  
	#200 coef_set = 1'b1;
	#0 sink_valid = 1'b1;
	#800 sink_valid = 1'b0;
end


// start valid for first cycle to indicate that the file reading should start.
reg	start;
always @ (posedge clk) begin
	if (reset_n == 1'b0)
    	start <= 1'b1;
    else begin
    	if (sink_valid == 1'b1 & sink_ready == 1'b1)
        	start <= 1'b0;
    end
end


// Read input data from a file 
integer din_x;
integer din_int;
always @ (posedge clk)begin
	if(reset_n == 1'b0)	begin
		sink_data <= 0;                                                                    
    end                                                                                  
	else begin
		if ((sink_valid & sink_ready) || (start & (sink_valid & !sink_ready))) begin
        	din_x = $fscanf(input_file,"%d",din_int);
            sink_data <= din_int;
		end 
        else begin
		    sink_data <= sink_data;
		end
    end                                                                                 
end      


// coef_we control generation                                                                         
initial begin
	#0	 coef_set_reload = 1'b0;
	#0 	 coef_we = 1'b0;

	// reload 1st coefficient set while data is computing with 2nd default coefficient set  
	#900 coef_set_reload = 1'b0;
	#0   coef_we = 1'b1;
	#800 coef_we = 1'b0;

	// reload 2nd coefficient set while data is computing with 1st reloaded coefficient set  
	#200 coef_set_reload = 1'b1;
	#0   coef_we = 1'b1;
	#800 coef_we = 1'b0;
end


// Read reloadable coefficient from a file
integer coef_x;
integer coef_int;
always @ (posedge clk)	begin
	if(reset_n == 1'b0)
		coef_in <= 0;                                                                                                                                                     
	else begin
		if (coef_we == 1'b1) begin
			case(coef_set_reload)
				0: coef_x = $fscanf(coef0_file,"%d",coef_int);
				1: coef_x = $fscanf(coef1_file,"%d",coef_int);
			endcase
			// DA Parallel: Coefiicient is latched in one clock cycle after coef_we asserted
            coef_in <= coef_int;
			// DA Serial: Coefiicient is latched in two clock cycle after coef_we asserted
			//coef_int_d1 <= coef_int;
            //coef_in <= coef_int_d1;
		end 
        else begin
		    coef_in <= coef_in;
		end
    end                                                                                 
end      

fir91  DUT (.clk(clk),
			.reset_n(reset_n),
			.ast_sink_data(sink_data),
			.coef_set(coef_set),
			.ast_sink_valid(sink_valid),
			.ast_source_ready(source_ready),
			.ast_sink_error(sink_error),
            .coef_set_in(coef_set_reload),
            .coef_we(coef_we),
            .coef_in(coef_in),
            .ast_source_data(source_data),
			.ast_sink_ready(sink_ready),
			.ast_source_valid(source_valid),
			.ast_source_error(source_error));

endmodule
