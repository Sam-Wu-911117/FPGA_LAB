//於8×8 LCD矩陣上，設計一個3-bit流水燈(可暫停)，由左上至左下，碰到底後再由左下反彈沿原路徑倒退回到左上。
module test6(clk, reset, sel,row, column_green, column_red);
input clk;	 	    // pin W16
input reset;	    // pin C16
input sel;			// pin AA15
output [7:0]column_green; // pin A10, B10, A13, A12, B12, D12, A15, A14
output [7:0]column_red; // pin D7, D6, A9, C9, A8, C8, C11, B11 
output [7:0]row; //pin T22,R21,C6,B6,B5,A5,B7,A7
wire   [4:0]addr;
wire   [63:0]shift_out;
wire   [7:0]data;
wire   [7:0]shift0, shift1, shift2, shift3, shift4, shift5, shift6, shift7;
wire   clk_work, clk_scan;
wire   [2:0]idx;
wire   up;

assign up=(shift_out== 64'b11100000_00000000_00000000_00000000_00000000_00000000_00000000_00000000)?1'b0:
(shift_out== 64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000111)?1'b1:up;

assign addr   = { 1'b0, idx };
assign shift0 = shift_out[63:56];
assign shift1 = {shift_out[48], shift_out[49], shift_out[50], shift_out[51], shift_out[52], shift_out[53], shift_out[54], shift_out[55]};
assign shift2 = shift_out[47:40];
assign shift3 = {shift_out[32], shift_out[33], shift_out[34], shift_out[35], shift_out[36], shift_out[37], shift_out[38], shift_out[39]};
assign shift4 = shift_out[31:24];
assign shift5 = {shift_out[16], shift_out[17], shift_out[18], shift_out[19], shift_out[20], shift_out[21], shift_out[22], shift_out[23]};
assign shift6 = shift_out[15:8];
assign shift7 = {shift_out[0], shift_out[1], shift_out[2], shift_out[3], shift_out[4], shift_out[5], shift_out[6], shift_out[7]};

//下去時綠色，上來時紅色
//assign column_green =(up==1'b0)?data:8'b0;
//assign column_red	  =(up==1'b1)?data:8'b0;
assign column_green = data;

freq_div#(20) 	M0 (clk, reset, clk_work); 
freq_div#(13) 	M1 (clk, reset, clk_scan); 
move  			M2 (clk_work, reset,sel, up, shift_out);
map				M3 (addr,shift0, shift1, shift2, shift3, shift4, shift5, shift6, shift7, data);
idx     		M4 (clk_scan, reset, idx, row);

endmodule


module freq_div(clk_in, reset, clk_out);
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


module move (clk, reset,enable, up, shift_out);
input clk, reset, enable, up;
output	[63:0]shift_out;
reg	[63:0]	shift_out;
always@ (posedge clk or posedge reset)
begin
if(reset)
shift_out= 64'b11110000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
else if(enable==1'b0 && up==1'b0)
shift_out= {shift_out[0], shift_out[63:1]};
else if(enable==1'b0 && up==1'b1)
shift_out= {shift_out[62:0], shift_out[63]};
else if(enable==1'b1)
shift_out=shift_out;
end
endmodule



module		map(addr,shift0, shift1, shift2, shift3, shift4, shift5, shift6, shift7, data);
input		[3:0]addr;
output reg 	[7:0]data;
input       [7:0]shift0, shift1, shift2, shift3, shift4, shift5, shift6, shift7;
always@(addr)
begin
case(addr)
	4'd0  	:data=shift0;           
	4'd1  	:data=shift1;
	4'd2  	:data=shift2;
	4'd3  	:data=shift3;
	4'd4  	:data=shift4;
	4'd5  	:data=shift5;
	4'd6  	:data=shift6;
	4'd7  	:data=shift7;
	default	:data=8'b0000_0000;
endcase
end
endmodule


module 	idx(clk, reset, idx, row);
input		 reset, clk;
output reg	[2:0]idx;
output reg	[7:0]row;
always@(posedge clk or posedge reset)
begin
	if(reset) begin
		idx<=3'b000;
		row<=8'b1000_0000;
	end
	else begin
		idx<=idx+3'b001;
		row<={row[0],row[7:1]};
	end
end
endmodule
