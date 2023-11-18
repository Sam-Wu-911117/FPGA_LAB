//設計鍵盤輸入工具，輸入數字顯示在七段顯示器上最左邊那顆，且要能右移，同時於8×8 LCD矩陣上顯示出相對應的國字。
module test7b(clk, reset,column, sel, seg7, column_red, row);
	input 	clk, reset;  	//pin W16, C16
	input		[2:0]column; 	//AA13,AB12,Y16
	output	[2:0]sel; 		//pin AB10, AB11, AA12
	output	[6:0]seg7; 		//pin AB7,AA7,AB6,AB5,AA9,Y9,AB8 
	output	[7:0]row, column_red;
	//row:				pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
	//column_red:		pin D7, D6, A9, C9, A8, C8, C11, B11
	//column_green:	pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
	wire		[7:0]column_out;
	wire		[7:0]idx, idx_cnt;
	wire 		clk_sel;
	wire		[3:0]key_out;
	wire		[3:0]key_code2;

	assign column_red = column_out;
	freq_div#(13) 	(clk,reset,clk_sel );
	key_led			(clk_sel, reset, column, sel, key_code2, key_out);
	bcd_to_seg7		(key_code2, seg7);
	idx_gen 			(key_out, idx);
	row_gen 			(clk_sel, reset, idx, row, idx_cnt);
	rom_char 		(idx_cnt, column_out);
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
module key_led(clk_sel, reset, column, sel, key_code2, key_out);
	input 	clk_sel, reset;
	input		[2:0]column;
	output	[2:0]sel;
	output	[23:0]key_code2;
	output	[3:0]key_out;
	wire 		press,press_valid;
	wire		[3:0]scan_code,key_code2;
	wire		[23:0]key_code;

	count6		(clk_sel, reset, sel);
	key_decode	(sel, column, press, scan_code);
	debounce_ctl(clk_sel, rst, press, press_valid);
	key_buf		(clk_sel, reset, press_valid, scan_code, key_code);
	key_code_mux(key_code, sel, key_code2, key_out);
endmodule

///
module key_decode(sel, column, press, scan_code);
	input		[2:0]sel;
	input		[2:0]column;
	output 	press;
	output	[3:0]scan_code;
	reg		[3:0]scan_code;
	reg 		press;

	always@(sel or column)begin
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
			3'b011:
				case(column)
					3'b101: begin scan_code = 4'b0000; press = 1'b1; end // 0
					default: begin scan_code = 4'b1111; press = 1'b0; end
				endcase
			default:begin 
				scan_code = 4'b1111; press = 1'b0;
			end
		endcase
	end
endmodule

///
module debounce_ctl (clk,rst,press,press_valid);
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
module key_buf(clk, rst, press_valid, scan_code, key_code);
	input 	clk, rst, press_valid;
	input		[3:0]scan_code;
	output	[23:0]key_code;
	reg		[23:0]key_code;

	always@(posedge clk or posedge rst) begin
		if(rst)
			key_code = 24'hffffff;  //initial value
		else
			key_code = press_valid ? {key_code[19:0], scan_code[3:0]} : key_code;
	end
endmodule

