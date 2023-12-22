//碰撞小紅點
module final(clk, row, red1,red2, green1, green2, column, 
sel, reset, seg7_out,enable);

input 	reset, clk,enable;  // pin C16,W16(10MHz),AA15   		
input 	[2:0]column;	//AA13,AB12,Y16	
output	[7:0] row;
output 	[7:4]green1;
output  [3:0]green2;
output 	[7:4]red1;
output  [3:0]red2;
		// red1:D7,D6,A9,C9
		// red2:A8,C8,C11,B11
		//row:T22,R21,C6,B6,B5,A5,B7,A7
		//green1:A10,B10,A13,A12
		//green2:B12,D12,A15,A14
output 	[2:0]sel;		//AB10,AB11,AA12	
output  [6:0] seg7_out; // pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
wire 		ck, press, press_vaild, coll1, coll2,clk_shift,clk_scan;
wire	[3:0]keycode, scancode, addr1, addr2;
//wire	[2:0]idx;
wire    [6:0]idx,idx_cnt;
wire	[7:0]hor1, ver1, hor2, ver2;
wire[3:0] count_out, count5, count4, count3, count2, count1, count0;
//assign 	addr1 = { coll1, idx };
//assign 	addr2 = { coll2, idx };
key_decode 	M1 (sel, column, press, scancode);
key_buf 	M2 (ck, reset, press_valid, scancode, keycode);
vaild		M3 (ck, reset, press, press_valid);
count6  	M4 (ck, reset, sel);

move1		M5 (reset, coll1, keycode, ver1, hor1, ck);
move2		M6 (reset, coll2, keycode, ver2, hor2, ck);
 	
freq_div#(14) M7 (clk, reset, ck);
freq_div#(22) M8 (clk, reset, clk_shift);
freq_div#(12) M9 (clk, reset, clk_scan);
freq_div #(15) (clk,reset,clk_sel);
//rom_char1		M7 (idx_cnt,green1);
//rom_char2		M77 (idx_cnt,green2);
idx_gen  M10(clk_shift, reset, idx); 
row_gen  M11(clk_scan, reset, idx, row, idx_cnt);

//idx		M8 (ck, reset, idx, row);

mix1		M12 (ver1, hor1, row, red1);
mix2		M13(ver2, hor2, row, red2);
collision1 	M14 (ck, reset, red1, green1, coll1);
collision2 	M15 (ck, reset, red2, green2, coll2);

map1 M16 (idx_cnt,green1);
map2 M17 (idx_cnt,green2);

bcd_to_seg7(count_out,seg7_out);
seg7_select #(6) (clk_sel, reset, seg7_sel);
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

module 	mix1(ver, hor, row, red1);
input		[7:4]ver, hor, row;
output 	[7:4]red1;
assign 	red1= (ver==row)?hor:8'b0;
endmodule

module 	mix2(ver, hor, row, red2);
input		[3:0]ver, hor, row;
output 	[3:0]red2;
assign 	red2= (ver==row)?hor:8'b0;
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

/*
module map(addr,data);
input		[3:0]addr;
output reg 	[7:0]data;
always@(addr)
begin
case(addr)

	
	4'd0  	:data= 8'b0111_1111;           //請自行設計地圖
	4'd1  	:data= 8'b0001_1111;
	4'd2  	:data= 8'b1101_1111;
	4'd3  	:data= 8'b0001_0100;
	4'd4  	:data= 8'b0111_0101;
	4'd5  	:data= 8'b0110_0001;
	4'd6  	:data= 8'b0110_1111;
	4'd7  	:data= 8'b0100_1000;
	
	 
	4'd0  	:data= 8'b0000_0000;           //請自行設計地圖
	4'd1  	:data= 8'b0000_0000;
	4'd2  	:data= 8'b0000_0000;
	4'd3  	:data= 8'b0000_0000;
	4'd4  	:data= 8'b0000_0000;
	4'd5  	:data= 8'b0000_0000;
	4'd6  	:data= 8'b0000_0000;
	4'd7  	:data= 8'b1000_0100;
	
	
	4'd8  :data=8'b1111_1111;
	4'd9  :data=8'b1111_1111;
	4'd10	:data=8'b1111_1111;
	4'd11	:data=8'b1111_1111;
	4'd12	:data=8'b1111_1111;
	4'd13	:data=8'b1111_1111;
	4'd14	:data=8'b1111_1111;
	4'd15	:data=8'b1111_1111;
	default	:data=8'b0000_0000;
endcase
end
endmodule
*/

