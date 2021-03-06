module FIR_FILTER_MultiplyBlock (
    X,
    Y
);

  // Port mode declarations:
  input signed   [31:0] X;
  output signed  [31:0] Y;

  //Multipliers:

  wire signed [43:0]
    w1,
    w4,
    w3,
    w8,
    w11,
    w192,
    w181,
    w362,
    w362_;

  assign w1 = X;
  assign w11 = w3 + w8; //2195.42405790882 = adderArea(3,34)
  assign w181 = w192 - w11; //2637.83511224265 = subArea(6,40)
  assign w192 = w3 << 6; //shl(6,40)
  assign w3 = w4 - w1; //2408.3135227603 = subArea(2,33)
  assign w362 = w181 << 1; //shl(1,42)
  assign w362_ = -1 * w362; //1902.70085356618 = negArea(1,42)
  assign w4 = w1 << 2; //shl(2,33)
  assign w8 = w1 << 3; //shl(3,34)

  assign Y = w362_[43:12]; //BitwidthUsed(0, 30)

  //FIR_FILTER_MultiplyBlock area estimate = 9144.27354647794;
endmodule //FIR_FILTER_MultiplyBlock




module FIR_FILTER (
    inData,
    CLK,
    outData,
    reset
);

  // Port mode declarations:
  input   [31:0] inData;
  input    CLK;
  output  [31:0] outData;
  input    reset;

  //registerIn
  reg [31:0] inData_in;

  always@(posedge CLK or posedge reset) begin
    if(reset) begin
      inData_in <= 32'h00000000;
    end  else begin
      inData_in <= inData;
    end
  end

  //registerOut
  reg [31:0] outData;
  wire [31:0] outData_in;

  always@(posedge CLK or posedge reset) begin
    if(reset) begin
      outData <= 32'h00000000;
    end  else begin
      outData <= outData_in;
    end
  end

  wire [31:0] multProducts;

  FIR_FILTER_MultiplyBlock my_FIR_FILTER_MultiplyBlock(
    .X(inData_in),
    .Y(multProducts)
  );

  assign outData_in = multProducts;

  //FIR_FILTER area estimate = 14040.7344846426;
endmodule //FIR_FILTER
