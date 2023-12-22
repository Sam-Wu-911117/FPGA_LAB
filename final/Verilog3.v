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
