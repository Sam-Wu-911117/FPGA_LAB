//碰撞小紅點
module 	LAB_08(clk, row, red, green, column, sel, reset);

input 		reset, clk;  // pin C16,W16(10MHz)   		
input 		[2:0]column;	//AA13,AB12,Y16	
output	[7:0]red, row, green;	
		// red:D7,D6,A9,C9,A8,C8,C11,B11
		//row:T22,R21,C6,B6,B5,A5,B7,A7
		//green:A10,B10,A13,A12,B12,D12,A15,A14
output 	[2:0]sel;		//AB10,AB11,AA12	
wire 		ck, press, press_vaild, coll;
wire 		[3:0]keycode, scancode, addr;
wire		[2:0]idx;
wire		[7:0]hor, ver;
assign 	addr = { coll, idx };
key_decode 	M1 (sel, column, press, scancode);
key_buf 	M2 (ck, reset, press_valid, scancode, keycode);
vaild		M3 (ck, reset, press, press_valid);
count6  	M4 (ck, reset, sel);
move		M5 (reset, coll, keycode, ver, hor, ck);
 	
freq_div#(14) 	M6 (clk, reset, ck);

map		M7 (addr,green);
idx		M8 (ck, reset, idx, row);
mix		M9 (ver, hor, row, red);
collision 	M10 (ck, reset, red, green, coll);
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

module 	mix(ver, hor, row, red);
input		[7:0]ver, hor, row;
output 	[7:0]red;
assign 	red= (ver==row)?hor:8'b0;
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
	4'd7  	:data= 8'b0000_1111;

	
	
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


module	move(reset, unable, keycode, ver, hor, clk);
input 		reset, clk, unable;
input 		[3:0]keycode;
output 	[7:0]ver, hor;
wire		left, right, up, down;

assign 	left  = ~keycode[1]&  keycode[2];
assign 	right =  keycode[1]&  keycode[2];
assign 	up    =  keycode[1]& ~keycode[2];
assign	down  =  keycode[3];

shift S1(left, right, reset, unable, hor, clk); //left & right
shift S2(up, down, reset, unable, ver, clk); //up & down

endmodule


module 	shift(left, right, reset, unable, out, clk);
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
				//3'b011: begin scan_code = 4'b0001; press = 1'b1;end   // 1
				3'b101: begin scan_code = 4'b0010; press = 1'b1;end   // 2
				//3'b110: begin scan_code = 4'b0011; press = 1'b1;end   // 3
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		3'b001:
			case(column)
				3'b011: begin scan_code = 4'b0100; press = 1'b1;end   // 4
				//3'b101: begin scan_code = 4'b0101; press = 1'b1;end   // 5
				3'b110: begin scan_code = 4'b0110; press = 1'b1;end   // 6
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase 
		3'b010:
			case(column)
				//3'b011: begin scan_code = 4'b0111; press = 1'b1;end   // 7
				3'b101: begin scan_code = 4'b1000; press = 1'b1;end   // 8
				//3'b110: begin scan_code = 4'b1001; press = 1'b1;end   // 9
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
