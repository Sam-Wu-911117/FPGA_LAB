//設計一個12小時制之倒數時間顯示器。
module test(clk, reset, enable, seg7_sel, seg7_out, dpt, carry, led_com);
input clk, reset, enable; //pin W16, C16, AA15
output[2:0]seg7_sel;//pin AB10, AB11, AA12
output[6:0] seg7_out; // pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
output dpt, carry, led_com; //pinAA8, N20, E2
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
hrcount(clk,reset,clk_count);
//freq_div #(23) (clk,reset,clk_count); // slow
freq_div #(15) (clk,reset,clk_sel); // high
clock(clk_count, reset, enable, count5, count4, count3, count2, count1, count0, carry);
bcd_to_seg7(count_out,seg7_out);
seg7_select #(6) (clk_sel, reset, seg7_sel);
endmodule 

//-------------------------------------------------------------
module freq_div (clk_in, reset, clk_out);
parameter exp = 20;
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset)
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule
//-------------------------------------------------------------
module hrcount(clk,reset,clk_out);
input clk,reset;
output clk_out;
reg [0:23]temp;
assign clk_out=(temp==24'b100110001001011010000000)?1:0;
always@(posedge clk or posedge reset)begin
if(reset)
temp=24'b0;
else if (temp==24'b100110001001011010000000)
temp=24'b0;
else
temp=temp+1'b1;
end
endmodule

//-------------------------------------------------------------
module count_00_59_bcd(clk, reset, enable, count1, count0, carry);
input clk, reset, enable;
output [3:0] count1, count0;
reg[3:0] count1, count0;
output carry;
wire carry = (count1 == 4'b0000 && count0 == 4'b0000) ? 1 : 0;
always@ (posedge clk or posedge reset)begin
if(reset) begin
count1 = 4'b0101; // 59
count0 = 4'b1001;
end
else if(enable == 1'b1) begin
if (count1 == 4'b0000 && count0 == 4'b0000) begin// 59
count1 = 4'b0101; // 00
count0 = 4'b1001;
end
else if(count0 == 4'b0000) begin
count0 = 4'b1001;
count1 = count1- 1'b1;
end
else
count0 = count0- 1'b1;
end
end
endmodule
//-------------------------------------------------------------
module count_00_11_bcd(clk, reset, enable, count1, count0, carry);
input clk, reset, enable;
output[3:0] count1, count0;
reg[3:0] count1, count0;
output carry;
wire carry = (count1 == 4'b0000 && count0 == 4'b0000) ? 1 : 0;
always@ (posedge clk or posedge reset)begin
if(reset) begin
count1 = 4'b0001; // 00
count0 = 4'b0001;
end

else if(enable == 1'b1) begin
if (count1 == 4'b0000 && count0 == 4'b0000) begin// 11
count1 = 4'b0001; // 00
count0 = 4'b0001;
end
else if(count0 == 4'b0000) begin
count0 = 4'b1001;
count1 = count1- 1'b1;
end
else
count0 = count0- 1'b1;
end
end
endmodule

//-------------------------------------------------------------

module bcd_to_seg7 (bcd_in, seg7);
input[3:0] bcd_in;
output[6:0] seg7;
reg[6:0] seg7;
always@ (bcd_in)
case(bcd_in)
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
//-------------------------------------------------------------

module clock(clk, reset, enable, count5, count4, count3, count2, count1, count0, carry);
input clk, reset, enable;
output[3:0]count5, count4, count3, count2, count1, count0;
output carry;
wire[3:0]count5, count4, count3, count2, count1, count0;
wire carry, carry3, carry2, carry1, carry0;
assign carry = carry0 & carry1 & carry2 ;
assign carry3 = carry0 & carry1 ;
count_00_11_bcd(clk, reset, carry3, count5, count4, carry2);
count_00_59_bcd(clk, reset, carry0, count3, count2, carry1);
count_00_59_bcd(clk, reset, enable, count1, count0, carry0); 
endmodule
//-----------------------------------------------------------

module seg7_select (clk, reset, seg7_sel);
parameter num_use= 6; //set parameter
input clk, reset;
output [2:0]seg7_sel;
reg [2:0]seg7_sel;

always@ (posedge clk or posedge reset) begin

if(reset == 1)
seg7_sel = 3'b101; // the rightmost one
else
if(seg7_sel==6-num_use)
seg7_sel=3'b101;
else
seg7_sel=seg7_sel-3'b001; // shift left
end

endmodule