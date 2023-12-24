module final(clk, reset, enable, column, column_red, column_green, row, seg7_sel, seg7_out, light_led, led_com);
input 	clk, reset;  	//pin W16, C16
input		[2:0]column; 	//AA13,AB12,Y16
input		enable;			//AA15
output	[7:0]row, column_green, column_red;
//row:				pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
//column_red:		pin D7, D6, A9, C9, A8, C8, C11, B11
//column_green:	pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
output	[2:0]seg7_sel;			//pin AB10, AB11, AA12 
output	[6:0]seg7_out;			//pin AB7, AA7, AB6, AB5, AA9, Y9, AB8 
wire	 	carry;
wire		[7:0]column_out1;
wire		[7:0]column_out2;
wire		[7:0]idx, idx2, idx_cnt, idx2_cnt;
wire 		clk_sel;
wire		clk_prng;
wire		[3:0]key_out;

//--鍵盤輸入--//
wire 		press,press_valid;
wire		[3:0]scan_code, key_code2;
count6		 (clk_sel, reset, seg7_sel);
key_decode	 (seg7_sel, column, press, scan_code);
debounce_ctl (clk_sel, reset, press, press_valid);
key_buf		 (clk_sel, reset, press_valid, scan_code, key_out);
//--
assign column_green = column_out1;
assign column_red = column_out2;
freq_div#(13) 	(clk, reset, clk_sel);
freq_div#(23)  (clk, reset, clk_shift);
freq_div#(12)  (clk, reset, clk_score);
//--
wire				coll;
idx_gen 			(key_out, idx);
row_gen 			(clk_sel, reset, idx, row, idx_cnt);
idx_gen2			(clk_shift, enable, reset, idx2);
row_gen2			(clk_sel, reset, idx2, idx2_cnt);
rom_char 		(finish, idx_cnt, column_out1);
rom_char2 		(finish, idx2_cnt, column_out2);
hit				(clk, reset, column_out2, column_out1, coll);
//--
wire		finish;
wire 		clk_count;
wire		[3:0]count_out, count1, count0;

