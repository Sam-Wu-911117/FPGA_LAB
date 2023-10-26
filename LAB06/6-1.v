//以鍵盤為輸入工具，將所鍵入的數字依序顯示在六個位數的七段顯示器上(當輸入新資料時,舊資料向左移動)
module LAB_06 (clk, rst, column, sel, seg7);
input 	clk, rst;		//pin W16,C16
input	[2:0]column;	//pin AA13, AB12, Y16
output	[2:0]sel;		//pin AB10, AB11, AA12
output	[6:0]seg7;	//pin AB7, AA7, AB6, AB5, AA9, Y9, AB8 
wire 	clk_sel;
wire		[3:0]key_code;

freq_div#(13) M1(clk, rst, clk_sel);
key_seg7_6dig M2(clk_sel, rst, column, sel, key_code);
bcd_to_seg7   M3(key_code, seg7);
endmodule

module freq_div(clk_in, reset, clk_out);
parameter 	exp = 20;   
input 		clk_in, reset;
output 		clk_out;
reg 			[exp - 1:0]divider;
integer 		i;

assign clk_out = divider[exp - 1];
always@(posedge clk_in or posedge reset)begin	//正緣觸發
	if(reset)
		for(i = 0; i < exp; i = i + 1)
			divider[i] = 1'b0;
	else
		divider = divider + 1'b1;
end
endmodule

module key_seg7_6dig(clk_sel, rst, column, sel, key_code);
input 	clk_sel, rst;
input 	[2:0]column;
output 	[2:0]sel;
output 	[3:0]key_code;
wire 		press, press_valid;
wire 		[3:0]scan_code, key_code;
wire 		[23:0]display_code;

count6       M4(clk_sel, rst, sel);
key_decode   M5(sel, column, press, scan_code);
debounce_ctl M6(clk_sel, rst, press, press_valid);
key_buf6     M7(clk_sel, rst, press_valid, scan_code, display_code);
key_code_mux M8(display_code, sel, key_code);
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
				3'b110: begin scan_code = 4'b0011; press = 1'b1;end   // 3
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		3'b001:
			case(column)
				3'b011: begin scan_code = 4'b0100; press = 1'b1;end   // 4
				3'b101: begin scan_code = 4'b0101; press = 1'b1;end   // 5
				3'b110: begin scan_code = 4'b0110; press = 1'b1;end   // 6
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase 
		3'b010:
			case(column)
				3'b011: begin scan_code = 4'b0111; press = 1'b1;end   // 7
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

module debounce_ctl (clk, rst, press, press_valid);  //用來防止手動按鍵盤有多次輸入
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

module key_buf6(clk, rst, press_valid, scan_code, display_code);  //左移存入數字
input 	clk, rst, press_valid;
input 	[3:0]scan_code;
output 	[23:0]display_code;
reg 		[23:0]display_code;

always@(posedge clk or posedge rst)begin
	if(rst)
		display_code = 24'hffffff;  //initial value
	else
		display_code = press_valid ? {display_code[19:0], scan_code} : display_code;  //{Left_shift_value} : Previous_ value;
	end
endmodule

module key_code_mux(display_code, sel, key_code);  //選擇每個燈位輸出值
input 	[23:0]display_code;
input 	[2:0]sel;
output 	[3:0]key_code;

assign key_code = (sel == 3'b101) ? display_code[3:0] :  //選擇輸出燈位
	(sel== 3'b100) ? display_code[7:4]   :
	(sel== 3'b011) ? display_code[11:8]  :
	(sel== 3'b010) ? display_code[15:12] :
	(sel== 3'b001) ? display_code[19:16] :
	(sel== 3'b000) ? display_code[23:20] : 4'b1111;
endmodule

module bcd_to_seg7(bcd_in, seg7);
input 	[3:0]bcd_in;
output 	[6:0]seg7;
reg 		[6:0]seg7;

always@(bcd_in)begin
	case(bcd_in)  // abcdefg
		4'b0000:seg7 = 7'b1111110;  //0
		4'b0001:seg7 = 7'b0110000;  //1
		4'b0010:seg7 = 7'b1101101;  //2
		4'b0011:seg7 = 7'b1111001;  //3
		4'b0100:seg7 = 7'b0110011;  //4
		4'b0101:seg7 = 7'b1011011;  //5
		4'b0110:seg7 = 7'b1011111;  //6
		4'b0111:seg7 = 7'b1110000;  //7
		4'b1000:seg7 = 7'b1111111;  //8
		4'b1001:seg7 = 7'b1111011;  //9
		default:seg7 = 7'b0000000; 
	endcase
end
endmodule
