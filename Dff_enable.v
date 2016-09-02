`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:06:12 04/09/2015 
// Design Name: 
// Module Name:    D_FF 
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
module D_FF #(parameter BW = 9,
								No_SOS = 4)
				 (input signed [BW-1:0]in,
				  input CLK,RESET,
				  output reg signed [BW-1:0] q_out);
		   
	
	reg [BW-1:0] reg_in [ 0:No_SOS-1];
	integer i;
	
	wire [3:0] stage_no;
	reg [3:0] val;
	
	always @(posedge CLK) begin
			if (~RESET) begin
				val<=0;
			end
			else begin
				if(stage_no==No_SOS)
					val <= 0;
				else
					val <= stage_no;
			end	
		end
	
	assign stage_no = val+1;
	
	always @(posedge CLK ) begin
	
		if (~RESET) begin
			for(i = 0; i < No_SOS; i = i+1) begin
				reg_in[i] <= 0;
			end	
		end
		else begin
				reg_in[val] <= in;
		end		
	end
	
		always @(stage_no) begin
			if(~RESET) begin
				q_out = 0;
			end
			else begin
				q_out = reg_in[val];
			end
		end	
endmodule 