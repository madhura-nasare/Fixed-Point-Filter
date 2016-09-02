`timescale 1ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:09:52 03/16/2015
// Design Name:   FixedPoint_FIR_Filter
// Module Name:   C:/Users/218/Desktop/xilinx/FixedPoint_Filter/tb_FixedPoint_FIR_Filter.v
// Project Name:  FixedPoint_Filter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: FixedPoint_FIR_Filter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_FixedPoint_FIR_Filter;

parameter No_Input = 50;
parameter Filt_order = 4;
parameter No_coeff = 8;
parameter WI1 = 4;
parameter WF1 = 5;
parameter WIC = 4;
parameter WFC = 5;
parameter WIO = WI1+WIC+Filt_order;
parameter WFO = WF1+WFC;

	// Inputs
	reg [WI1+WF1-1:0] input_sample;
	reg [WI1+WF1-1:0] input_sample_array [0:No_Input-1];
	reg RESET;
	reg CLK;

	// Outputs
	wire [(WI1+WIC+Filt_order)+(WF1+WFC)-1:0] Filt_Out;
	wire overFlow;
	
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

parameter ClockPeriod = 10;
	initial CLK =0;
	always #(ClockPeriod/2) CLK = ~CLK;

initial begin 
$readmemb("Filter_Coeff.txt", tb_FixedPoint_FIR_Filter.uut00.Filter_coeff);
end

	// Instantiate the Unit Under Test (UUT)
	FixedPoint_FIR_Filter #(.Filt_order(Filt_order),
									.No_coeff(No_coeff),
									.WI1(WI1),
									.WF1(WF1),
									.WIC(WIC),
									.WFC(WFC),
									.WIO(WIO),
									.WFO(WFO))
									uut00 (.input_sample(input_sample), .RESET(RESET),	.CLK(CLK), .Filt_Out(Filt_Out), .overFlow(overFlow));

integer i;

initial begin 
	input_sample = 0;
	@(posedge CLK)RESET = 1;
	@(posedge CLK)RESET = 0;
		$readmemb("new_input_sample.txt",input_sample_array);
			for(i=0; i<50; i=i+1) begin
					@(posedge CLK) input_sample = input_sample_array[i]; 
					$display(FixedToFloat(Filt_Out, WI1+WIC+Filt_order, WF1+WFC));
			end
@(posedge CLK) RESET = 1;
@(posedge CLK) RESET = 0;
@(posedge CLK) $finish;
end
      
	always @ input_sample input_sample_real = FixedToFloat(input_sample, WI1, WF1); //convert in1 to real
	
	always @ Filt_Out Filt_Out_real = FixedToFloat(Filt_Out, (WI1+WIC+Filt_order), (WF1+WFC));//convert Out2 to real
		
endmodule

