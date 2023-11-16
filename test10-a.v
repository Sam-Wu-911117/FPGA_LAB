//做出以下迷宮，共有兩張地圖，星星為起始位置，走到正字記號即接到第二張地圖，走到第二張地圖的右下出口處即通關，撞牆要顯示全版綠，通關時需顯示綠色笑臉，迷宮及笑臉如下：
module 	lab08_3(clk, row, red, green, column, sel, reset);

input 		clk,reset;     		//pin W16, C16
input 		[2:0]column;		//pin AA13, AB12, Y16
output	[7:0] row,red, green;		
// row pin T22,R21,C6,B6,B5,A5,B7,A7
// red pin D7, D6, A9, C9, A8, C8, C11, B11
// green pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14

//output carry;
output 	[2:0] sel;			//pin AB10, AB11, AA12
wire 		ck, press, press_vaild;
wire [1:0] coll,k;

wire 		[3:0]keycode, scancode;
wire [4:0]addr;
wire		[2:0]idx;
wire		[7:0]hor, ver;
//reg [2:0]sel;
assign 	addr = { coll, idx };
//assign k=((ver==8'b1000_0000)&&(hor==8'b0000_0010)&&(row==8'b1000_0000))? 2'b01:2'b00;

key_decode 	M1 (sel,column,press,scancode);
key_buff 	M2 (ck,reset,press_vaild,scancode,keycode);
vaild		M3 (ck,reset,press,press_vaild);
count6  	M4 (ck,reset,sel);
move		M5 (reset,coll,keycode,ver,hor,ck);
 	
freq_div#(14) 	M6 (clk,reset,ck);
//freq_div#(23) 	M20 (clk,reset,clk_count);
map		M7 (addr,green);
idx		M8 (ck,reset,idx,row);
mix		M9 (ver,hor,row,red,k);
collision 	M10 (ck,reset,red,green,coll,k);

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

