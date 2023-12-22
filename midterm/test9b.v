//以左上排LED燈設計十字路口紅綠燈，8×8 矩陣顯示器顯示行人號誌，需使用七段顯示器進行倒數(紅燈方倒數)，模式如下：
//A.	白天：
//i.	Round-1：綠燈15秒，走動小綠人。
//ii.	Round-2：黃燈5秒，跑動小黃人。
//iii.	Round-3：紅燈20秒，靜止小紅人。
//B.	晚上：黃燈閃爍，閃爍小黃人，七段顯示器關閉。

module test9b(clk, rst, day_night, light_led, led_com, seg7_out, seg7_sel, row, column_green, column_red);
input		clk;					//pin W16
input		rst;					//pin C16
input		day_night;			//pin AA20
output 	[11:0]light_led;  //pin E2, D3, C2, C1, L2, L1, G2, G1, U2, N1, AA2, AA1
output 	led_com;  			//pin N20
output 	[2:0]seg7_sel;		//pin AB10, AB11, AA12
output 	[6:0]seg7_out;		//pin AB7,AA7,AB6,AB5,AA9,Y9,AB8 
output	[7:0]row, column_green, column_red;
//row:				pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
//column_red:		pin D7, D6, A9, C9, A8, C8, C11, B11
//column_green:	pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
wire		led_com;
wire		clk_cnt_dn;
wire		clk_fst;
wire		clk_sel;
wire		clk_scan;
wire		[7:0]column_out, column_out1, column_out2, column_out3;
wire		[7:0]g1_cnt;
wire		[3:0]count_out;
wire		[2:0]mode;
wire		[3:0]idx, idx1, idx2, idx_cnt;

