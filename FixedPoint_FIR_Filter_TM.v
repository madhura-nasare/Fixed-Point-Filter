`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:24:39 03/16/2015 
// Design Name: 
// Module Name:    FixedPoint_FIR_Filter_TM 
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
module FixedPoint_FIR_Filter_TM #(parameter Filt_order = 4,
										    No_coeff = 8,
										    WI1 = 4,
										    WF1 = 5,
										    WIC = 4,
										    WFC = 5,
											 WIO = WI1+WIC+Filt_order,
											 WFO = WF1+WFC )
										   (input signed [WI1+WF1-1:0]input_sample, 
										    input RESET ,CLK,
											 input inputValid,
										    output reg [1:0] overFlow,
										    output reg signed [WIO+WFO-1:0] Filt_Out);
										 
										 
										 
										 
reg signed [WIC+WFC-1:0] coeff; 
reg signed [WIC+WFC-1:0] Filter_coeff [0:No_coeff-1];//memory to store coefficint of filter

reg signed [WI1+WF1-1:0] delay_wire [0:Filt_order+1];
reg signed [WI1+WF1-1:0] delay; // reg to store current value of input during iteratiom

wire signed [(WIC+WI1)+ (WFC+WF1)-1:0] Mult_Out;

wire signed [(WI1+WIC+Filt_order)+(WF1+WFC)-1:0] Add_Out;

wire  overFlow_Mul;

wire  overFlow_Add;

reg state;
reg s0 = 1'b0, s1 = 1'b1;

integer i = 0;
integer j = 0;
reg [(WI1+WIC+Filt_order)+(WF1+WFC)-1:0] Add_reg ;

//-----------filter coefficient memory initialization-----////////
initial begin 
$readmemb("Filter_Coeff.txt", Filter_coeff);
end
	
	//-----------one adder------///
	FixedPoint_Multiplier  #(.WI1(WIC),
									 .WF1(WFC),
							       .WI2(WI1),
							       .WF2(WF1),
							       .WIO(WIC+WI1),
							       .WFO(WFC+WF1))
									  Multiplier00 ( .in1(coeff), .in2(delay), .overFlow(overFlow_Mul), .FixedPoint_Mul_Out(Mult_Out));
	
	//----------one multiplier-------//								  
	FixedPoint_Adder    #(.WI1(WIC+WI1),
								 .WF1(WFC+WF1),
						       .WI2(WI1+WIC),
						       .WF2(WFC+WF1),
						       .WIO(WI1+WIC+Filt_order),
						       .WFO(WFC+WF1)) 
						        Adder00 (.in1(Mult_Out), .in2(Add_reg), .overFlow(overFlow_Add), .FixedPoint_Add_Out(Add_Out));
						  

	
	always @(posedge CLK) begin
		
			if (RESET) begin
				state <= s0;
				delay <= 0 ;
				coeff<=0;
				Add_reg <=0;
				Filt_Out<=0;
				for(j = 0; j<Filt_order+1; j=j+1) begin
						delay_wire [j] <= 0;
						end
			//	$readmemb("reset_delay_wire.txt",delay_wire);//reset delay wire memory
			end
			
			else begin
			
			
			case(state)
			//state S0 to initialize all value to zero and put input valur into 
			//delay_wire[0] location
				s0:begin
					if (inputValid) begin
					Add_reg <=0;
					delay <= 0 ;
					coeff<=0;
					delay_wire[0] <= input_sample;
					state <= s1;
					end
					else begin
					state <= s0;
					end
					end
			//state S1 to start computation for input sample and take out filter output		
				s1:begin	
						Add_reg <=  Add_Out;
						coeff <= Filter_coeff[i];
						delay<=delay_wire[i];
						if ( i <= Filt_order) begin
						state <= s1;
						i = i+1;
						end
						else begin
						Filt_Out <= Add_Out; //final filter output
						state<= s0;
						i=0;
						for(j = 0; j<Filt_order+1; j=j+1) begin
							delay_wire [j+1] <= delay_wire[j];
						end
								
						end
					end
			endcase
		end
	end
	
	always @* begin
		if ((overFlow_Add) && (overFlow_Mul))
			overFlow = 2'b11; //both overflow
		else if ((!overFlow_Add) && (overFlow_Mul))
			overFlow = 2'b01; //adder overflow
		else if ((overFlow_Add) && (overFlow_Mul))
			overFlow = 2'b10; // multiplier overflow
		else 
			overFlow = 2'b00;
	
	end
endmodule