module count6(clk,rst,sel);
input clk,rst;
output [2:0]sel;
reg[2:0]sel;
always@ (posedge clk or posedge rst)
begin
if(rst)
sel=3'b000;
else begin
if(sel==3'b101)
sel=3'b0;
else
sel=sel+3'b001;
end
end
endmodule

/*module count_0_1(clk, reset, enable, count_out, carry,start,j,k);
input clk, reset,start,enable;
input [1:0]k;
output[3:0] count_out;
output carry,j;

reg[3:0] count_out;
reg j;
assign carry = (count_out== 4'b0) ? 1 : 0;
always@ (posedge clk or posedge reset)
begin
if(reset)begin
count_out= 4'b0001;
j=1'b0;
end
else if(start)begin

count_out= 4'b0000;
//n=1'b1;
end
else if(enable==1&&k==2'b00 ) 
begin
if(count_out== 4'b0)begin
//~~~~your code~~~~//count_out back to 0
//count_out=count_out-4'b0001;
count_out=4'b0;
j=1'b1;
end
else begin
//~~~~your code~~~~//count_out add 1
//count_out=4'b1001;
count_out=count_out-4'b0001;
//n=1'b0;
end
end
end
endmodule*/

/*module count_0_5(clk, reset,n, count_out, carry,start,x,y,p);
input clk, reset,start;
input n;
input		y,p;
output[3:0] count_out;
output carry,x;

reg[3:0] count_out;
reg x;
assign carry = (count_out== 4'b0) ? 1 : 0;
always@ (posedge clk or posedge reset)
begin
if(reset)begin
count_out= 4'b0101;
x=2'b00;
//m=1'b0;
end
else if(start)begin
count_out= 4'b0000;
//m=1'b1;
//start=1'b0;
end
else if( (p==1'b0)&&(y==1'b0)) 
begin
if(count_out== 4'b0)begin
count_out=4'b1001;
x=1'b1;
end
else begin
count_out=count_out-4'b0001;
//x=1'b0;
end
end
end
endmodule*/


/*module seg7_select(clk, reset, seg7_sel);
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
endmodule*/

/*module bcd_to_seg7(bcd_in, seg7);
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
endmodule*/

module key_decode(sel, column, press, scan_code);
input[2:0]sel;
input[2:0] column;
output press;
output[3:0] scan_code;
reg[3:0] scan_code;
reg press;
always@(sel or column) begin
case(sel)
3'b000:
case(column)
//3'b011: begin scan_code= 4'b0001; press = 1'b1; end // 1
3'b101: begin scan_code= 4'b0010; press = 1'b1; end // 2
//3'b110: begin scan_code= 4'b0011; press = 1'b1; end // 3
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b001:
case(column)
3'b011: begin scan_code= 4'b0100; press = 1'b1; end // 4
//3'b101: begin scan_code= 4'b0101; press = 1'b1; end // 5
3'b110: begin scan_code= 4'b0110; press = 1'b1; end // 6
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b010:
case(column)
//3'b011: begin scan_code= 4'b0111; press = 1'b1; end // 7
3'b101: begin scan_code= 4'b1000; press = 1'b1; end // 8
//3'b110: begin scan_code= 4'b1001; press = 1'b1; end // 9
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b011:
case(column)
3'b101: begin scan_code= 4'b0000; press = 1'b0; end // 0
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
default:
begin scan_code= 4'b0000; press = 1'b0; end
endcase
end
endmodule

module vaild (clk,rst,press,press_valid);
input press,clk,rst;
output press_valid;
reg[5:0] gg;
assign press_valid=~(gg[5]||(~press));
always@(posedge clk or posedge rst)
begin
if(rst)
	gg<=6'b0;
else
	gg<={gg[4:0],press};
end
endmodule

module key_buff(clk, rst, press_valid, scan_code, key_code);
input clk, rst, press_valid;
input[3:0] scan_code;
output[3:0]key_code;
reg[3:0]key_code;
always@(posedge clk or posedge rst) begin
if(rst)
key_code= 4'b0000;// initial value
else
key_code= press_valid ? scan_code:4'b0000;
end
endmodule

module 	shift(left, right, reset, unable, out, clk);
input 		left, right, reset, clk;
input [1:0] unable;
output reg	[7:0]out;

always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b0000_0010;
	/*else if(unable==2'b10)
		out<=8'b0001_0000;*/
	else if(unable==2'b01||unable==2'b11) 		//碰撞狀態
 		out<=8'b0000_0000;
 	else if(left)
		out={out[6:0],out[7]};
	else if(right)
		out={out[0],out[7:1]};
 	else
  		out<=out;
end
endmodule

module 	shift_1(up,down, reset, unable, out, clk);
input 		up, down, reset, clk;
input  [1:0]unable;
//input  [1:0]k;
output reg	[7:0]out;

always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b1000_0000;
	/*else if(unable==2'b10)
		out<=8'b0000_0100;*/
	else if(unable==2'b01||unable==2'b11) 		//碰撞狀態
 		out<=8'b0000_0000;
 	/*else if(k==2'b01)
		out<=8'b0000_0000;*/
 	else if(up)
		out={out[6:0],out[7]};
	else if(down)
		out={out[0],out[7:1]};
 	else
  		out<=out;
end
endmodule

module	move(reset, unable, keycode, ver, hor, clk);
input 		reset, clk;
input [1:0] unable;
input 		[3:0]keycode;
output 	[7:0]ver, hor;
wire		left, right, up, down;

assign 	left   =~keycode[1]&  keycode[2];
assign 	right =  keycode[1]&  keycode[2];
assign 	up    =  keycode[1]& ~keycode[2];
assign	down=  keycode[3];

shift S1(left,right,reset,unable,hor,clk); //left & right
shift_1 S2(up,down,reset,unable,ver,clk); //up & down

endmodule

module		map(addr,data);
input		[4:0]addr;
output reg 	[7:0]data;
always@(addr)
begin
case(addr)
	5'd0  	:data=8'b1111_1101;           //請自行設計地圖
	5'd1  	:data=8'b1000_0001; 
	5'd2  	:data=8'b1011_1111; 
	5'd3  	:data=8'b1000_0001;
	5'd4  	:data=8'b1111_1101; 
	5'd5  	:data=8'b1001_0001; 
	5'd6  	:data=8'b1100_0101;
	5'd7  	:data=8'b1111_1111; 
	
	5'd8  	:data=8'b1111_1111;
	5'd9  	:data=8'b1111_1111;
	5'd10	:data=8'b1111_1111;
	5'd11	:data=8'b1111_1111;
	5'd12	:data=8'b1111_1111;
	5'd13	:data=8'b1111_1111;
	5'd14	:data=8'b1111_1111;
	5'd15	:data=8'b1111_1111;
	
	5'd16	:data=8'b1111_1111;
	5'd17	:data=8'b1000_1001;
	5'd18	:data=8'b1010_0101;
	5'd19	:data=8'b1001_0101;
	5'd20	:data=8'b1101_0001;
	5'd21	:data=8'b1001_0111;
	5'd22	:data=8'b1111_0000;
	5'd23	:data=8'b1111_1111;
	
	5'd24	:data=8'b0011_1100;
	5'd25	:data=8'b0100_0010;
	5'd26	:data=8'b1010_0101;
	5'd27	:data=8'b1000_0001;
	5'd28	:data=8'b1010_0101;
	5'd29	:data=8'b1001_1001;
	5'd30	:data=8'b0100_0010;
	5'd31	:data=8'b0011_1100;
	
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

module 	mix(ver, hor, row, red,k);
input		[7:0]ver, hor, row;
output 	[7:0]red;
output  [1:0]k;

assign 	red=(ver==row) ? hor:8'b0000_0000;
assign  k=((ver==8'b0000_0010)&&(hor==8'b0000_0001))?2'b01:((ver==8'b0000_0100)&&(hor==8'b0100_0000))?2'b10 :2'b00;

endmodule

module  	collision(clk, reset, red, green, coll,k);
input		clk, reset;
input       [1:0]k;
input		[7:0]red, green;
output [1:0]coll;

reg 	[1:0]coll;

//assign m=2'b00;
always@(posedge clk or posedge reset)
begin
	if(reset)begin
		coll<=2'b00;
		
		end
	else if(((red & green) != 8'b0)) begin   //發生碰撞
		coll<=2'b01;
		end
	else if(k==2'b10)
		coll<=2'b10;
	else if (k==2'b01)begin
		coll<=2'b11;
		
		end
	else
	 coll<=coll;
end
endmodule






