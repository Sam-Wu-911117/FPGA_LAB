//設計一個可以控制白天、晚上的紅綠燈控制電路
//白天(Mode 0~5 重複循環)：
/*
 Mode = 0, 綠燈1亮，紅燈2亮(20秒過後)
 Mode = 1, 綠燈1閃爍，紅燈2亮(5秒過後)
 Mode = 2, 黃燈1亮，紅燈2亮(4秒過後)
 Mode = 3, 紅燈1亮，綠燈2亮(20秒過後)
 Mode = 4, 紅燈1亮，綠燈2閃爍(5秒過後)
 Mode = 5, 紅燈1亮，黃燈2亮(4秒過後)
晚上：
 黃燈1閃爍、黃燈2閃爍
(七段顯示器於綠燈方向號誌同時倒數，紅燈及夜晚時顯示0)
*/

module	 LAB_07(clk, rst, day_night, light_led, led_com, seg7_out, seg7_sel);
input		clk;////pin W16
input		rst;//C16
input		day_night; //AA20
output[11:0] light_led;//pin E2 ,D3 ,C2 ,c1, L2, L1, G2, G1, U2, N1, AA2, AA1
output	led_com;//pin N20
output[2:0]	seg7_sel;//pin AB10 ,AB11, AA12
output[6:0]	seg7_out;//pin AB7, AA7, AB6, AB5, AA9, Y9, AB8 
wire		led_com;
wire		clk_cnt_dn;
wire[7:0]	g1_cnt;
wire[7:0]	g2_cnt;
wire[3:0]	count_out;
assign	led_com= 1'b1;
assign	light_led[8:3] = 6'b0;
assign	count_out  =(day_night == 1'b1 && seg7_sel == 3'b101 ) ? g2_cnt[3:0] :
							(day_night == 1'b1 && seg7_sel == 3'b100 ) ? g2_cnt[7:4] :
							(day_night == 1'b1 && seg7_sel == 3'b011 ) ? g1_cnt[3:0] :
							(day_night == 1'b1 && seg7_sel == 3'b010 ) ? g1_cnt[7:4] :
							8'b0;
freq_div#(23) M0(clk, rst, clk_cnt_dn);
freq_div#(21) M1(clk, rst, clk_fst);
freq_div#(15) M2(clk, rst, clk_sel);
traffic M3(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, {light_led[11:9],light_led[2:0]});
bcd_to_seg7 M4(count_out,seg7_out);
seg7_select#(4) M5(clk_sel,reset,seg7_sel);
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

module light_cnt_dn_29 (clk, rst, enable, cnt);
input		clk, rst, enable;
output	[7:0]	cnt;
reg[7:0]	cnt;//MSB[7:4] for 十位數,LSB[3:0] for 個位數
always@(posedge clk or posedge rst) begin
if(rst)
	cnt= 8'b0; // initial state
else if(enable)  // 0 -> 29 -> 24 -> ... -> 1 -> 0 -> 29
	if(cnt== 8'b0)
		 cnt=8'b00101001;  // 29
	else if(cnt[3:0] == 4'd0) begin  // 20 -> 19, 10 -> 09
		 cnt[7:4]=cnt[7:4]-4'b0001; 
		 cnt[3:0]=4'b1001; 	  
	end
	else
		 cnt[3:0]=cnt[3:0]-4'b0001;   // 19 -> 18, 18 -> 17, 17 -> 16, …
else	cnt=8'b0;	
end
endmodule

module seg7_select(clk, reset, seg7_sel);
parameter num_use = 6;	//設參數
input	clk, reset;
output [2:0]seg7_sel;
reg [2:0]seg7_sel;
always@ (posedge clk or posedge reset) begin
if(reset == 1)	
seg7_sel = 3'b101;  //the rightmost one
else
	if(seg7_sel == 6 - num_use)
	seg7_sel = 3'b101; 
	else
	seg7_sel = seg7_sel - 3'b001;  //shift left
end
endmodule

module ryg_ctl (clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, g1_en, g2_en, light_led);
input	clk_fst, clk_cnt_dn, rst, day_night;
input[7:0]	g1_cnt, g2_cnt;
output	g1_en, g2_en;
output[5:0]	light_led;
reg		g1_en, g2_en;
reg[5:0]	light_led;
reg[2:0]	mode;
always@(posedge clk_fst or posedge rst) begin
if (rst)begin
	light_led <= 6'b001_100; // g1 : r2
	mode <= 3'b0;
	g1_en <= 1'b0;
	g2_en <= 1'b0;
   	end
else if(day_night == 1'b1) begin // day time
case(mode)
3'd0: begin
	light_led <= 6'b001_100; // g1 : r2
	g1_en <= 1'b1; 	// g1 count down
	if(g1_cnt == 8'b0000_1001) 	// after 20 seconds
	mode <= mode + 3'b1; 
	end	
3'd1: begin	// g1 flashes : r2
	if (g1_cnt == 8'b0000_0100) //after 5 seconds
	mode <= mode + 3'b1; 
	else
	light_led[3] <= clk_cnt_dn;	// g1 flashes
	end
3'd2: begin
	light_led = 6'b010_100; 	 // y1 : r2
	if (g1_cnt == 8'b0000_0000) begin	// after 4 seconds
	g1_en <= 1'b0;
	mode <= mode + 3'b1;	
	end
	end
3'd3: begin
	light_led <= 6'b100_001; 	// r1 : g2
	g2_en <= 1'b1;
	if(g2_cnt == 8'b0000_1001)	// after 20 seconds
	mode <= mode + 3'b1; 
	end
3'd4: begin	// r1 : g2 flashes
	if(g2_cnt == 8'b0000_0100)	// after 5 seconds
	mode <= mode + 3'b1; 
	else
	light_led[0] <= clk_cnt_dn;	// g2 flashes
	end
3'd5: 	begin	
	light_led <= 6'b100_010;	// r1 : y2
	if (g2_cnt == 8'b0000_0000) begin	// after 4 seconds
	g2_en <= 1'b0;
	mode <= 3'b0;
	end
	end
default: begin	// back to mode0
	light_led <= 6'b001_100; 	// g1 : r2
	g1_en <= 1'b1; // g1 count down
	if(g1_cnt == 8'b0000_1001) 	// after 20 seconds
	mode <= mode + 3'b1; 
	end
endcase
end
else if(day_night == 1'b0)begin  // night time
//row_en <= 2'b11;
light_led <= {{1'b0, clk_cnt_dn, 1'b0}, {1'b0, clk_cnt_dn, 1'b0}}; 
// y1 flashes : y2 flashes
g1_en <= 1'b0;
g2_en <= 1'b0;
end
end
endmodule

module traffic (clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, light_led);
input 	clk_fst, clk_cnt_dn, rst, day_night;
output[5:0]	light_led;
output[7:0]	g1_cnt;
output[7:0]	g2_cnt;
wire		g1_en, g2_en;
wire[7:0]	g1_cnt;
wire[7:0]	g2_cnt;
ryg_ctl M0(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt,g1_en,g2_en ,light_led);
light_cnt_dn_29 M1(clk_cnt_dn,rst,g1_en,g1_cnt); // for light 1
light_cnt_dn_29 M2(clk_cnt_dn,rst,g2_en,g2_cnt); // for light 2 
endmodule

module bcd_to_seg7(bcd_in, seg7);
input [3:0]bcd_in;
output [6:0]seg7;
reg[6:0] seg7;
always@ (bcd_in)begin
case(bcd_in)  //abcdefg
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
end
endmodule
