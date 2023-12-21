module final(clk, rst, column, row, column_green, column_red, sel);
input clk, rst;
input [2:0]column;	//AA13,AB12,Y16	
output[7:0] row, column_green, column_red;
//row:pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
//column_green/red比照Lab1
output [2:0]sel;	//AB10,AB11,AA12
wire clk_shift, clk_scan, clk_out, press, press_valid, coll;
wire[1:0] sel_col;
wire[6:0] keycode, scan_code;
wire[6:0] idx, idx_cnt;
wire[7:0] hor, ver;
freq_div#(21) M1 (clk, rst, clk_shift);
freq_div#(12) M2 (clk, rst, clk_scan);
freq_div#(8) M3 (clk, rst, clk_out);
key_decode 	M4 (sel, column, press, scan_code);
key_buff 	M5 (clk_out, rst, press_valid, scan_code, keycode);
valid		M6 (clk_out, rst, press, press_valid);
count6  	M7 (clk_out, rst, sel);
idx_gen	M8 (clk_shift, rst, coll, idx);
row_gen	M9 (clk_scan, rst, idx, row, idx_cnt);
move		M10 (rst, coll, keycode, ver, hor, clk_out);
map	M11 (idx_cnt, column_green);
mix	M12 (ver, hor, row, column_red);
collision 	M13 (clk_out, rst, column_red, column_green, coll);
endmodule


module 	shift_hor(left, right, reset, unable, out, clk);
input 		left, right, reset, clk, unable;
output reg	[7:0]out;

always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b0000_1000;
	else if(unable) 		//碰撞狀態
 		out<=8'b0000_0000;
 	else if(left)
		out<={out[6:0],out[7]};
	else if(right)
		out<={out[0],out[7:1]};
 	else
  		out<=out;
end
endmodule

module 	shift_ver(up, down, reset, unable, out, clk);
input 		up, down, reset, clk, unable;
output reg	[7:0]out;

always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b0000_0001;
	else if(unable) 		//碰撞狀態
 		out<=8'b0000_0000;
 	else if(up)
		out<={out[6:0],out[7]};
	else if(down)
		out<={out[0],out[7:1]};
 	else
  		out<=out;
end
endmodule

module	move(reset, unable, keycode, ver, hor, clk);
input 		reset, clk, unable;
input 		[3:0]keycode;
output 	[7:0]ver, hor;
wire		left, right, up, down;

assign 	left  = ~keycode[1]&  keycode[2];
assign 	right =  keycode[1]&  keycode[2];
assign 	up    =  keycode[1]& ~keycode[2];
assign	down=  keycode[3];

shift_hor S1(left, right, reset, unable, hor, clk); //left & right
shift_ver S2(up, down, reset, unable, ver, clk); //up & down

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

module map(addr, data);
input[6:0]addr;
output[7:0]data;
reg[7:0]data;
always@(addr) begin
case(addr)
7'd0: data = 8'h00; 		7'd1: data = 8'h00; // Blank
7'd2: data = 8'h00; 		7'd3: data = 8'h00;
7'd4: data = 8'h00; 		7'd5: data = 8'h00;
7'd6: data = 8'h00; 		7'd7: data = 8'h00;
7'd8: data = 8'b11000011; 		7'd9: data = 8'b11000011;
7'd10: data = 8'b11000011; 	7'd11: data = 8'b11000011;
7'd12: data = 8'b11000011;		7'd13: data = 8'b11000011;
7'd14: data = 8'b11000011;		7'd15: data = 8'b11111111;
7'd16: data = 8'b11000011;		7'd17: data = 8'b10000111;
7'd18: data = 8'b11000111;		7'd19: data = 8'b11100111;
7'd20: data = 8'b11100111;		7'd21: data = 8'b11000111;
7'd22: data = 8'b11000011;		7'd23: data = 8'b11000011;
7'd24: data = 8'b11000011;		7'd25: data = 8'b10000111;
7'd26: data = 8'b10001111;		7'd27: data = 8'b11000111;
7'd28: data = 8'b11100011;		7'd29: data = 8'b11110011;
7'd30: data = 8'b11000011;		7'd31: data = 8'b10000011;
7'd32: data = 8'b10000111;		7'd33: data = 8'b10001111;
7'd34: data = 8'b11000111;		7'd35: data = 8'b11000011;
7'd36: data = 8'b11100011;		7'd37: data = 8'b11000011;
7'd38: data = 8'b10000111;		7'd39: data = 8'b10001111;
7'd40: data = 8'b10000111;		7'd41: data = 8'b10000011;
7'd42: data = 8'b10000001;		7'd43: data = 8'b11100001;
7'd44: data = 8'b11110001;		7'd45: data = 8'b11100011;
7'd46: data = 8'b11000011;		7'd47: data = 8'b11000011;
7'd48: data = 8'b00000000;		7'd49: data = 8'b00000000;
7'd50: data = 8'b00000000;		7'd51: data = 8'b00000000;
7'd52: data = 8'b00000000;		7'd53: data = 8'b00000000;
7'd54: data = 8'b00000000;		7'd55: data = 8'b00000000;
7'd56: data = 8'b00111100;		7'd57: data = 8'b01000010; //finish
7'd58: data = 8'b10100101;		7'd59: data = 8'b10000001;
7'd60: data = 8'b10100101;		7'd61: data = 8'b10011001;
7'd62: data = 8'b01000010;		7'd63: data = 8'b00111100;
7'd64: data = 8'b11111111;		7'd65: data = 8'b11111111;	//fail
7'd66: data = 8'b11111111;		7'd67: data = 8'b11111111;
7'd68: data = 8'b11111111;		7'd69: data = 8'b11111111;
7'd70: data = 8'b11111111;		7'd71: data = 8'b11111111;
endcase
end
endmodule