assign led_com = 1'b1;
assign count_out = (day_night == 1'b0) ? 4'b1111 :
						(seg7_sel == 3'b101) ? g1_cnt[3:0] :
						(seg7_sel == 3'b100) ? g1_cnt[7:4] : 
						(seg7_sel == 3'b011) ? 4'b1111 : 
						(seg7_sel == 3'b010) ? 4'b1111 : 4'b1111;
assign column_green = (mode == 3'b001) ? column_out3 :
							(mode == 3'b000) ? column_out1 : 
							(mode == 3'b011) ? column_out2 : 8'b0;
assign column_red   = (mode == 3'b001) ? column_out3 :
							(mode == 3'b010) ? column_out2 :
							(mode == 3'b011) ? column_out2 : 8'b0;
assign idx = (mode == 3'b000) ? idx1 : idx2;
freq_div#(23) 	 M0(clk, rst, clk_cnt_dn);
freq_div#(21) 	 M1(clk, rst, clk_fst);
freq_div#(15) 	 M2(clk, rst, clk_sel);
traffic 			 M3(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, light_led, mode);
bcd_to_seg7 	 M4(count_out, seg7_out);
seg7_select#(4) M5(clk_sel, rst, seg7_sel);
freq_div#(12)   M6(clk, rst, clk_scan);
idx_gen 		    M7(clk_cnt_dn, rst, idx1); 
idx_gen 		    M8(clk_fst, rst, idx2); 
row_gen 		    M9(clk_scan, rst, idx, row, idx_cnt);
rom_char1 	    M10(idx_cnt, column_out1);
rom_char2 	    M11(idx_cnt, column_out2);
rom_char3 	    M12(idx_cnt, column_out3);
endmodule

///
module freq_div(clk_in, reset, clk_out);
parameter 	exp = 20;   
input 		clk_in, reset;
output 		clk_out;
reg			[exp - 1:0]divider;
integer 		i;

assign clk_out = divider[exp - 1];
always@(posedge clk_in or posedge reset)begin
	if(reset)
		for(i = 0; i < exp; i = i + 1)
			divider[i] = 1'b0;
	else
		divider = divider + 1'b1;
	end
endmodule

///
module traffic(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, light_led, mode);
input 	clk_fst, clk_cnt_dn, rst, day_night;
output	[5:0]light_led;
output	[7:0]g1_cnt;
output	[2:0]mode;
wire 		g1_en;
wire		[7:0]g1_cnt;

ryg_ctl 				M0(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g1_en, light_led, mode);
light_cnt_dn_40 	M1(clk_cnt_dn, rst, g1_en,g1_cnt);  //for light 1
endmodule

///
module ryg_ctl(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g1_en, light_led, mode);
input		clk_fst, clk_cnt_dn, rst, day_night;
input		[7:0]g1_cnt;
output	g1_en;
output   [11:0]light_led;
output	[2:0]mode;
reg		g1_en;
reg		[11:0]light_led;
reg		[2:0]mode;

always@(posedge clk_fst or posedge rst)begin
	if(rst)begin
		light_led[11:3] = 6'b0;
		light_led[2:0] <= 6'b000_001; //g
		mode <= 3'b000;
		g1_en <= 1'b0;		
	end
	else if(day_night == 1'b1)  //day time
	case(mode)
		3'd0:begin
			light_led[2:0] <= 6'b000_001; 	//綠燈十五秒
			g1_en <= 1'b1; 						//g1 count down
			if(g1_cnt == 8'b0010_0101) 		//after 15 seconds(剩下25秒)
				mode <= mode + 3'b001; 
		end
		3'd1:begin
			light_led[2:0] <= 6'b000_010;    //黃燈五秒
			if (g1_cnt == 8'b0010_0000) 		//after 5 seconds(剩下20秒)
				mode <= mode + 3'b001; 			
		end
		3'd2:begin
			light_led[2:0] <= 6'b000_100;	 	//紅燈二十秒
			if(g1_cnt == 8'b0000_0000)begin	//after 20 seconds(剩下0秒)
				mode <= 3'b000;	
			end
		end	
		default:begin	// back to mode0
			light_led[2:0] <= 6'b000_001; 	//綠燈
			g1_en <= 1'b1; 						// g1 count down
			if(g1_cnt == 8'b0010_1000) 		//after 20 seconds
				mode <= mode + 3'b001; 
		end
		endcase
	else if(day_night == 1'b0)begin  //night time
		light_led[2:0] <= {1'b0, clk_cnt_dn, 1'b0};  //黃燈閃
		mode <= 3'b011;
		g1_en <= 1'b0;		
	end
end
endmodule

///
module light_cnt_dn_40(clk, rst, enable, cnt);
input 	clk, rst, enable;
output	[7:0]cnt;
reg		[7:0]cnt;

always@(posedge clk or posedge rst)begin
	if(rst)
		cnt = 8'b0;  //initial state
	else if(enable)  
		if(cnt == 8'b0)
			 cnt = 8'b0100_0000;  
		else if(cnt[3:0] == 4'd0) begin  
			 cnt[7:4] = cnt[7:4] - 4'b0001 ; 
			 cnt[3:0] = 4'b1001;
		end
		else
			 cnt[3:0] = cnt[3:0] - 1'b1;  
	else	
		cnt = 8'b0;	
	end
endmodule

///
module bcd_to_seg7(bcd_in, seg7);
input		[3:0]bcd_in;
output	[6:0]seg7;
reg		[6:0]seg7;

always@(bcd_in)
	case(bcd_in) // abcdefg
		4'b0000: seg7 = 7'b1111110;  //0
		4'b0001: seg7 = 7'b0110000;  //1
		4'b0010: seg7 = 7'b1101101;  //2
		4'b0011: seg7 = 7'b1111001;  //3
		4'b0100: seg7 = 7'b0110011;  //4
		4'b0101: seg7 = 7'b1011011;  //5
		4'b0110: seg7 = 7'b1011111;  //6
		4'b0111: seg7 = 7'b1110010;  //7
		4'b1000: seg7 = 7'b1111111;  //8
		4'b1001: seg7 = 7'b1111011;  //9
		default: seg7 = 7'b0000000; 
	endcase
endmodule

///
module seg7_select(clk, reset, seg7_sel);
parameter	num_use= 6;	
input			clk, reset;
output		[2:0]seg7_sel;
reg			[2:0]seg7_sel;

always@(posedge clk or posedge reset)begin
	if(reset == 1)
		seg7_sel = 3'b101;  //the rightmost one
	else
		if(seg7_sel == 6 - num_use)
			seg7_sel = 3'b101; 
		else
			seg7_sel = seg7_sel - 3'b001;  //shift left
	end
endmodule

///
module idx_gen(clk, rst, idx);
input 	clk, rst;
output	[3:0]idx;
reg		[3:0]idx;

always@(posedge clk or posedge rst)begin
	if(rst)
		idx = 4'b0000;
	else if(idx == 4'b1000)
		idx = 4'b0000;
	else
		idx = idx + 4'b1000;
end
endmodule

///
module row_gen(clk, rst, idx, row, idx_cnt);
input 	clk, rst;
input		[3:0]idx;
output	[7:0] row;
output	[3:0]idx_cnt;
reg		[7:0]row;
reg		[3:0]idx_cnt;
reg		[2:0]cnt;

always@(posedge clk or posedge rst)begin
	if(rst) begin
		row = 8'b1000_0000;
		cnt = 3'd0;
		idx_cnt = 4'd0;
	end
	else begin
		if(row == 8'b00000001) 	
			row = 8'b10000000;
		else
			case(row)
				8'b10000000 : row = 8'b01000000;
				8'b01000000 : row = 8'b00100000;
				8'b00100000 : row = 8'b00010000;
				8'b00010000 : row = 8'b00001000;
				8'b00001000 : row = 8'b00000100;
				8'b00000100 : row = 8'b00000010;
				8'b00000010 : row = 8'b00000001;
				8'b00000001 : row = 8'b10000000;
			endcase
			cnt = cnt + 1'b1;	
			idx_cnt = idx + cnt;	
	end
end
endmodule

///
module rom_char1(addr, data);  //走動
input		[3:0]addr;
output	[7:0]data;
reg		[7:0]data;

always@(addr)begin
	case(addr)
		7'd0:  data = 8'b00111000;	 //0
		7'd1:  data = 8'b00111000; 
		7'd2:  data = 8'b00111000;		
		7'd3:  data = 8'b00010000;
		7'd4:  data = 8'b01111100;		
		7'd5:  data = 8'b00010000;
		7'd6:  data = 8'b00101000;		
		7'd7:  data = 8'b01000100;
		
		7'd8:  data = 8'b00011100;	 //1
		7'd9:  data = 8'b00011100; 
		7'd10: data = 8'b00011100; 	
		7'd11: data = 8'b00001000;
		7'd12: data = 8'b00111110; 	
		7'd13: data = 8'b00001000;
		7'd14: data = 8'b00010100; 	
		7'd15: data = 8'b00100010;
		
		7'd16: data = 8'b00000000;  //blank
		7'd17: data = 8'b00000000;  
		7'd18: data = 8'b00000000; 	
		7'd19: data = 8'b00000000;
		7'd20: data = 8'b00000000; 	
		7'd21: data = 8'b00000000;
		7'd22: data = 8'b00000000; 	
		7'd23: data = 8'b00000000;
	endcase
end
endmodule

///
module rom_char2(addr, data);
input		[3:0]addr;
output	[7:0]data;
reg		[7:0]data;

always@(addr)begin
	case(addr)
		7'd0:  data = 8'b00111000;  //0
		7'd1:  data = 8'b00111000; 
		7'd2:  data = 8'b00111000; 	
		7'd3:  data = 8'b00010000;
		7'd4:  data = 8'b01111100; 	
		7'd5:  data = 8'b00010000;
		7'd6:  data = 8'b00101000; 	
		7'd7:  data = 8'b01000100;
		
		7'd8:  data = 8'b00111000;  //1
		7'd9:  data = 8'b00111000;  
		7'd10: data = 8'b00111000; 	
		7'd11: data = 8'b00010000;
		7'd12: data = 8'b01111100; 	
		7'd13: data = 8'b00010000;
		7'd14: data = 8'b00101000; 	
		7'd15: data = 8'b01000100;
	endcase
end
endmodule

///
module rom_char3(addr, data);
input		[3:0]addr;
output	[7:0]data;
reg		[7:0]data;

always@(addr)begin
	case(addr)
		7'd0:  data = 8'b00111000;	 //0
		7'd1:  data = 8'b00111000; 
		7'd2:  data = 8'b00111000;		
		7'd3:  data = 8'b00010000;
		7'd4:  data = 8'b01111100;		
		7'd5:  data = 8'b00010000;
		7'd6:  data = 8'b00101000;		
		7'd7:  data = 8'b01000100;
		
		7'd8:  data = 8'b00011100;	 //1
		7'd9:  data = 8'b00011100; 
		7'd10: data = 8'b00011100; 	
		7'd11: data = 8'b00001000;
		7'd12: data = 8'b00111110; 	
		7'd13: data = 8'b00001000;
		7'd14: data = 8'b00010100; 	
		7'd15: data = 8'b00100010;
		
		7'd16: data = 8'b00000000;  //blank
		7'd17: data = 8'b00000000;  
		7'd18: data = 8'b00000000; 	
		7'd19: data = 8'b00000000;
		7'd20: data = 8'b00000000; 	
		7'd21: data = 8'b00000000;
		7'd22: data = 8'b00000000; 	
		7'd23: data = 8'b00000000;
	endcase
end
endmodule