assign count_out = (seg7_sel == 3'b101) ? count0 :
						(seg7_sel == 3'b100) ? count1 :
						(seg7_sel == 3'b011) ? score0 :
						(seg7_sel == 3'b010) ? score1 :
						(seg7_sel == 3'b001) ? score2 : score3;						
hrcount				(clk, reset, clk_count); 
count_20_00_bcd	(clk_count, reset, enable, count1, count0, finish);
bcd_to_seg7			(count_out, seg7_out);
//--------------------
output [11:0]light_led; //pin E2, D3, C2, C1, L2, L1, G2, G1, U2, N1, AA2, AA1
output led_com; //pin N20
wire 		[3:0]score0, score1;
count_score(clk_score, coll, reset, score0, score1, score2, score3);
endmodule

///
module freq_div (clk_in, reset, clk_out);
parameter 	exp = 20;
input 		clk_in, reset;
output 		clk_out;
reg			[exp - 1 : 0]divider;
integer 		i;

assign clk_out = divider[exp - 1];
always@(posedge clk_in or posedge reset)begin //正緣觸發
	if(reset)
		for(i = 0; i < exp; i = i + 1)
			divider[i] = 1'b0;
	else
		divider = divider + 1'b1;
end
endmodule


///
module key_decode(sel, column, press, scan_code);
input		[2:0]sel;
input		[2:0]column;
output 	press;
output	[3:0]scan_code;
reg		[3:0]scan_code;
reg 		press;

always@(*)begin
	case(sel)
		3'b000:
			case(column)
				3'b011: begin scan_code = 4'b0001; press = 1'b1; end // 1
				3'b101: begin scan_code = 4'b0010; press = 1'b1; end // 2
				3'b110: begin scan_code = 4'b0011; press = 1'b1; end // 3
				default: begin scan_code = 4'b1111; press = 1'b0; end
			endcase
		3'b001:
			case(column)
				3'b011: begin scan_code = 4'b0100; press = 1'b1; end // 4
				3'b101: begin scan_code = 4'b0101; press = 1'b1; end // 5
				3'b110: begin scan_code = 4'b0110; press = 1'b1; end // 6
				default: begin scan_code = 4'b1111; press = 1'b0; end
			endcase
		3'b010:
			case(column)
				3'b011: begin scan_code = 4'b0111; press = 1'b1; end // 7
				3'b101: begin scan_code = 4'b1000; press = 1'b1; end // 8
				3'b110: begin scan_code = 4'b1001; press = 1'b1; end // 9
				default: begin scan_code = 4'b1111; press = 1'b0; end
			endcase
		default:begin 
			scan_code = 4'b1111; press = 1'b0;end
	endcase
end
endmodule


///
module debounce_ctl (clk, rst, press, press_valid);
input 	press,clk,rst;
output 	press_valid;
reg		[5:0]gg;

assign press_valid = ~(gg[5] || (~press));
always@(posedge clk or posedge rst)begin
	if(rst)
		gg <= 6'b0;
	else
		gg <= {gg[4:0], press};
	end
endmodule


///
module key_buf(clk, rst, press_valid, scan_code, key_out);
input 	clk, rst, press_valid;
input		[3:0]scan_code;
output	[3:0]key_out;
reg		[3:0]key_out;

always@(posedge clk or posedge rst) begin
	if(rst)
		key_out = 4'b0000;  //initial value
	else
		key_out = press_valid ? scan_code:key_out ;
	end
endmodule


///
module count6(clk,rst,sel);
input 	clk,rst;
output 	[2:0]sel;
reg		[2:0]sel;

always@(posedge clk or posedge rst)begin
	if(rst)
		sel = 3'b000;
	else begin
		if(sel == 3'b101)
			sel = 3'b0;
		else
			sel = sel + 3'b001;
	end
end
endmodule


///
module rom_char(finish, addr, data);
input		[7:0]addr;
input 	finish;
output	[7:0]data;
reg		[7:0]data;

always@(*)begin
	if(finish==1'b0)begin
		case(addr)
			8'd0 : data = 8'b00000000;
			8'd1 : data = 8'b00000000;  //Blank
			8'd2 : data = 8'b00000000; 
			8'd3 : data = 8'b00000000;
			8'd4 : data = 8'b00000000; 
			8'd5 : data = 8'b00000000;
			8'd6 : data = 8'b00000000; 
			8'd7 : data = 8'b00000000;

			8'd8 : data = 8'b00000000; 
			8'd9 : data = 8'b00000000;  //0
			8'd10: data = 8'b00000000; 
			8'd11: data = 8'b00000000;
			8'd12: data = 8'b00000000; 
			8'd13: data = 8'b00000000;
			8'd14: data = 8'b00000000; 
			8'd15: data = 8'b00000000; 
			
			8'd16: data = 8'b11000000; 
			8'd17: data = 8'b11000000;  //1
			8'd18: data = 8'b00000000; 
			8'd19: data = 8'b00000000;
			8'd20: data = 8'b00000000; 
			8'd21: data = 8'b00000000;
			8'd22: data = 8'b00000000; 
			8'd23: data = 8'b00000000;

			8'd24: data = 8'b00011000; 
			8'd25: data = 8'b00011000;  //2
			8'd26: data = 8'b00000000; 
			8'd27: data = 8'b00000000;
			8'd28: data = 8'b00000000; 
			8'd29: data = 8'b00000000;
			8'd30: data = 8'b00000000; 
			8'd31: data = 8'b00000000;

			8'd32: data = 8'b00000011; 
			8'd33: data = 8'b00000011;  //3
			8'd34: data = 8'b00000000; 
			8'd35: data = 8'b00000000;
			8'd36: data = 8'b00000000; 
			8'd37: data = 8'b00000000;
			8'd38: data = 8'b00000000; 
			8'd39: data = 8'b00000000;

			8'd40: data = 8'b00000000; 
			8'd41: data = 8'b00000000;  //4
			8'd42: data = 8'b00000000; 
			8'd43: data = 8'b11000000;
			8'd44: data = 8'b11000000; 
			8'd45: data = 8'b00000000;
			8'd46: data = 8'b00000000; 
			8'd47: data = 8'b00000000;

			8'd48: data = 8'b00000000; 
			8'd49: data = 8'b00000000;  //5
			8'd50: data = 8'b00000000; 
			8'd51: data = 8'b00011000;
			8'd52: data = 8'b00011000; 
			8'd53: data = 8'b00000000;
			8'd54: data = 8'b00000000; 
			8'd55: data = 8'b00000000;

			8'd56: data = 8'b00000000; 
			8'd57: data = 8'b00000000;  //6
			8'd58: data = 8'b00000000; 
			8'd59: data = 8'b00000011;
			8'd60: data = 8'b00000011; 
			8'd61: data = 8'b00000000;
			8'd62: data = 8'b00000000; 
			8'd63: data = 8'b00000000;

			8'd64: data = 8'b00000000; 
			8'd65: data = 8'b00000000;  //7
			8'd66: data = 8'b00000000; 
			8'd67: data = 8'b00000000;
			8'd68: data = 8'b00000000; 
			8'd69: data = 8'b00000000;
			8'd70: data = 8'b11000000; 
			8'd71: data = 8'b11000000;

			8'd72: data = 8'b00000000; 
			8'd73: data = 8'b00000000;  //8
			8'd74: data = 8'b00000000; 
			8'd75: data = 8'b00000000;
			8'd76: data = 8'b00000000; 
			8'd77: data = 8'b00000000;
			8'd78: data = 8'b00011000; 
			8'd79: data = 8'b00011000;

			8'd80: data = 8'b00000000; 
			8'd81: data = 8'b00000000;  //9
			8'd82: data = 8'b00000000; 
			8'd83: data = 8'b00000000;
			8'd84: data = 8'b00000000; 
			8'd85: data = 8'b00000000;
			8'd86: data = 8'b00000011; 
			8'd87: data = 8'b00000011;
			default : data = 8'b0;
		endcase
	end
	else
		data=8'b00000000;
end
endmodule

///
module idx_gen(scan_code ,idx);
input 	[3:0]scan_code;
output	[7:0]idx;
reg		[7:0]idx;

always@(*)begin		
		idx = scan_code * 8 + 8'd8;
end
endmodule


///
module row_gen(clk, rst, idx, row, idx_cnt);
input 	clk, rst;
input		[7:0]idx;
output	[7:0]row;
output	[7:0]idx_cnt;
reg		[7:0]row;
reg		[7:0]idx_cnt;
reg		[2:0]cnt;

always@(posedge clk or posedge rst)begin
	if(rst)begin
		row <= 8'b0000_0001;
		cnt <= 3'd0;
		idx_cnt <= 8'd0;
	end
	else begin
		row <= {row[0], row[7:1]}; 	//輪流將每一列LED致能
		cnt <= cnt + 3'd1; 			//從0數到7
		idx_cnt <= idx + cnt; 		//將初始位置加0到7
	end
end
endmodule


///
module idx_gen2(clk, enable, rst, idx);
input 	clk, rst, enable;
output 	[7:0]idx;
reg 		[7:0]idx;

always@(posedge clk or posedge rst)begin  
	if(rst)
		idx = 7'd0;
	else if(idx == 7'd120)
		idx = 7'd0;
	else if(enable == 1'b1)
		idx = idx + 7'd08;  //idx = idx + 7'b01 下往上
end
endmodule

///
module row_gen2(clk, rst, idx, idx_cnt);
input 	clk, rst;
input		[7:0]idx;
output	[7:0]idx_cnt;
reg		[7:0]idx_cnt;
reg		[2:0]cnt;

always@(posedge clk or posedge rst)begin
	if(rst)begin
		cnt <= 3'd0;
		idx_cnt <= 8'd0;
	end
	else begin
		cnt <= cnt + 3'd1; 			//從0數到7
		idx_cnt <= idx + cnt; 		//將初始位置加0到7
	end
end
endmodule


module rom_char2(finish, addr, data);
input		[7:0]addr;
input 	finish;
output	[7:0]data;
reg		[7:0]data;

always@(*)begin
	if(finish == 1'b0)begin
		case(addr)
			8'd0 : data = 8'b00100100;
			8'd1 : data = 8'b00100100;  //Blank
			8'd2 : data = 8'b11111111; 
			8'd3 : data = 8'b00100100;
			8'd4 : data = 8'b00100100; 
			8'd5 : data = 8'b11111111;
			8'd6 : data = 8'b00100100; 
			8'd7 : data = 8'b00100100;

			8'd8: data = 8'b00100100; 
			8'd9: data = 8'b00100100;  //5
			8'd10: data = 8'b11111111; 
			8'd11: data = 8'b00111100;
			8'd12: data = 8'b00111100; 
			8'd13: data = 8'b11111111;
			8'd14: data = 8'b00100100; 
			8'd15: data = 8'b00100100;
			  
			8'd16: data = 8'b00100100; 
			8'd17: data = 8'b00100100;  //8
			8'd18: data = 8'b11111111; 
			8'd19: data = 8'b00100100;
			8'd20: data = 8'b00100100; 
			8'd21: data = 8'b11111111;
			8'd22: data = 8'b00111100; 
			8'd23: data = 8'b00111100;

			8'd24: data = 8'b00100111; 
			8'd25: data = 8'b00100111;  //3
			8'd26: data = 8'b11111111; 
			8'd27: data = 8'b00100100;
			8'd28: data = 8'b00100100; 
			8'd29: data = 8'b11111111;
			8'd30: data = 8'b00100100; 
			8'd31: data = 8'b00100100;

			8'd32: data = 8'b00100100; 
			8'd33: data = 8'b00100100;  //9
			8'd34: data = 8'b11111111; 
			8'd35: data = 8'b00100100;
			8'd36: data = 8'b00100100; 
			8'd37: data = 8'b11111111;
			8'd38: data = 8'b00100111; 
			8'd39: data = 8'b00100111;

			8'd40: data = 8'b00111100; 
			8'd41: data = 8'b00111100;  //2
			8'd42: data = 8'b11111111; 
			8'd43: data = 8'b00100100;
			8'd44: data = 8'b00100100; 
			8'd45: data = 8'b11111111;
			8'd46: data = 8'b00100100; 
			8'd47: data = 8'b00100100;

			8'd48: data = 8'b11100100; 
			8'd49: data = 8'b11100100;  //1
			8'd50: data = 8'b11111111; 
			8'd51: data = 8'b00100100;
			8'd52: data = 8'b00100100; 
			8'd53: data = 8'b11111111;
			8'd54: data = 8'b00100100; 
			8'd55: data = 8'b00100100;

			8'd56: data = 8'b00100100; 
			8'd57: data = 8'b00100100;  //7
			8'd58: data = 8'b11111111; 
			8'd59: data = 8'b00100100;
			8'd60: data = 8'b00100100; 
			8'd61: data = 8'b11111111;
			8'd62: data = 8'b11100100; 
			8'd63: data = 8'b11100100;

			8'd64: data = 8'b00100100; 
			8'd65: data = 8'b00100100;  //4
			8'd66: data = 8'b11111111; 
			8'd67: data = 8'b11100100;
			8'd68: data = 8'b11100100; 
			8'd69: data = 8'b11111111;
			8'd70: data = 8'b00100100; 
			8'd71: data = 8'b00100100;
			
			8'd72: data = 8'b00100100; 
			8'd73: data = 8'b00100100;  //6
			8'd74: data = 8'b11111111; 
			8'd75: data = 8'b00100111;
			8'd76: data = 8'b00100111; 
			8'd77: data = 8'b11111111;
			8'd78: data = 8'b00100100; 
			8'd79: data = 8'b00100100;
			
			8'd80: data = 8'b00100111; 
			8'd81: data = 8'b00100111;  //3
			8'd82: data = 8'b11111111; 
			8'd83: data = 8'b00100100;
			8'd84: data = 8'b00100100; 
			8'd85: data = 8'b11111111;
			8'd86: data = 8'b00100100; 
			8'd87: data = 8'b00100100;
			
			8'd88: data = 8'b00100100; 
			8'd89: data = 8'b00100100;  //6
			8'd90: data = 8'b11111111; 
			8'd91: data = 8'b00100111;
			8'd92: data = 8'b00100111; 
			8'd93: data = 8'b11111111;
			8'd94: data = 8'b00100100; 
			8'd95: data = 8'b00100100;
			
			8'd96: data = 8'b00111100; 
			8'd97: data = 8'b00111100;  //2
			8'd98: data = 8'b11111111; 
			8'd99: data = 8'b00100100;
			8'd100: data = 8'b00100100; 
			8'd101: data = 8'b11111111;
			8'd102: data = 8'b00100100; 
			8'd103: data = 8'b00100100;
			
			8'd104: data = 8'b00100100; 
			8'd105: data = 8'b00100100;  //5
			8'd106: data = 8'b11111111; 
			8'd107: data = 8'b00111100;
			8'd108: data = 8'b00111100; 
			8'd109: data = 8'b11111111;
			8'd110: data = 8'b00100100; 
			8'd111: data = 8'b00100100;
			
			8'd112: data = 8'b00100100; 
			8'd113: data = 8'b00100100;  //7
			8'd114: data = 8'b11111111; 
			8'd115: data = 8'b00100100;
			8'd116: data = 8'b00100100; 
			8'd117: data = 8'b11111111;
			8'd118: data = 8'b11100100; 
			8'd119: data = 8'b11100100;
			
			8'd120: data = 8'b00100100; 
			8'd121: data = 8'b00100100;  //9
			8'd122: data = 8'b11111111; 
			8'd123: data = 8'b00100100;
			8'd124: data = 8'b00100100; 
			8'd125: data = 8'b11111111;
			8'd126: data = 8'b00100111; 
			8'd127: data = 8'b00100111;
			
			8'd128: data = 8'b11100100; 
			8'd129: data = 8'b11100100;  //1
			8'd130: data = 8'b11111111; 
			8'd131: data = 8'b00100100;
			8'd132: data = 8'b00100100; 
			8'd133: data = 8'b11111111;
			8'd134: data = 8'b00100100; 
			8'd135: data = 8'b00100100;
			
			8'd136: data = 8'b00100100; 
			8'd137: data = 8'b00100100;  //4
			8'd138: data = 8'b11111111; 
			8'd139: data = 8'b11100100;
			8'd140: data = 8'b11100100; 
			8'd141: data = 8'b11111111;
			8'd142: data = 8'b00100100; 
			8'd143: data = 8'b00100100;
			
			8'd144: data = 8'b00100100; 
			8'd145: data = 8'b00100100;  //8
			8'd146: data = 8'b11111111; 
			8'd147: data = 8'b00100100;
			8'd148: data = 8'b00100100; 
			8'd149: data = 8'b11111111;
			8'd150: data = 8'b00111100; 
			8'd151: data = 8'b00111100;
		endcase
	end
	else
		data = 8'b11111111;
end	
endmodule

module hit(clk, reset, red, green, coll);
input clk, reset;
input [7:0]red, green;
output reg coll;

always@(posedge clk or posedge reset)begin
	if(reset)
		coll <= 1'b0;
	else if((red & green) != 8'b0)begin
		coll = 1'b1;
	end
	else
		coll <= 1'b0;
end
endmodule

///
module hrcount(clk, reset, clk_out);
input 	clk,reset;
output 	clk_out;
reg 		[0:23]temp;

assign clk_out = (temp == 24'b100110001001011010000000) ? 1 : 0;
always@(posedge clk or posedge reset)begin
	if(reset)
		temp = 24'b0;
	else if (temp == 24'b100110001001011010000000)
		temp = 24'b0;
	else
		temp = temp + 1'b1;
end
endmodule

///
module count_20_00_bcd(clk, reset, enable, count1, count0, finish);
input 	clk, reset, enable;
output	[3:0] count1, count0;
output 	finish;
reg 		finish;
reg		[3:0] count1, count0;

always@(posedge clk or posedge reset)begin
	if(reset) begin
		count1 = 4'b0010;
		count0 = 4'b0000;
		finish = 1'b0;
	end
	else if(enable == 1'b1) begin
		if (count1 == 4'b0000 && count0 == 4'b0000) begin
			count1 = 4'b0000;
			count0 = 4'b0000;
			finish = 1'b1;
	end
	else if(count0 == 4'b0000) begin
		count0 = 4'b1001;
		count1 = count1 - 1'b1;
	end
	else
		count0 = count0 - 1'b1;
	end
end
endmodule


///
module bcd_to_seg7 (bcd_in, seg7);
input		[3:0]bcd_in;
output	[6:0]seg7;
reg		[6:0]seg7;

always@(bcd_in)
	case(bcd_in)
		4'b0000: seg7 = 7'b1111110;  //0
		4'b0001: seg7 = 7'b0110000;  //1
		4'b0010: seg7 = 7'b1101101;  //2
		4'b0011: seg7 = 7'b1111001;  //3
		4'b0100: seg7 = 7'b0110011;  //4
		4'b0101: seg7 = 7'b1011011;  //5
		4'b0110: seg7 = 7'b1011111;  //6
		4'b0111: seg7 = 7'b1110000;  //7
		4'b1000: seg7 = 7'b1111111;  //8
		4'b1001: seg7 = 7'b1111011;  //9
		default: seg7 = 7'b0000000; 
	endcase
endmodule


///
module seg7_select(clk, reset, seg7_sel);
parameter 	num_use = 6; //set parameter
input 		clk, reset;
output 		[2:0]seg7_sel;
reg 			[2:0]seg7_sel;

always@ (posedge clk or posedge reset) begin
	if(reset == 1)
		seg7_sel = 3'b101;  //the rightmost one
	else
		if(seg7_sel == 6 - num_use)
			seg7_sel=3'b101;
		else
			seg7_sel=seg7_sel - 3'b001;  //shift left
end
endmodule





///
module count_score(clk, coll, reset, score0, score1, score2, score3);
input		coll, reset, clk;
output 	[3:0]score0, score1, score2, score3;
reg		[3:0]score0, score1, score2, score3;

always@ (posedge clk or posedge reset)begin
	if(reset) begin
		score0 = 4'b0000;  //000
		score1 = 4'b0000;  //000
		score2 = 4'b0000;  //000
		score3 = 4'b0000;  //000
	end
	else if(coll == 1'b1) begin
		if (score3 == 4'b1001 && score2 == 4'b1001 && score1 == 4'b1001 && score0 == 4'b1001)begin  
			score0 = 4'b0000;  //000
			score1 = 4'b0000;  //000
			score2 = 4'b0000;  //000
			score3 = 4'b0000;  //000
		end
	else if(score0 == 4'b1001) begin
		score0 = 4'b0000;
		score1 = score1 + 4'b0001;
		if(score1 == 4'b1001 ) begin
			score0 = 4'b0000;
			score1 = 4'b0000;
			score2 = score2 + 4'b0001;
		end
	end
	else if(score1 == 4'b1001 && score0 == 4'b1001) begin
		score0 = 4'b0000;
		score1 = 4'b0000;
		score2 = score2 + 4'b0001;
	end
	else if(score2 == 4'b1001 && score1 == 4'b1001 && score0 == 4'b1001) begin
		score0 = 4'b0000;
		score1 = 4'b0000;
		score2 = 4'b0000;
		score3 = score3 + 4'b0001;
	end
	else
		score0 = score0 + 4'b0001;
	end
end
endmodule
