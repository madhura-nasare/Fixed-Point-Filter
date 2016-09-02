`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:43:49 04/07/2015 
// Design Name: 
// Module Name:    FixedPoint_IIR_SOS_Filter 
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
module FixedPoint_IIR_SOS_Filter #(parameter  
															No_coeff = 8, // given filter coeeficient number
															WI_IN = 8, //input sample integer bit width
															WF_IN = 18, //input sample fraction bit width
															WI_A = 2, //input coefficient integer width
															WF_A = 8,
															WI_B = 2,
															WF_B = 8,
															WI_G = 5,
															WF_G = 11,
															WI_OUT = WI_IN+WI_G,
															WF_OUT = WF_IN+WF_G) //input coefficient fraction width
											 (input signed [WI_IN+WF_IN-1:0]input_sample,
											  input signed [WI_G+WF_G-1:0] scale_input,
								           input nReset,CLK,CE, 
							              output reg overFlow,
								           output reg signed [WI_OUT+WF_OUT-1:0] Filt_Out);

localparam Filter_Order = 2;
localparam intW_out = WI_IN+WI_G+WI_B+WI_A;
localparam fracW_out = WF_A+WF_B+WF_IN+WF_G;

reg signed [WI_B+WF_B-1:0] coeff_B [0:No_coeff-1]; //memory to store coefficint of filter
reg signed [WI_A+WF_A-1:0] coeff_A [0:No_coeff-1];



reg signed [WI_IN+WF_IN-1:0] delay_wire_IN [0:1]; //delay wire for input sample
wire signed [(WI_IN+WI_B)+ (WF_IN+WF_B)-1:0] Mult_Out_FIR [0:2]; // wire for multiplication output to connect adder
wire signed [(WI_IN+WI_B+Filter_Order)+(WF_IN+WF_B)-1:0] Add_Out_FIR [0:1];// wire for addder output to connect with adder and output

reg signed [intW_out+fracW_out-1:0] feedback_wire_OUT [0:1];
wire signed [intW_out+fracW_out-1:0] Mult_Out_Feedback [0:2];
wire signed [intW_out+fracW_out-1:0] Add_Out_Feedback [0:1];

//wire signed [intW_out+fracW_out-1:0] Mult_Out_Scaling;
wire signed [WI_OUT+WF_OUT-1:0] Mult_Out_Scaling;

//output register for integer and fraction part
reg signed [WI_OUT-1:0] int_out;
reg signed [WF_OUT-1:0] frac_out;
reg signed [intW_out+fracW_out-1:0] feedback_delay;

//overFlow wire for multiplier and adder 
wire [0:2] overFlow_Mul; //overflow for multiplier
wire [0:1] overFlow_Add; //overflow for multiplier
wire [0:2] overFlow_Mul_Feedback;
wire [0:1] overFlow_Add_Feedback;
wire overFlow_Mul_Scaling;
wire CLKen;
integer i;

//-----------filter coefficient memory initialization-----////////
initial begin 

$readmemb("Filter_Coeff_B.txt",coeff_B);
$readmemb("Filter_Coeff_A.txt",coeff_A);

end

//------------------------------------------------------------------//
//--------------------feedforward section---------------------------//
	FixedPoint_Multiplier #(.WI1(WI_B),
									.WF1(WF_B),
									.WI2(WI_IN),
									.WF2(WF_IN),
									.WIO(WI_B+WI_IN),
									.WFO(WF_B+WF_IN))
									 Multiplier00 ( .in1(coeff_B[0]), 
														 .in2(input_sample), 
														 .overFlow(overFlow_Mul[0]), 
														 .FixedPoint_Mul_Out(Mult_Out_FIR[0]));
	
	FixedPoint_Multiplier #(.WI1(WI_B),
									.WF1(WF_B),
							      .WI2(WI_IN),
							      .WF2(WF_IN),
							      .WIO(WI_B+WI_IN),
							      .WFO(WF_B+WF_IN))
									 Multiplier01 ( .in1(coeff_B[1]), 
														 .in2(delay_wire_IN[0]), 
														 .overFlow(overFlow_Mul[1]), 
														 .FixedPoint_Mul_Out(Mult_Out_FIR[1]));
														 
	FixedPoint_Multiplier #(.WI1(WI_B),
									.WF1(WF_B),
							      .WI2(WI_IN),
							      .WF2(WF_IN),
							      .WIO(WI_B+WI_IN),
							      .WFO(WF_B+WF_IN))
									 Multiplier02 ( .in1(coeff_B[2]), 
														 .in2(delay_wire_IN[1]), 
														 .overFlow(overFlow_Mul[2]), 
														 .FixedPoint_Mul_Out(Mult_Out_FIR[2]));
														 
	FixedPoint_Adder #(.WI1(WI_IN+WI_B),
							 .WF1(WF_IN+WF_B),
						    .WI2(WI_IN+WI_B),
						    .WF2(WF_IN+WF_B),
						    .WIO(WI_IN+WI_B+Filter_Order),
						    .WFO(WF_IN+WF_B)) 
						     Adder00 ( .in1(Mult_Out_FIR[1]), 
											.in2(Mult_Out_FIR[2]), 
											.overFlow(overFlow_Add[0]), 
											.FixedPoint_Add_Out(Add_Out_FIR[0]));
											
	FixedPoint_Adder #(.WI1(WI_IN+WI_B),
							 .WF1(WF_IN+WF_B),
						    .WI2(WI_IN+WI_B+Filter_Order),
						    .WF2(WF_IN+WF_B),
						    .WIO(WI_IN+WI_B+Filter_Order),
						    .WFO(WF_IN+WF_B)) 
						     Adder01 ( .in1(Mult_Out_FIR[0]), 
											.in2(Add_Out_FIR[0]), 
											.overFlow(overFlow_Add[1]), 
											.FixedPoint_Add_Out(Add_Out_FIR[1]));

//-----------------------------------------------------------------------------//
//------------------------------feedback section-------------------------------//
	
	FixedPoint_Multiplier #(.WI1(WI_A),
									.WF1(WF_A),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(intW_out),
									.WFO(fracW_out))
									 Multiplier03 ( .in1(coeff_A[1]), 
														 .in2(feedback_wire_OUT[0]), 
														 .overFlow(overFlow_Mul_Feedback[1]), 
														 .FixedPoint_Mul_Out(Mult_Out_Feedback[1]));
														 
	FixedPoint_Multiplier #(.WI1(WI_A),
									.WF1(WF_A),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(intW_out),
									.WFO(fracW_out))
									 Multiplier04 ( .in1(coeff_A[2]), 
														 .in2(feedback_wire_OUT[1]), 
														 .overFlow(overFlow_Mul_Feedback[2]), 
														 .FixedPoint_Mul_Out(Mult_Out_Feedback[2]));
														 
	FixedPoint_Multiplier #(.WI1(WI_A),
									.WF1(WF_A),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(intW_out),
									.WFO(fracW_out))
									 Multiplier05 ( .in1(coeff_A[0]), 
														 .in2(Add_Out_Feedback[0]), 
														 .overFlow(overFlow_Mul_Feedback[0]), 
														 .FixedPoint_Mul_Out(Mult_Out_Feedback[0]));
	
	FixedPoint_Adder #(.WI1(intW_out),
							 .WF1(fracW_out),
							 .WI2(intW_out),
					       .WF2(fracW_out),
							 .WIO(intW_out),
							 .WFO(fracW_out)) 
							  Adder03 ( .in1(Mult_Out_Feedback[1]), 
											.in2(Mult_Out_Feedback[2]), 
											.overFlow(overFlow_Add_Feedback[1]), 
											.FixedPoint_Add_Out(Add_Out_Feedback[1]));
											
	FixedPoint_Adder #(.WI1(WI_IN+WI_B+Filter_Order),
							 .WF1(WF_IN+WF_B),
							 .WI2(intW_out),
							 .WF2(fracW_out),
							 .WIO(intW_out),
							 .WFO(fracW_out)) 
							  Adder02 ( .in1(Add_Out_FIR[1]), 
											.in2(Add_Out_Feedback[1]), 
											.overFlow(overFlow_Add_Feedback[0]), 
											.FixedPoint_Add_Out(Add_Out_Feedback[0]));
											
//---------------------------------------------------------------------------------//
//----------------------------Scaling Multiplier-----------------------------------//

	FixedPoint_Multiplier #(.WI1(WI_G),
									.WF1(WF_G),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(WI_OUT),
									.WFO(WF_OUT))
									 Multiplier06 ( .in1(scale_input), 
														 .in2(Mult_Out_Feedback[0]), 
														 .overFlow(overFlow_Mul_Scaling), 
														 .FixedPoint_Mul_Out(Mult_Out_Scaling));
														 
//----------------------------------------------------------------------------------//
//------------------------------Truncation of Output--------------------------------//

//----------------------integer part truncation or signbit padding-------------------//
	/*always @* begin
	 
	 if(WI_OUT >= intW_out) begin
		int_out = {{(WI_OUT-intW_out){Mult_Out_Scaling[intW_out-1]}} , Mult_Out_Scaling[intW_out+fracW_out-1:fracW]};				
	 end
	 else begin// WI_OUT < intW_out
	 
	 end
	end*/
//----------------------fraction part truncation or zero padding--------------------//
//------------------------overflow condition-------------------------------------//
	always @* begin
	
		overFlow = (|(overFlow_Mul))|(|(overFlow_Add))|(|(overFlow_Mul_Feedback))|(|(overFlow_Add_Feedback))|(overFlow_Mul_Scaling);//overflow for multiplier

	end
//--------------------------clock enable signal--------------------//

	assign CLKen = CLK & CE;

//--------------------------------------output--------------------------------------//
	
	always @(posedge CLK) begin
		
			if(~nReset) begin
				
				for (i = 0; i < 2; i= i+1) begin 
						delay_wire_IN[i] <= 0;
						feedback_wire_OUT[i] <= 0;
						feedback_delay <= 0;
				end
//			Filt_Out <= 0;
				
			end
				
			else begin
					delay_wire_IN[0] <= input_sample;
					delay_wire_IN[1] <= delay_wire_IN[0];
					//feedback_delay <= Mult_Out_Feedback[0];
					//feedback_wire_OUT[0] <= feedback_delay;
					feedback_wire_OUT[0] <= Mult_Out_Feedback[0];
					feedback_wire_OUT[1] <= feedback_wire_OUT[0];
//					Filt_Out <= Mult_Out_Scaling;
			end	
	
	end

	always @* begin
		Filt_Out <= Mult_Out_Scaling;
	end
//--------------------------------------------------------------------------------------------//
//---------------------------------convert everything to real----------------------------------//
/*//=====  Function Definition
	
		function real FixedToFloat;
					input [63:0] in;
					input integer WI;
					input integer WF;
					integer i;
					real retVal;
					
					begin
					retVal = 0;
					
					for (i = 0; i < WI+WF-1; i = i+1) begin
								if (in[i] == 1'b1) begin
										retVal = retVal + (2.0**(i-WF));
								end
					end
					FixedToFloat = retVal - (in[WI+WF-1] * (2.0**(WI-1)));
					end
		endfunction
		
		real delay_wire_real0, delay_wire_real1, feedback_real0,feedback_real1;
		real m_feedback0,m_feedback1,m_feedback2,m_add0,m_add1;
		real f_mul0,f_mul1,f_mul2, f_add0, f_add1;
		real m_scaling;
		//-----------------feedforward part---------------------//
		
		always @ delay_wire_IN[0] delay_wire_real0 = FixedToFloat(delay_wire_IN[0], WI_IN, WF_IN); 
		always @ delay_wire_IN[1] delay_wire_real1 = FixedToFloat(delay_wire_IN[1], WI_IN, WF_IN); 
		
		always @ Mult_Out_FIR[0] f_mul0 = FixedToFloat(Mult_Out_FIR[0], WI_IN+WI_B, WF_IN+WF_B);
		always @ Mult_Out_FIR[1] f_mul1 = FixedToFloat(Mult_Out_FIR[1], WI_IN+WI_B, WF_IN+WF_B);
		always @ Mult_Out_FIR[2] f_mul2 = FixedToFloat(Mult_Out_FIR[2], WI_IN+WI_B, WF_IN+WF_B);
		
		always @ Add_Out_FIR[0] f_add0 = FixedToFloat(Add_Out_FIR[0], WI_IN+WI_B+Filter_Order, WF_IN+WF_B);
		always @ Add_Out_FIR[1] f_add1 = FixedToFloat(Add_Out_FIR[1], WI_IN+WI_B+Filter_Order, WF_IN+WF_B);
		
		//-------------------feedback part------------------------//
		
		always @ feedback_wire_OUT[0] feedback_real0 = FixedToFloat(feedback_wire_OUT[0], intW_out, fracW_out); 
		always @ feedback_wire_OUT[1] feedback_real1 = FixedToFloat(feedback_wire_OUT[1], intW_out, fracW_out); 
		
		always @ Mult_Out_Feedback[0] m_feedback0 =  FixedToFloat(Mult_Out_Feedback[0], intW_out, fracW_out);
		always @ Mult_Out_Feedback[1] m_feedback1 =  FixedToFloat(Mult_Out_Feedback[1], intW_out, fracW_out);
		always @ Mult_Out_Feedback[2] m_feedback2 =  FixedToFloat(Mult_Out_Feedback[2], intW_out, fracW_out);
		
		always @ Add_Out_Feedback[0] m_add0 = FixedToFloat(Add_Out_Feedback[0], intW_out, fracW_out);
		always @ Add_Out_Feedback[1] m_add1 = FixedToFloat(Add_Out_Feedback[1], intW_out, fracW_out);
		
		//------------------scaling-----------------------------//
		
		always @ Mult_Out_Scaling m_scaling  = FixedToFloat(Mult_Out_Scaling, WI_OUT, WF_OUT);*/
		
endmodule 
