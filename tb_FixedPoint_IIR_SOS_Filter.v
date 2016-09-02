`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:39:27 04/16/2015
// Design Name:   FixedPoint_IIR_SOS_Filter
// Module Name:   C:/Users/218/Desktop/xilinx/FixedPoint_Filter/tb_FixedPoint_IIR_SOS_Filter.v
// Project Name:  FixedPoint_Filter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: FixedPoint_IIR_SOS_Filter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_FixedPoint_IIR_SOS_Filter;

parameter No_Input = 10;
parameter No_SOS = 4;
parameter No_coeff = 8; // given filter coeeficient number
parameter No_scale_Val = 5;
parameter WI_IN = 3; //input sample integer bit width
parameter WF_IN = 7; //input sample fraction bit width
parameter WI_A = 2; //input coefficient integer width
parameter WF_A = 8;
parameter WI_B = 2;
parameter WF_B = 8;
parameter WI_G = 5;
parameter WF_G = 11;
parameter WI_OUT =8;
parameter WF_OUT = 18;

localparam intW_out = WI_IN+WI_G+WI_B+WI_A;
localparam fracW_out = WF_A+WF_B+WF_IN+WF_G;

	// Inputs
	reg [WI_IN+WF_IN-1:0] input_sample;
	reg [WI_G+WF_G-1:0] scale_input;
	reg nReset;
	reg CLK;
	

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
		
	// Instantiate the Unit Under Test (UUT)
	FixedPoint_IIR_SOS_Filter #( .WI_IN(WI_IN),
										  .WF_IN(WF_IN),
										  .WI_A(WI_A),
										  .WF_A(WF_A),
										  .WI_B(WI_B),
										  .WF_B(WF_B),
										  .WI_G(WI_G),
						   			  .WF_G(WF_G),
										  .WI_OUT(WI_OUT), 
										  .WF_OUT(WF_OUT))
										  uut (.input_sample(input_sample), 
												  .scale_input(scale_input), 
												  .nReset(nReset), 
												  .CLK(CLK), 
												  .overFlow(overFlow), 
												  .Filt_Out(Filt_Out));
												
	
	parameter ClockPeriod = 10;
	initial CLK =0;
	always #(ClockPeriod/2) CLK = ~CLK;

	integer i;
	
	initial begin
		// Initialize Inputs
		input_sample = 0;
		scale_input = 16'b00001_00000000000;
		nReset = 0;
		@(posedge CLK) nReset = 0;
		@(posedge CLK) nReset = 1;
				$readmemb("input_sample_IIR.txt",input_sample_IIR);
			for(i=0; i<50; i=i+1) begin
					@(posedge CLK)nReset = 1; input_sample = input_sample_IIR[i]; 
					$display(FixedToFloat(Filt_Out,WI_OUT,WF_OUT));
			end
	@(posedge CLK) nReset = 0;
	@(posedge CLK) nReset = 1;
	@(posedge CLK) ;
       
		// Add stimulus here

	end		  
      
		always @ input_sample input_sample_real = FixedToFloat(input_sample, WI_IN, WF_IN); //convert in1 to real
	
		always @ Filt_Out Filt_Out_real = FixedToFloat(Filt_Out, WI_OUT, WF_OUT);//convert Out2 to real
		
endmodule

