module LAB_03(clk, reset, seg7_sel, enable, seg7_out, dpt_out, carry, led_com);
input clk, reset, enable; //pin 55,124,47
output[2:0] seg7_sel; //pin 37,36,33
output[6:0] seg7_out; // pin23,26,27,28,29,30,31
output dpt_out, led_com, carry;
wire clk_count, clk_sel;
wire[3:0] count_out, count1, count0;
assign dpt_out= 1'b0;
assign led_com= 1'b1;
assign count_out= (seg7_sel == 3'b101 )? count0 : count1; //MUX
freq_div #(21) (clk, reset, clk_count); // slow
freq_div #(17) (clk, reset, clk_sel); // high
count_00_23 (clk_count, reset, enable, count1, count0, carry);
bcd_to_seg7 (count_out, seg7_out);
seg7_select #(2) (clk_sel, reset, seg7_sel);
endmodule

module freq_div(clk_in, reset, clk_out);
parameter	exp = 20;   
input 		clk_in, reset;
output 		clk_out;
reg 			[exp - 1:0]divider;
integer 		i;
assign clk_out = divider[exp - 1];
always@ (posedge clk_in or posedge reset)	//正緣觸發
begin
if(reset)
for(i = 0; i < exp; i = i + 1) divider[i] = 1'b0;
else
divider = divider + 1'b1;
end
endmodule

module count_00_23_bcd(clk, reset, enable, count1, count0, carry);
input 	clk, reset, enable;
output 	[3:0]count1, count0;
reg 		[3:0]count1, count0;
output 	carry;
wire 		carry;
assign carry = (count1 == 4'b0010 & count0 == 4'b0011) ? 1 : 0;  //count0:個位數 count1:十位數
always@ (posedge clk or posedge reset)begin
if(reset) begin
count1 <= 4'b0000;
count0 <= 4'b0000;
end
else if(enable == 1'b1) begin
	if (count1 == 4'b0010 & count0 == 4'b0011) begin  //23
	count1 = 4'b0000;  //00
	count0 = 4'b0000;
	end
	else if(count0 == 4'b1001) begin
	count0 = 4'b0000;
	count1 = count1 + 1'b1;
	end
	else
	count0 = count0 + 1'b1;
	end
end
endmodule

module seg7_select(clk, reset, seg7_sel);
parameter num_use = 6;	//設參數
input	clk, reset;
output [2:0]seg7_sel;
reg [2:0]seg7_sel;
always@ (posedge clk or posedge reset) begin
if(reset == 1)	
seg7_sel = 3'b101;  //the rightmost one
else
	if(seg7_sel == 6 - num_use)
	seg7_sel = 3'b101; 
	else
	seg7_sel = seg7_sel - 3'b001;  //shift left
end
endmodule

module bcd_to_seg7(bcd_in, seg7);
input [3:0]bcd_in;
output [6:0]seg7;
reg[6:0] seg7;
always@ (bcd_in)begin
case(bcd_in)  //abcdefg
4'b0000: seg7 = 7'b1111110; // 0
4'b0001: seg7 = 7'b0110000; // 1
4'b0010: seg7 = 7'b1101101; // 2
4'b0011: seg7 = 7'b1111001; // 3
4'b0100: seg7 = 7'b0110011; // 4
4'b0101: seg7 = 7'b1011011; // 5
4'b0110: seg7 = 7'b1011111; // 6
4'b0111: seg7 = 7'b1110000; // 7
4'b1000: seg7 = 7'b1111111; // 8
4'b1001: seg7 = 7'b1111011; // 9
default: seg7 = 7'b0000000; 
endcase
end
endmodule