///
module key_code_mux(key_code, sel, key_code2, key_out);
	input		[23:0]key_code;
	input		[2:0]sel;
	output	[23:0]key_code2;
	output 	[3:0]key_out;

	assign key_out = key_code[3:0];
	assign key_code2 = (sel == 3'b101) ? key_code[23:20] :
						(sel == 3'b100) ? key_code[19:16] :
						(sel == 3'b011) ? key_code[15:12] :
						(sel == 3'b010) ? key_code[11:8] :
						(sel == 3'b001) ? key_code[7:4] :
						(sel == 3'b000) ? key_code[3:0] : 4'b1111;
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
module bcd_to_seg7(bcd_in, seg7);
	input		[3:0]bcd_in;
	output	[6:0]seg7;
	reg		[6:0]seg7;

	always@(bcd_in)
		case(bcd_in)  //abcdefg
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


/*
module seg7_select(clk, reset, sel, seg7_sel);
	input 	clk, reset;
	input 	[2:0]sel;
	output	[2:0]seg7_sel;
	reg 		[2:0]seg7_sel;
	always@(posedge clk or posedge reset)begin
		if(reset == 1)
			seg7_sel = 3'b101;  //the rightmost one
endmodule
*/

///
module rom_char(addr, data);
	input		[7:0]addr;
	output	[7:0]data;
	reg		[7:0]data;

	always@(addr)begin
		case(addr)
			8'd0 : data = 8'h00; 8'd1 : data = 8'h00;  //Blank
			8'd2 : data = 8'h00; 8'd3 : data = 8'h00;
			8'd4 : data = 8'h00; 8'd5 : data = 8'h00;
			8'd6 : data = 8'h00; 8'd7 : data = 8'h00;

			8'd8 : data = 8'h3C; 8'd9 : data = 8'h42;  //0
			8'd10: data = 8'h46; 8'd11: data = 8'h4A;
			8'd12: data = 8'h52; 8'd13: data = 8'h62;
			8'd14: data = 8'h3C; 8'd15: data = 8'h00; 
		
			8'd16: data = 8'b00000000;  //1
			8'd17: data = 8'b00000000;  
			8'd18: data = 8'b00000000; 
			8'd19: data = 8'b01111110;
			8'd20: data = 8'b00000000; 
			8'd21: data = 8'b00000000;
			8'd22: data = 8'b00000000; 
			8'd23: data = 8'b00000000;

			8'd24: data = 8'b00000000;  //2
			8'd25: data = 8'b00000000;  
			8'd26: data = 8'b00111100; 
			8'd27: data = 8'b00000000;
			8'd28: data = 8'b00000000; 
			8'd29: data = 8'b01111110;
			8'd30: data = 8'b00000000; 
			8'd31: data = 8'b00000000;

			8'd32: data = 8'b00000000;  //3
			8'd33: data = 8'b01111100;  
			8'd34: data = 8'b00000000; 
			8'd35: data = 8'b00111000;
			8'd36: data = 8'b00000000; 
			8'd37: data = 8'b11111110;
			8'd38: data = 8'b00000000; 
			8'd39: data = 8'b00000000;

			8'd40: data = 8'b00000000;  //4
			8'd41: data = 8'b11111111;  
			8'd42: data = 8'b10100101; 
			8'd43: data = 8'b10100101;
			8'd44: data = 8'b11000011; 
			8'd45: data = 8'b10000001;
			8'd46: data = 8'b11111111; 
			8'd47: data = 8'b00000000;

			8'd48: data = 8'b00000000;  //5
			8'd49: data = 8'b11111111;  
			8'd50: data = 8'b00010000; 
			8'd51: data = 8'b11111111;
			8'd52: data = 8'b00010010; 
			8'd53: data = 8'b00100100;
			8'd54: data = 8'b11111111; 
			8'd55: data = 8'b00000000;

			8'd56: data = 8'b00100000;  //6
			8'd57: data = 8'b00010000;  
			8'd58: data = 8'b11111111; 
			8'd59: data = 8'b00100100;
			8'd60: data = 8'b01000100; 
			8'd61: data = 8'b11000011;
			8'd62: data = 8'b00000000; 
			8'd63: data = 8'b00000000;

			8'd64: data = 8'b00100000;  //7
			8'd65: data = 8'b00100000;  
			8'd66: data = 8'b11111111; 
			8'd67: data = 8'b00100000;
			8'd68: data = 8'b00100000; 
			8'd69: data = 8'b00011111;
			8'd70: data = 8'b00000000; 
			8'd71: data = 8'b00000000;

			8'd72: data = 8'b00000000;  //8
			8'd73: data = 8'b00100100;  
			8'd74: data = 8'b00100100; 
			8'd75: data = 8'b01000010;
			8'd76: data = 8'b01000010; 
			8'd77: data = 8'b10000001;
			8'd78: data = 8'b00000000; 
			8'd79: data = 8'b00000000;

			8'd80: data = 8'b00100000;  //9
			8'd81: data = 8'b01111100;  
			8'd82: data = 8'b00100100; 
			8'd83: data = 8'b00100100;
			8'd84: data = 8'b01000101; 
			8'd85: data = 8'b11000111;
			8'd86: data = 8'b00000000; 
			8'd87: data = 8'b00000000;
	endcase
end
endmodule

///
module idx_gen(scan_code ,idx);
	input 	[3:0]scan_code;
	output	[7:0]idx;
	reg		[7:0]idx;

	always@(scan_code)begin
		if(scan_code == 4'b0000)
			idx = 8'd08;
		else if(scan_code == 4'b0001)
			idx = 8'd16;
		else if(scan_code == 4'b0010)
			idx = 8'd24;
		else if(scan_code == 4'b0011)
			idx = 8'd32;
		else if(scan_code == 4'b0100)
			idx = 8'd40;
		else if(scan_code == 4'b0101)
			idx = 8'd48;
		else if(scan_code == 4'b0110)
			idx = 8'd56;
		else if(scan_code == 4'b0111)
			idx = 8'd64;
		else if(scan_code == 4'b1000)
			idx = 8'd72;
		else if(scan_code == 4'b1001)
			idx = 8'd80;
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
			row = 8'b1000_0000;
			cnt = 3'd0;
			idx_cnt = 8'd0;
		end
		else begin
			row = {row[0], row[7:1]}; 	//輪流將每一列LED致能
			cnt = cnt + 3'd1; 			//從0數到7
			idx_cnt = idx + cnt; 		//將初始位置加0到7
		end
	end
endmodule