`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:21:37 04/19/2015 
// Design Name: 
// Module Name:    FixedPoint_IIR_SOS_Filter_TM 
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
module FixedPoint_IIR_SOS_Filter_TM #(parameter
															No_SOS = 1,
															No_scale_Val = 5,
															No_coeff = 8, // given filter coeeficient number
															WI_IN = 8, //input sample integer bit width
															WF_IN = 18, //input sample fraction bit width
															WI_A = 3, //input coefficient integer width
															WF_A = 8,
															WI_B = 3,
															WF_B = 8,
															WI_G = 5,
															WF_G = 11,
															WI_OUT = WI_IN+WI_G,
															WF_OUT = WF_IN+WF_G) //input coefficient fraction width
											 (input signed [WI_IN+WF_IN-1:0]input_sample,
											  input nReset,CLK,CE,
							              output reg overFlow,
								           output reg signed [WI_OUT+WF_OUT-1:0] Filt_Out);

wire CLKen;
localparam Filter_Order = 2;

//fix bitwidth for feedback section
localparam intW_out = WI_IN+WI_G+WI_B+WI_A;
localparam fracW_out = WF_A+WF_B+WF_IN+WF_G;

//bitwidth parameter at output of scaling multiplier
localparam scaledW_int = WI_IN+WI_G; 
localparam scaledW_frac = WF_IN+WF_G;

//register to hold coefficient value at each iteration
reg signed [WI_B+WF_B-1:0]fforward_coeff_0;
reg signed [WI_B+WF_B-1:0]fforward_coeff_1;
reg signed [WI_B+WF_B-1:0]fforward_coeff_2;
reg signed [WI_A+WF_A-1:0]fback_coeff_0;
reg signed [WI_A+WF_A-1:0]fback_coeff_1;
reg signed [WI_A+WF_A-1:0]fback_coeff_2;

//register to hold scaling value at each iteration
reg signed [WI_G+WF_G-1:0] scale_input;

// flag to keep track of stage
wire [3:0] stage_no;		

//delay wire for input sample						           
wire signed [scaledW_int+scaledW_frac-1:0] delay_wire_IN [0:1];

// wire for multiplication output to connect adder 
wire signed [(scaledW_int+WI_B)+ (scaledW_frac+WF_B)-1:0] Mult_Out_FIR [0:2];
 
// wire for addder output to connect with adder and output
wire signed [(scaledW_int+WI_B+2)+(scaledW_frac+WF_B)-1:0] Add_Out_FIR [0:1];

//wire to for feedback register
wire signed [intW_out+fracW_out-1:0] feedback_wire_OUT [0:1];

//wire for  feedback portion adder 
wire signed [intW_out+fracW_out-1:0] Mult_Out_Feedback [0:2];

//wire for feedback portion multiplier
wire signed [intW_out+fracW_out-1:0] Add_Out_Feedback [0:1];

//wire signed [intW_out+fracW_out-1:0] Mult_Out_Scaling;
//wire at output of scaling multiplier of SOS
wire signed [WI_OUT+WF_OUT-1:0] Mult_Out_Scaling;

//overFlow wire for multiplier and adder 
wire [0:2] overFlow_Mul; 
wire [0:1] overFlow_Add; 
wire [0:2] overFlow_Mul_Feedback;
wire [0:1] overFlow_Add_Feedback;
wire overFlow_Mul_Scaling;
wire overFlow_Mul_scale_in;
wire signed [scaledW_int+scaledW_frac-1:0] scaled_input;

//register to hold internal output of SOS
reg signed [scaledW_int+scaledW_frac-1:0] internal_out ;

//memory to hold all coefficients
reg signed [WI_A+WF_A-1:0] Filter_Coeff [0:(6 * No_SOS)-1];

//memory to hold all scaling coefficients
reg signed [WI_G+WF_G-1:0] scale_coeff [0:No_scale_Val-1];

// register to hold intermidiate input for each SOS
reg signed [scaledW_int+scaledW_frac-1:0] reg_in;
integer i = 0;
integer j = 0;
reg state;
reg s0 = 1'b0, s1 = 1'b1;
//--------------------------clock enable signal--------------------//
assign CLKen = CE & CLK;

//initial reg_in = 0;

//------------------------------------------------------------------//
//---------------------scaling Multiplier---------------------------//
	FixedPoint_Multiplier #(.WI1(WI_G),
									.WF1(WF_G),
									.WI2(WI_IN),
									.WF2(WF_IN),
									.WIO(scaledW_int),
									.WFO(scaledW_frac))
									 Multiplier07 ( .in1(scale_coeff[0]), 
														 .in2(input_sample), 
														 .overFlow(overFlow_Mul_scale_in), 
														 .FixedPoint_Mul_Out(scaled_input));

//------------------------------------------------------------------//
//--------------------feedforward section---------------------------//
//------------------------------------------------------------------//
	//register 01
	D_FF #( .BW(scaledW_int+scaledW_frac),
				.No_SOS(No_SOS))
			   Dff00 (.RESET(nReset),
			          .CLK(CLKen),
			          .in(reg_in),
			          .q_out(delay_wire_IN[0]));
	//register 02					 
	D_FF #( .BW(scaledW_int+scaledW_frac),
				.No_SOS(No_SOS))
			   Dff01 (.RESET(nReset),
			          .CLK(CLKen),
			          .in(delay_wire_IN[0]),
			          .q_out(delay_wire_IN[1]));
						 
//-------------------Multiplier-----------------------------------//

	FixedPoint_Multiplier #(.WI1(WI_B),
									.WF1(WF_B),
									.WI2(scaledW_int),
									.WF2(scaledW_frac),
									.WIO(WI_B+scaledW_int),
									.WFO(WF_B+scaledW_frac))
									 Multiplier00 ( .in1(fforward_coeff_0), 
														 .in2(reg_in), 
														 .overFlow(overFlow_Mul[0]), 
														 .FixedPoint_Mul_Out(Mult_Out_FIR[0]));
	
	FixedPoint_Multiplier #(.WI1(WI_B),
									.WF1(WF_B),
									.WI2(scaledW_int),
									.WF2(scaledW_frac),
									.WIO(WI_B+scaledW_int),
									.WFO(WF_B+scaledW_frac))
									 Multiplier01 ( .in1(fforward_coeff_1), 
														 .in2(delay_wire_IN[0]), 
														 .overFlow(overFlow_Mul[1]), 
														 .FixedPoint_Mul_Out(Mult_Out_FIR[1]));
														 
	FixedPoint_Multiplier #(.WI1(WI_B),
									.WF1(WF_B),
									.WI2(scaledW_int),
									.WF2(scaledW_frac),
									.WIO(WI_B+scaledW_int),
									.WFO(WF_B+scaledW_frac))
									 Multiplier02 ( .in1(fforward_coeff_2), 
														 .in2(delay_wire_IN[1]), 
														 .overFlow(overFlow_Mul[2]), 
														 .FixedPoint_Mul_Out(Mult_Out_FIR[2]));
//----------------------------Adder-------------------------------------//													 
	FixedPoint_Adder #(.WI1(WI_B+scaledW_int),
							 .WF1(WF_B+scaledW_frac),
						    .WI2(WI_B+scaledW_int),
						    .WF2(WF_B+scaledW_frac),
						    .WIO(scaledW_int+WI_B+Filter_Order),
						    .WFO(WF_B+scaledW_frac)) 
						     Adder00 ( .in1(Mult_Out_FIR[1]), 
											.in2(Mult_Out_FIR[2]), 
											.overFlow(overFlow_Add[0]), 
											.FixedPoint_Add_Out(Add_Out_FIR[0]));
											
	FixedPoint_Adder #(.WI1(WI_B+scaledW_int),
							 .WF1(WF_B+scaledW_frac),
						    .WI2(WI_B+scaledW_int),
						    .WF2(WF_B+scaledW_frac),
						    .WIO(scaledW_int+WI_B+Filter_Order),
						    .WFO(WF_B+scaledW_frac)) 
						     Adder01 ( .in1(Mult_Out_FIR[0]), 
											.in2(Add_Out_FIR[0]), 
											.overFlow(overFlow_Add[1]), 
											.FixedPoint_Add_Out(Add_Out_FIR[1]));

//------------------------------------------------------------------------//
//------------------------------feedback section--------------------------//
//------------------------------------------------------------------------//
	//register01
	D_FF #( .BW(intW_out+fracW_out),
			  .No_SOS(No_SOS))
			   Dff02 (.RESET(nReset),
			          .CLK(CLKen),
			          .in(Mult_Out_Feedback[0]),
			          .q_out(feedback_wire_OUT[0]));
	//register02					 
	D_FF #( .BW(intW_out+fracW_out),
			  .No_SOS(No_SOS))
			   Dff03 (.RESET(nReset),
			          .CLK(CLKen),
			          .in(feedback_wire_OUT[0]),
			          .q_out(feedback_wire_OUT[1]));
	
//------------------------------Multiplier------------------------------//	
	FixedPoint_Multiplier #(.WI1(WI_A),
									.WF1(WF_A),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(intW_out),
									.WFO(fracW_out))
									 Multiplier03 ( .in1(fback_coeff_1), 
														 .in2(feedback_wire_OUT[0]), 
														 .overFlow(overFlow_Mul_Feedback[1]), 
														 .FixedPoint_Mul_Out(Mult_Out_Feedback[1]));
														 
	FixedPoint_Multiplier #(.WI1(WI_A),
									.WF1(WF_A),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(intW_out),
									.WFO(fracW_out))
									 Multiplier04 ( .in1(fback_coeff_2), 
														 .in2(feedback_wire_OUT[1]), 
														 .overFlow(overFlow_Mul_Feedback[2]), 
														 .FixedPoint_Mul_Out(Mult_Out_Feedback[2]));
														 
	FixedPoint_Multiplier #(.WI1(WI_A),
									.WF1(WF_A),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(intW_out),
									.WFO(fracW_out))
									 Multiplier05 ( .in1(fback_coeff_0), 
														 .in2(Add_Out_Feedback[0]), 
														 .overFlow(overFlow_Mul_Feedback[0]), 
														 .FixedPoint_Mul_Out(Mult_Out_Feedback[0]));

//---------------------------------Adder--------------------------//	
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
											
	FixedPoint_Adder #(.WI1(scaledW_int+WI_B+Filter_Order),
							 .WF1(scaledW_frac+WF_B),
							 .WI2(intW_out),
							 .WF2(fracW_out),
							 .WIO(intW_out),
							 .WFO(fracW_out)) 
							  Adder02 ( .in1(Add_Out_FIR[1]), 
											.in2(Add_Out_Feedback[1]), 
											.overFlow(overFlow_Add_Feedback[0]), 
											.FixedPoint_Add_Out(Add_Out_Feedback[0]));
											
//---------------------------------------------------------------------//
//----------------------------Scaling Multiplier-----------------------//

	FixedPoint_Multiplier #(.WI1(WI_G),
									.WF1(WF_G),
									.WI2(intW_out),
									.WF2(fracW_out),
									.WIO(scaledW_int),
									.WFO(scaledW_frac))
									 Multiplier06 ( .in1(scale_input), 
														 .in2(Mult_Out_Feedback[0]), 
														 .overFlow(overFlow_Mul_Scaling), 
														 .FixedPoint_Mul_Out(Mult_Out_Scaling));
														 

//------------------------overflow condition------------------------//
	always @* begin
		//overflow for multiplier
		overFlow = (|(overFlow_Mul))|(|(overFlow_Add))|(|(overFlow_Mul_Feedback))|(|(overFlow_Add_Feedback))|(overFlow_Mul_Scaling);

	end

//-------------------------------output---------------------------//
//-----------------Finite State Machine---------------------------// 
always @(posedge CLKen) begin
		if (~nReset) begin
			i <= 0;
			//reg_in <=0;
		end
		else begin
			if(stage_no == No_SOS)
				i <= 0;
			else
				i <= stage_no;
		end
	end
	
	assign stage_no = i+1;
	
	always @(posedge CLKen) begin
		if(~nReset) begin
			reg_in <= 0;
			Filt_Out <= 0;
		end
		else begin
		if(stage_no == No_SOS)
			Filt_Out <= Mult_Out_Scaling;
		end
	end
	
	always @(stage_no) begin
		/*if(~nReset) begin
			reg_in = 0;
			end
		else begin*/
		if (stage_no == 1) begin
				reg_in = scaled_input;
				
					fforward_coeff_0 <= Filter_Coeff[(i*6)];
					fforward_coeff_1 <= Filter_Coeff[(i*6)+1];
					fforward_coeff_2 <= Filter_Coeff[(i*6)+2];
				
					fback_coeff_0 <= Filter_Coeff[(i*6)+3];
					fback_coeff_1 <= Filter_Coeff[(i*6)+4];
					fback_coeff_2 <= Filter_Coeff[(i*6)+5];
					
					scale_input <= scale_coeff[i+1]; 
			end
			else begin
				internal_out = Mult_Out_Scaling;
				reg_in = internal_out;
				fforward_coeff_0 <= Filter_Coeff[(i*6)];
					fforward_coeff_1 <= Filter_Coeff[(i*6)+1];
					fforward_coeff_2 <= Filter_Coeff[(i*6)+2];
				
					fback_coeff_0 <= Filter_Coeff[(i*6)+3];
					fback_coeff_1 <= Filter_Coeff[(i*6)+4];
					fback_coeff_2 <= Filter_Coeff[(i*6)+5];
					scale_input <= scale_coeff[i+1]; 
			end
			//end
	end

	
	//-----------------------------------//
//---------------------------------convert everything to real----------------------------------//
//=====  Function Definition
	/*
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
