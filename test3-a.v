//在七段顯示器上顯示000-to-321 的上數計數器
module count_000_321_top(clk, reset, seg7_sel, enable, seg7_out, dpt_out, carry, led_com);
input	clk, reset, enable;  //pin W16, C16, AA15
output [2:0]seg7_sel; 	   //pin AB10, AB11, AA12 
output [6:0]seg7_out;      // pin AB7, AA7, AB6, AB5, AA9, Y9, AB8 
output dpt_out, led_com, carry;
wire clk_count, clk_sel;
wire [3:0] count_out,count2, count1, count0;
assign dpt_out = 1'b0;
assign led_com = 1'b1;
assign count_out = (seg7_sel == 3'b101) ? count0 : (seg7_sel == 3'b100) ? count1 : count2; //MUX
freq_div #(21) (clk, reset, clk_count);  //slow
freq_div #(17) (clk, reset, clk_sel);    //high
count_000_321 (clk_count, reset, enable,count2, count1, count0, carry); //count0:個位數 count1:十位數
bcd_to_seg7	 (count_out, seg7_out);
seg7_select #(3) (clk_sel, reset, seg7_sel);
endmodule

module count_000_321(clk, reset, enable,count2_out, count1_out, count0_out, carry);
input clk, reset, enable;
output[3:0] count2_out,count1_out, count0_out;
output carry =  carry2 &carry1 & carry0;
wire carry0, carry1,carry2;
count_0_9 C1(clk, reset, enable, count0_out, carry0);
count_0_9 C2(clk, reset, carry0, count1_out, carry1);
count_0_9 C3(clk, reset, carry1, count2_out, carry2);
endmodule

module seg7_select(clk, reset, seg7_sel);
parameter num_use = 6;  //設參數
input	clk, reset;
output[2:0]	seg7_sel;
reg	[2:0]	seg7_sel;
always@ (posedge clk or posedge reset) begin
if(reset == 1)
	seg7_sel = 3'b101; // the rightmost one
else
	if(seg7_sel == 6 - num_use)
		seg7_sel = 3'b101; 
	else
		seg7_sel = seg7_sel - 3'b001; // shift left
end
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;   
input clk_in, reset;
output clk_out;
reg[exp - 1:0] divider;
integer i;
assign clk_out = divider[exp - 1];
always@ (posedge clk_in or posedge reset)begin  //正緣觸發
if(reset)
for(i = 0; i < exp; i = i + 1) divider[i] = 1'b0;
else
divider = divider + 1'b1;
end
endmodule

module count_0_9(clk, reset, enable, count_out, carry);
input clk, reset, enable;
output[3:0] count_out;
output carry;
reg[3:0] count_out;
assign carry = (count_out == 4'b1001) ? 1 : 0;
always@ (posedge clk or posedge reset)begin
if(reset)
count_out = 4'b0;
else if(enable == 1) begin
if(count_out == 4'b1001)
count_out <= 4'b0000;
else
count_out <= count_out + 1;
end
end
endmodule

module bcd_to_seg7(bcd_in, seg7);
input [3:0]bcd_in;
output [6:0]seg7;
reg [6:0]seg7;
always@(bcd_in)begin
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
