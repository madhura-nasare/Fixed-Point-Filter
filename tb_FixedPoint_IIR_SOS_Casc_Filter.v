`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:56:47 04/19/2015
// Design Name:   FixedPoint_IIR_SOS_Casc_Filter
// Module Name:   C:/Users/218/Desktop/xilinx/FixedPoint_Filter/tb_FixedPoint_IIR_SOS_Casc_Filter.v
// Project Name:  FixedPoint_Filter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: FixedPoint_IIR_SOS_Casc_Filter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_FixedPoint_IIR_SOS_Casc_Filter;

parameter No_Input = 10;
parameter No_SOS = 4;
parameter WI_IN = 3; //input sample integer bit width
parameter WF_IN = 7; //input sample fraction bit width
parameter WI_A = 2; //input coefficient integer width
parameter WF_A = 8;
parameter WI_B = 2;
parameter WF_B = 8;
parameter WI_G = 5;
parameter WF_G = 11;
//parameter WI_OUT = WI_IN+WI_G;
//parameter WF_OUT = WF_IN+WF_G;
parameter WI_OUT =12;
parameter WF_OUT = 24;

	// Inputs
	reg [9:0] input_sample;
	reg nReset;
	reg CLK;
	reg CE;
	
	reg [WI_A+WF_A-1:0] Filter_Coeff [0:(6 * No_SOS)-1];
	reg [WI_IN+WF_IN-1:0] input_sample_IIR [0:No_Input-1];
	
	// Outputs
	wire overFlow;
	wire [WI_OUT+WF_OUT-1:0] Filt_Out;

		//Real Number Presentation
	real input_sample_real;
	real Filt_Out_real;
	
//=====  Function Definition
	
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
		
		always @ input_sample input_sample_real = FixedToFloat(input_sample, WI_IN, WF_IN); //convert in1 to real
	
		always @ Filt_Out Filt_Out_real = FixedToFloat(Filt_Out, WI_OUT, WF_OUT);//convert Out2 to real		
		
	// Instantiate the Unit Under Test (UUT)
	FixedPoint_IIR_SOS_Casc_Filter #( .No_SOS(No_SOS),
												 .WI_IN(WI_IN),
												 .WF_IN(WF_IN),
												 .WI_A(WI_A),
												 .WF_A(WF_A),
												 .WI_B(WI_B),
												 .WF_B(WF_B),
												 .WI_G(WI_G),
												 .WF_G(WF_G),
												 .WI_OUT(WI_OUT), 
												 .WF_OUT(WF_OUT))
												  uut00 ( .input_sample(input_sample), 
															 .nReset(nReset), 
															 .CLK(CLK), 
															 .CE(CE), 
														    .overFlow(overFlow), 
															 .Filt_Out(Filt_Out));
															 
	parameter ClockPeriod = 10;
	initial CLK =0;
	always #(ClockPeriod/2) CLK = ~CLK;

	integer j;
	
	initial begin
	
	$readmemb ("Filter_Coeff_IIR.txt",Filter_Coeff);
	$readmemb ("scaling_coeff.txt",tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.scale_coeff);
	
	for (j = 0; j < 3; j = j+1) begin
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[0].FP_SOS00.coeff_B[j] = Filter_Coeff[j];
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[0].FP_SOS00.coeff_A[j] = Filter_Coeff[j+3];
	end
	
	for (j = 0; j < 3; j = j+1) begin
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[1].FP_SOS00.coeff_B[j] = Filter_Coeff[j+6];
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[1].FP_SOS00.coeff_A[j] = Filter_Coeff[(j+3)+6];
	end
	
	for (j = 0; j < 3; j = j+1) begin
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[2].FP_SOS00.coeff_B[j] = Filter_Coeff[j+12];
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[2].FP_SOS00.coeff_A[j] = Filter_Coeff[(j+3)+12];
	end
	
	for (j = 0; j < 3; j = j+1) begin
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[3].FP_SOS00.coeff_B[j] = Filter_Coeff[j+18];
		tb_FixedPoint_IIR_SOS_Casc_Filter.uut00.FixedPoint_SOS[3].FP_SOS00.coeff_A[j] = Filter_Coeff[(j+3)+18];
	end
	
	end

	integer i;
	
	initial begin
		// Initialize Inputs
		input_sample = 0;
		nReset = 0;
		CE = 1;
	@(posedge CLK) nReset = 0;
	@(posedge CLK) nReset = 1;
	
		$readmemb("input_sample_IIR.txt",input_sample_IIR);
			for(i=0; i<No_Input; i=i+1) begin
					@(posedge CLK)nReset = 1; input_sample = input_sample_IIR[i]; 
//					@(posedge CLK);
					$display(FixedToFloat(Filt_Out, WI_OUT,WF_OUT));
			end
	@(posedge CLK) nReset = 0;
	@(posedge CLK) nReset = 1;
	@(posedge CLK) ;
	
	end


      
endmodule