module	move1(reset, unable, keycode, ver, hor, clk);
input 		reset, clk, unable;
input 		[3:0]keycode;
output 	[7:0]ver, hor;
wire		left, right, up, down;
assign 	left  =  ~keycode[3]&  ~keycode[2]& ~keycode[1]&  keycode[0] ;//press_1
assign 	right = ~keycode[3]&  ~keycode[2]& keycode[1]&  ~keycode[0] ;//press_2
//assign 	up    =  keycode[1]& ~keycode[2];
//assign	   down  =  keycode[3];
shift1 S1(left, right, reset, unable, hor, clk); //left & right
shift2 S2(up, down, reset, unable, ver, clk); //up & down
endmodule



module	move2(reset, unable, keycode, ver, hor, clk);
input 		reset, clk, unable;
input 		[3:0]keycode;
output 	[7:0]ver, hor;
wire		left, right, up, down;
assign 	left  = keycode[3]&  ~keycode[2]& ~keycode[1]&  ~keycode[0] ;//press_3
assign 	right = keycode[3]&  ~keycode[2]& ~keycode[1]&   keycode[0] ;////press_4
//assign 	up    =  keycode[1]& ~keycode[2];
//assign		down  =  keycode[3];
shift1 S1(left, right, reset, unable, hor, clk); //left & right
shift2 S2(up, down, reset, unable, ver, clk); //up & down
endmodule




module 	shift1(left, right, reset, unable, out, clk);
input 		left, right, reset, clk, unable;
output reg	[7:4]out;
always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b0001;//col_control_bit
	else if(unable) 		//碰撞狀態
 		out<=8'b0000;
 	else if(left)
		out<={out[6:4],out[7]};
	else if(right)
		out<={out[4],out[7:5]};
 	else
  		out<=out;
end
endmodule

module 	shift2(left, right, reset, unable, out, clk);
input 		left, right, reset, clk, unable;
output reg	[3:0]out;
always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b0001;//row_control_bit
	else if(unable) 		//碰撞狀態
 		out<=8'b0000;
 	else if(left)
		out<={out[2:0],out[3]};
	else if(right)
		out<={out[0],out[3:1]};
 	else
  		out<=out;
end
endmodule




module  	collision1(clk, reset, red, green, coll);
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

module  	collision2(clk, reset, red, green, coll);
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

