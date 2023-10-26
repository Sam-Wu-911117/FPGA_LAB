//3位元來回移位跑馬燈
module LAB_01 (clk, reset, shiftR_out, shiftG_out, ctl_bit);
input 	clk;	 	 // pin W16(10MHz)
input 	reset;	   	 // pin C16
output	[7:0]shiftR_out; 
// pin D7, D6, A9, C9, A8, C8, C11, B11
output	[7:0]shiftG_out; 
// pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
assign shiftG_out =0;
output 	ctl_bit; 	 // pin T22
assign 	ctl_bit= 1'b1;
wire	clk_work;
freq_div	#(20) M1 (clk, reset, clk_work); 
scroll M2 (clk_work, reset, shiftR_out);
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;   
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset)	//正緣觸發
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule

module scroll (clk, reset, shift_out);
input 	clk, reset;
output 	[7:0]shift_out;
wire		[7:0]shift_out;
reg		[8:0]pattern;
assign  	shift_out= pattern[7:0];
always@ (posedge clk or posedge reset)
begin
if(reset)
pattern = 9'b0_1110_0000;
else 
case(pattern)
  9'b0_11100000:pattern = 9'b0_01110000;
  9'b0_01110000:pattern = 9'b0_00111000;  
  9'b0_00111000:pattern = 9'b0_00011100;  
  9'b0_00011100:pattern = 9'b0_00001110;
  9'b0_00001110:pattern = 9'b0_00000111;  
  9'b0_00000111:pattern = 9'b1_00001110;  
  9'b1_00001110:pattern = 9'b1_00011100;
  9'b1_00011100:pattern = 9'b1_00111000;  
  9'b1_00111000:pattern = 9'b1_01110000;
  9'b1_01110000:pattern = 9'b1_11100000;
  9'b1_11100000:pattern = 9'b0_01110000;
default:pattern = 9'b0_11100000;endcase
end
endmodule
