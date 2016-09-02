`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:29:15 03/16/2015 
// Design Name: 
// Module Name:    FixedPoint_FIR_Filter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module FixedPoint_FIR_Filter #(parameter Filt_order = 4, //filter order parameter
										 No_coeff = 8, // given filter coeeficient number
										 WI1 = 4, //input sample integer bit width
										 WF1 = 5, //input sample fraction bit width
										 WIC = 4, //input coefficient integer width
										 WFC = 5,
										 WIO = WI1+WIC+Filt_order,
										 WFO = WF1+WFC) //input coefficient fraction width
										(input signed [WI1+WF1-1:0]input_sample, 
										 input RESET ,CLK, 
										 output reg [1:0] overFlow,
										 output reg signed [WIO+WFO-1:0] Filt_Out);



reg signed [WIC+WFC-1:0] Filter_coeff [0:No_coeff-1]; //memory to store coefficint of filter

wire signed [WI1+WF1-1:0] delay_wire [0:Filt_order]; //delay wire for input sample
wire signed [(WIC+WI1)+ (WFC+WF1)-1:0] Mult_Out [0:Filt_order]; // wire for multiplication output to connect adder
wire signed [(WI1+WIC+Filt_order)+(WF1+WFC)-1:0] Add_Out [0:Filt_order-1];// wire for addder output to connect with adder and output
wire [0:Filt_order] overFlow_Mul; //overflow for multiplier
wire [0:Filt_order-1] overFlow_Add; //overflow for multiplier


//-----------filter coefficient memory initialization-----////////
//initial begin 
//$readmemb("Filter_Coeff.txt", Filter_coeff);
//end

assign delay_wire[0] = input_sample;

//--------delay element generation-----------------//
genvar j;
generate
for (j=0; j<Filt_order; j= j+1)
	begin: delay_element
	Dff  #(.BW(WI1+WF1)) 
		    Dff00 (.RESET(RESET), .CLK(CLK), .d(delay_wire[j]), .q(delay_wire[j+1]));
	end
endgenerate
//----------multiplier generation--------------///
genvar i;
generate 
for (i=0; i<Filt_order+1; i=i+1)
	begin: FP_Mul
		FixedPoint_Multiplier #(.WI1(WIC),
									   .WF1(WFC),
							         .WI2(WI1),
							         .WF2(WF1),
							         .WIO(WIC+WI1),
							         .WFO(WFC+WF1))
										Multiplier00 ( .in1(Filter_coeff[i]), .in2(delay_wire[i]), .overFlow(overFlow_Mul[i]), .FixedPoint_Mul_Out(Mult_Out[i]));
	end
endgenerate 

//-----------single adder for addition of first two multiplier output----//////
		FixedPoint_Adder #(.WI1(WIC+WI1),
								 .WF1(WFC+WF1),
						       .WI2(WI1+WIC),
						       .WF2(WFC+WF1),
						       .WIO(WI1+WIC+Filt_order),
						       .WFO(WFC+WF1)) 
						        Adder00 (.in1(Mult_Out[0]), .in2(Mult_Out[1]), .overFlow(overFlow_Add[0]), .FixedPoint_Add_Out(Add_Out[0]));

//------------generation of adder -----------------///////////
genvar k;
generate
for ( k=1; k<Filt_order; k=k+1)
	begin: FP_Adder
		FixedPoint_Adder #(.WI1(WIC+WI1),
								 .WF1(WFC+WF1),
							    .WI2(WI1+WIC+Filt_order),
							    .WF2(WFC+WF1),
							    .WIO(WI1+WIC+Filt_order),
							    .WFO(WFC+WF1)) 
								  Adder01 (.in1(Mult_Out[k+1]), .in2(Add_Out[k-1]), .overFlow(overFlow_Add[k]), .FixedPoint_Add_Out(Add_Out[k]));
	end
endgenerate

////////////////---------overflow condition---------------///////
always @* begin
	if (|(overFlow_Add) && |(overFlow_Mul)) begin
		overFlow = 2'b11;
	end
	else if ((overFlow_Add) && !(|(overFlow_Mul))) begin
		overFlow = 2'b10;
	end
	else if (!(|(overFlow_Add)) && (overFlow_Mul)) begin
		overFlow = 2'b10;
	end
	else begin
		overFlow = 2'b00;
	end
end

//---------Final Output----------//
always @(posedge CLK) begin
 
 if(RESET)
	Filt_Out <= 0;
 else
	Filt_Out <= Add_Out[Filt_order-1];
	
end
endmodule