module count6(clk, reset, sel);  //依序掃描七段顯示器
input 	clk, reset;
output 	[2:0]sel;
reg 		[2:0]sel;
always@(posedge clk or posedge reset)begin
	if(reset) begin
		sel <= 3'b0;
	end
	else if(sel == 3'b101) begin
		sel <= 3'b0;
	end
	else begin
		sel <= sel + 1;
	end
end
endmodule

module vaild (clk, rst, press, press_valid);  //用來防止手動按鍵盤有多次輸入
input		press, clk, rst;
output 	press_valid;
reg 		[5:0]gg;  //幾Bit取決於致能count數，由於七段顯示器需用到count6為了重複利用count訊號因此直接設6bit
assign press_valid = ~(gg[5] || (~press));
always@(posedge clk or posedge rst)begin
	if(rst)
		gg <= 6'b0;
	else
		gg <= {gg[4:0], press};
	end
endmodule

module key_buf(clk, rst, press_valid, scan_code, display_code);  //左移存入數字
input 	clk, rst, press_valid;
input 	[3:0]scan_code;
output 	[3:0]display_code;
reg 		[3:0]display_code;
always@(posedge clk or posedge rst)begin
	if(rst)
		display_code = 4'b0000;  //initial value
	else
		display_code = press_valid ?  scan_code : 4'b0000;  //{Left_shift_value} : Previous_ value;
end
endmodule

module key_decode(sel, column, press, scan_code);
input		[2:0]sel;		//選第幾列
input		[2:0]column;	//選第幾行
output 	press;
output	[3:0]scan_code;
reg		[3:0]scan_code;
reg 		press;

always@(sel or column)begin
	case(sel)
		3'b000:
			case(column)
				3'b011: begin scan_code = 4'b0001; press = 1'b1;end   // 1
				3'b101: begin scan_code = 4'b0010; press = 1'b1;end   // 2
				//3'b110: begin scan_code = 4'b0011; press = 1'b1;end   // 3
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		3'b001:
			case(column)
				//3'b011: begin scan_code = 4'b0100; press = 1'b1;end   // 4
				//3'b101: begin scan_code = 4'b0101; press = 1'b1;end   // 5
				//3'b110: begin scan_code = 4'b0110; press = 1'b1;end   // 6
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase 
		3'b010:
			case(column)
				//3'b011: begin scan_code = 4'b0111; press = 1'b1;end   // 7
				3'b101: begin scan_code = 4'b1000; press = 1'b1;end   // 8
				3'b110: begin scan_code = 4'b1001; press = 1'b1;end   // 9
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		3'b011:
			case(column)
				3'b101: begin scan_code = 4'b0000; press = 1'b1;end   // 0
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		default:begin
			scan_code = 4'b1111; press = 1'b0;end
	endcase
end
endmodule


module map1(addr, data);
input[6:0]addr;
output[7:0]data;
reg[7:0]data;
always@(addr) begin
case(addr)
7'd0: data = 8'h08; 7'd1: data = 8'h04; // Blank
7'd2: data = 8'h04; 7'd3: data = 8'h02;
7'd4: data = 8'h02; 7'd5: data = 8'h01;
7'd6: data = 8'h00; 7'd7: data = 8'h00;
7'd8: data = 8'h00; 7'd9: data = 8'h00; // 0

7'd10: data = 8'h08; 7'd11: data = 8'h04;
7'd12: data = 8'h04;	7'd13: data = 8'h08;
7'd14: data = 8'h02;	7'd15: data = 8'h01;
7'd16: data = 8'h01;	7'd17: data = 8'h02;// 1
7'd18: data = 8'h02;	7'd19: data = 8'h08;

7'd20: data = 8'h00;	7'd21: data = 8'h00;
7'd22: data = 8'h00;	7'd23: data = 8'h00;
7'd24: data = 8'h08;	7'd25: data = 8'h02;// 2
7'd26: data = 8'h02;	7'd27: data = 8'h04;
7'd28: data = 8'h00;	7'd29: data = 8'h00;

7'd30: data = 8'h00;	7'd31: data = 8'h00;
7'd32: data = 8'h04; 7'd33: data = 8'h02;// 3
7'd34: data = 8'h02;	7'd35: data = 8'h04;
7'd36: data = 8'h02;	7'd37: data = 8'h02;
7'd38: data = 8'h00;	7'd39: data = 8'h00;
7'd40: data = 8'h08; 7'd41: data = 8'h04;// 4
7'd42: data = 8'h04;	7'd43: data = 8'h04;
7'd44: data = 8'h02;	7'd45: data = 8'h08;
7'd46: data = 8'h04;	7'd47: data = 8'h00;
7'd48: data = 8'h01;	7'd49: data = 8'h00;//5
7'd50: data = 8'h00;	7'd51: data = 8'h08;
7'd52: data = 8'h02;	7'd53: data = 8'h02;
7'd54: data = 8'h00;	7'd55: data = 8'h00;

7'd56: data = 8'h00;	7'd57: data = 8'h00;  //6
7'd58: data = 8'h01;	7'd59: data = 8'h04;
7'd60: data = 8'h02;	7'd61: data = 8'h02;
7'd62: data = 8'h04;	7'd63: data = 8'h00;

7'd64: data = 8'h08;	7'd65: data = 8'h02;  //7
7'd66: data = 8'h02;	7'd67: data = 8'h02;
7'd68: data = 8'h02; 7'd69: data = 8'h02;
7'd70: data = 8'h00;	7'd71: data = 8'h00;

7'd72: data = 8'h01;	7'd73: data = 8'h02;  //8
7'd74: data = 8'h02;	7'd75: data = 8'h0C;
7'd76: data = 8'h02;	7'd77: data = 8'h02;
7'd78: data = 8'h00;	7'd79: data = 8'h00;

7'd80: data = 8'h04;	7'd81: data = 8'h02;  //9
7'd82: data = 8'h02;	7'd83: data = 8'h08;
7'd84: data = 8'h02; 7'd85: data = 8'h02 ;
7'd86: data = 8'h00;	7'd87: data = 8'h00;

endcase
end
endmodule

module map2(addr, data);
input[6:0]addr;
output[7:0]data;
reg[7:0]data;
always@(addr) begin
case(addr)
7'd0: data = 8'h09; 7'd1: data = 8'h05; // Blank
7'd2: data = 8'h01; 7'd3: data = 8'h02;
7'd4: data = 8'h08; 7'd5: data = 8'h04;
7'd6: data = 8'h03; 7'd7: data = 8'h0A;
7'd8: data = 8'h36; 7'd9: data = 8'h43; // 0

7'd10: data = 8'h49; 7'd11: data = 8'h45;
7'd12: data = 8'h01;	7'd13: data = 8'h62;
7'd14: data = 8'h38;	7'd15: data = 8'h04;
7'd16: data = 8'h03;	7'd17: data = 8'h1A;// 1
7'd18: data = 8'h06;	7'd19: data = 8'h03;

7'd20: data = 8'h09;	7'd21: data = 8'h05;
7'd22: data = 8'h11;	7'd23: data = 8'h02;
7'd24: data = 8'h38;	7'd25: data = 8'h44;// 2
7'd26: data = 8'h43;	7'd27: data = 8'h02;
7'd28: data = 8'h06;	7'd29: data = 8'h13;

7'd30: data = 8'h7E;	7'd31: data = 8'h00;
7'd32: data = 8'h3C; 7'd33: data = 8'h42;// 3
7'd34: data = 8'h02;	7'd35: data = 8'h3C;
7'd36: data = 8'h02;	7'd37: data = 8'h42;
7'd38: data = 8'h3C;	7'd39: data = 8'h00;
7'd40: data = 8'h1C; 7'd41: data = 8'h24;// 4
7'd42: data = 8'h44;	7'd43: data = 8'h44;
7'd44: data = 8'h44;	7'd45: data = 8'h7E;
7'd46: data = 8'h04;	7'd47: data = 8'h00;
7'd48: data = 8'h7E;	7'd49: data = 8'h40;//5
7'd50: data = 8'h40;	7'd51: data = 8'h7C;
7'd52: data = 8'h02;	7'd53: data = 8'h42;
7'd54: data = 8'h3C;	7'd55: data = 8'h00;

7'd56: data = 8'h3C;	7'd57: data = 8'h40;  //6
7'd58: data = 8'h40;	7'd59: data = 8'h7C;
7'd60: data = 8'h42;	7'd61: data = 8'h42;
7'd62: data = 8'h3C;	7'd63: data = 8'h00;

7'd64: data = 8'h3C;	7'd65: data = 8'h42;  //7
7'd66: data = 8'h42;	7'd67: data = 8'h42;
7'd68: data = 8'h2 ;	7'd69: data = 8'h2;
7'd70: data = 8'h2 ;	7'd71: data = 8'h00;

7'd72: data = 8'h3C;	7'd73: data = 8'h42;  //8
7'd74: data = 8'h42;	7'd75: data = 8'h3C;
7'd76: data = 8'h42;	7'd77: data = 8'h42;
7'd78: data = 8'h3C;	7'd79: data = 8'h00;

7'd80: data = 8'h3C;	7'd81: data = 8'h42;  //9
7'd82: data = 8'h42;	7'd83: data = 8'h3E;
7'd84: data = 8'h2 ;	7'd85: data = 8'h2 ;
7'd86: data = 8'h3C;	7'd87: data = 8'h00;
endcase
end
endmodule


module idx_gen(clk, rst, idx);
input clk, rst;
output[6:0] idx;
reg[6:0]idx;
always@(posedge clk or posedge rst)begin  //加分題
    if(rst)
        idx = 7'd80;
    else if(idx == 7'd0)
        idx = 7'd80;
    else
        idx = idx - 7'd01;  //idx = idx + 7'b01 下往上
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
idx_cnt <= 7'd0;
end
else begin
row <= {row[0], row[7:1]};  //輪流將每一列LED致能
cnt <= cnt + 1'b1;          //從0數到7 
idx_cnt <= idx + cnt;       //將初始位置加0到7
end
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