module idx_gen(clk, rst, coll, idx);
input clk, rst, coll;
output[6:0] idx;
reg[6:0]idx;
always@(posedge clk or posedge rst) begin
if(rst)
idx= 7'd40;
else if(idx==0 && coll==1'b0)
idx= 7'd64;
else if(idx>=16 && coll==1'b1)
idx= 7'd64;
else if(idx<16 && coll==1'b1)
idx= 7'd56;
else
idx=idx-7'd1;
end
endmodule

module row_gen(clk, rst, idx, row, idx_cnt);
input clk, rst;
input[6:0]idx;
output[7:0] row;
output[6:0]idx_cnt;
reg[7:0] row;
reg[6:0]idx_cnt;
reg[2:0]cnt;
always@(posedge clk or posedge rst) begin
if(rst) begin
row <= 8'b0000_0001;
cnt <= 3'd0;
idx_cnt <= 6'd0;
end
else begin
row <= {row[0],row[7:1]};//(輪流將每一列LED致能)
cnt <= cnt + 3'd1	;//(從0數到7) 
idx_cnt <= idx + cnt	;//(將初始位置加0到7)
end
end
endmodule	

module sel_color(idx, clk, column_out, sel);
input clk;
input [6:0]idx;
output [7:0]column_out;
output [1:0]sel;
wire [6:0]idx;
reg [7:0]column_out;
reg [1:0]sel;
always@ (posedge clk) begin
if(idx==7'd8) begin
sel <= 2'b10;
column_out <=8'b011111110;
end
end
endmodule

module 	mix(ver, hor, row, red);
input		[7:0]ver, hor, row;
output 	[7:0]red;

assign 	red=(row==ver)?hor : 8'b00000000;

endmodule

module  	collision(clk, reset, red, green, coll);
input		clk, reset;
input		[7:0]red, green;
output reg 	coll;
always@(posedge clk or posedge reset)
begin
	if(reset)
		coll<=1'b0;
	else if((red & green) != 8'b0)    //發生碰撞
		coll<=1'b1;
	else
		coll<=coll;
end
endmodule

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

3'b101: begin scan_code= 4'b0010; press = 1'b1; end // 2

default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b001:
case(column)
3'b011: begin scan_code= 4'b0100; press = 1'b1; end // 4

3'b110: begin scan_code= 4'b0110; press = 1'b1; end // 6
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b010:
case(column)

3'b101: begin scan_code= 4'b1000; press = 1'b1; end // 8

default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
3'b011:
case(column)
3'b101: begin scan_code= 4'b0000; press = 1'b1; end // 0
default: begin scan_code= 4'b1111; press = 1'b0; end
endcase
default:
begin scan_code= 4'b1111; press = 1'b0; end
endcase
end
endmodule


module key_buff(clk, rst, press_valid, scan_code, keycode);
input clk, rst, press_valid;
input[3:0] scan_code;
output[3:0]keycode;
reg[3:0]keycode;
always@(posedge clk or posedge rst) begin
if(rst)
keycode= 4'b0;// initial value
else
keycode= press_valid? scan_code: 4'b0;
end
endmodule

module valid (clk, rst, press, press_valid);
localparam count_bit=6;//此變數需與鍵盤使用的count數匹配
input press, clk, rst;
output press_valid;
reg [count_bit-1:0] gg;      //(幾Bit取決於致能count數，由於七段顯示器使用到count6而不是count4為了重複利用count訊號因此設6bit)
assign press_valid = ~(gg[count_bit-1] || (~press));
always@(posedge clk or posedge rst)
begin
if(rst)
    gg <= 6'b0;
else
    gg <= {gg[count_bit-2:0], press};
end
endmodule

module count6(clk, reset, count_out);
input clk, reset;
output[2:0] count_out;
reg[2:0] count_out;
always@ (posedge clk or posedge reset)begin
if(reset)
count_out= 3'b0;
else begin
if(count_out== 3'b101)
count_out <= 3'b000; //count_out back to 0
else
count_out <= count_out + 3'b001; //count_out add 1
end
end
endmodule
