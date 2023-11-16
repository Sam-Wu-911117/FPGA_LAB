//在七段顯示器上顯示年月日上數計數器(可暫停)，要用小點點做分隔，要有大小月及閏年，從2021/01/01上數至2048/12/31。(ex：2023/01/31 → 23.01.31)
module lab03_1(clk, reset, enable, seg7_sel, seg7_out, dpt, carry, led_com);
input clk, reset, enable; //pin W16, C16, AA15
output[2:0]seg7_sel; //pin AB10, AB11, AA12 
output[6:0] seg7_out; //pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
output dpt, carry, led_com;  //pinAA8, N20,E2
wire clk_count, clk_sel;
wire[3:0] count_out, count5, count4, count3, count2, count1, count0;
assign led_com= 1'b1;
assign count_out= (seg7_sel == 3'b101 )? count0 : (seg7_sel == 3'b100 )? count1 :
(seg7_sel == 3'b011 )? count2 : 
(seg7_sel == 3'b010 )? count3 : 
(seg7_sel == 3'b001 )? count4 : count5;
assign dpt= (seg7_sel == 3'b101 )? 1'b1 : (seg7_sel == 3'b100 )? 1'b0 :
(seg7_sel == 3'b011 )? 1'b1 : 
(seg7_sel == 3'b010 )? 1'b0 : 
(seg7_sel == 3'b001 )? 1'b1 :1'b0;

freq_div #(16) (clk,reset,clk_count);
freq_div #(15) (clk,reset,clk_sel); 
clock(clk_count, reset, enable, count5, count4, count3, count2, count1, count0, carry );
bcd_to_seg7(count_out,seg7_out);
seg7_select#(6) (clk_sel,reset,seg7_sel );
endmodule

module freq_div (clk_in, reset, clk_out);
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

module count_21_48(clk, reset, enable, count1_out,count0_out, carry,start);
input clk, reset, enable,start;
output[3:0] count1_out,count0_out;
output carry;
reg[3:0] count1_out,count0_out;
assign carry = (count0_out== 4'b1000&&count1_out==4'b0100) ? 1 : 0;
always@ (posedge clk or posedge reset)
begin
if(reset)begin
count0_out= 4'b0001;
count1_out=4'b0010;
end
else if(start) begin
count0_out= 4'b0001;
count1_out=4'b0010;
end
else if(enable == 1) begin
if(count0_out== 4'b1000&&count1_out==4'b0100)begin
count0_out=4'b0001;
count1_out=4'b0010;
end
else if(count0_out==4'b1001)begin
count0_out=4'b0000;
count1_out=count1_out+4'b0001;
end
else
count0_out=count0_out+4'b0001;
end
end
endmodule

module seg7_select(clk, reset, seg7_sel);
parameter	num_use= 6;	//設參數
input		clk, reset;
output[2:0]	seg7_sel;
reg	[2:0]	seg7_sel;
always@ (posedge clk or posedge reset) begin
if(reset == 1)
	seg7_sel = 3'b101; // the rightmost one
else
	if(seg7_sel == 6 -num_use)
		seg7_sel = 3'b101; 
	else
		seg7_sel = seg7_sel-3'b001; // shift left
end
endmodule

module count_00_31_bcd(clk, reset, enable, count1_out, count0_out, carry,start);
input clk, reset, enable,start;
output [3:0] count1_out, count0_out;
reg[3:0] count1_out, count0_out;
output carry;
wire carry = ((count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b0001)||(count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b0011)||
(count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b0101)||(count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b0111)||(count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b1000)
||(count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b1010)||(count1_out == 4'b0011 && count0_out == 4'b0001&&countt==4'b1100)
||(count1_out == 4'b0011 && count0_out == 4'b0000&&countt==4'b0100)||(count1_out == 4'b0011 && count0_out == 4'b0000&&countt==4'b0110)||(count1_out == 4'b0011 && count0_out == 4'b0000&&countt==4'b1001)
||(count1_out == 4'b0011 && count0_out == 4'b0000&&countt==4'b1011)||(count1_out == 4'b0010 && count0_out == 4'b1000&&countt==4'b0010)) ? 1 : 0;
reg [3:0]countt;
always@ (posedge clk or posedge reset)begin
if(reset) begin
count1_out = 4'b0000; // 00
count0_out = 4'b0001;
countt=4'b0001;
end
else if(start) begin
count1_out = 4'b0000; // 00
count0_out = 4'b0001;
countt=4'b0001;
end
else if(enable == 1'b1) begin
if(countt==4'b1100)
countt=4'b0001;
if ((count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b0001)||(count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b0011) 
||(count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b0101)||(count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b0111)
||(count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b1000)||(count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b1010)
||(count1_out == 4'b0011 && count0_out == 4'b0001 &&countt==4'b1100)) 
begin// 31
count1_out = 4'b0000; // 00
count0_out = 4'b0001;
countt=countt+4'b0001;
end
else if((count0_out == 4'b0000&&count1_out==4'b0011 &&countt==4'b0100)
||(count0_out == 4'b0000&&count1_out==4'b0011&&countt==4'b0110)||(count0_out == 4'b0000&&count1_out==4'b0011&&countt==4'b1001)
||(count0_out == 4'b0000&&count1_out==4'b0011&&countt==4'b1011)) begin//30
count1_out = 4'b0000;
count0_out = 4'b0001;
countt=countt+4'b0001;
end
else if((count0_out == 4'b1000&&count1_out==4'b0010&&countt==4'b0010))begin//28
count1_out = 4'b0000;
count0_out = 4'b0001;
countt=countt+4'b0001;
end
else if(count0_out==4'b1001)begin
count0_out=4'b0000;
count1_out=count1_out+4'b0001;
end
else
count0_out = count0_out+ 1'b1;
end
end
endmodule

module count_00_12_bcd(clk, reset, enable, count1_out, count0_out, carry,start);
input clk, reset, enable,start;
output [3:0] count1_out, count0_out;
reg[3:0] count1_out, count0_out;
output carry;
wire carry = (count1_out == 4'b0001 && count0_out == 4'b0010) ? 1 : 0;
always@ (posedge clk or posedge reset)begin
if(reset) begin
count1_out = 4'b0000; // 00
count0_out = 4'b0001;
end
else if(start) begin
count1_out = 4'b0000; // 00
count0_out = 4'b0001;
end
else if(enable == 1'b1) begin
if (count1_out == 4'b0001 && count0_out == 4'b0010) begin// 12
count1_out = 4'b0000; // 00
count0_out = 4'b0001;
end
else if(count0_out == 4'b1001) begin
count0_out = 4'b0000;
count1_out = count1_out+ 1'b1;
end
else
count0_out = count0_out+ 1'b1;
end
end
endmodule

module bcd_to_seg7(bcd_in, seg7);
input[3:0] bcd_in;
output[6:0] seg7;
reg[6:0] seg7;
always@ (bcd_in)
case(bcd_in) // abcdefg
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
endmodule

module clock(clk, reset, enable, count5, count4, count3, count2, count1, count0, carry);
input clk, reset, enable;
output[3:0]count5, count4, count3, count2, count1, count0;
output carry;
wire[3:0]count5, count4, count3, count2, count1, count0;
wire carry, carry3, carry2, carry1, carry0;
assign carry =carry0&carry1&carry2 ;
assign carry3 =carry0&carry1;
count_00_12_bcd(clk, reset, carry0, count3, count2, carry1,carry);
count_00_31_bcd M1(clk, reset, enable, count1, count0, carry0,carry);
count_21_48 M2(clk, reset, carry3, count5, count4, carry2,carry); 
endmodule
