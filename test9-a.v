// 以左上排LED燈設計十字路口紅綠燈，8×8 矩陣顯示器顯示行人號誌，需使用七段顯示器進行倒數(紅燈方倒數)，模式如下：
//A.	白天：
//i.	Round-1：綠燈12秒，走動小綠人。
//ii.	Round-2：綠燈閃爍3秒，跑動小綠人。
//iii.	Round-3：黃燈5秒，閃爍小黃人。
//iv.	Round-4：紅燈20秒，靜止小紅人。
//B.	晚上：黃燈閃爍，閃爍小黃人，七段顯示器顯示0000。

module	 lab07_2 (clk, rst, day_night, light_led, led_com, seg7_out, seg7_sel,row,  column_red,column_green);
input		clk; //pin W16
input		rst; //pin C16
input		day_night; //AA20
output[5:0]	light_led; //pin E2 ,D3 ,C2 ,c1, L2, L1, G2, G1, U2, N1, AA2, AA1
output	led_com; //pin N20
output[2:0]	seg7_sel; //pin AB10 ,AB11, AA12
output[6:0]	seg7_out; //pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
output[7:0] row,  column_red,column_green;
//row:pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
// R pin D7, D6, A9, C9, A8, C8, C11, B11
// G pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
wire		led_com;
wire		clk_cnt_dn,clk_fst,clk_sel,clk_out,clk_fst2;
wire[7:0]	g1_cnt;
wire[7:0]	g2_cnt;
wire[3:0]	count_out;
wire[7:0] idx,idx_cnt;
wire[7:0] column_out;
wire[2:0]k;
assign clk_out=(k==3'b000)?clk_fst:(k==3'b001)?clk_fst2:clk_fst;
assign	led_com= 1'b1;
assign	count_out = (seg7_sel == 3'b101 )? g2_cnt[3:0] : (seg7_sel == 3'b100 )? g2_cnt[7:4] :
(seg7_sel == 3'b011 )? 3'b0 : 
(seg7_sel == 3'b010 )? 3'b0 : 
(seg7_sel == 3'b001 )? g1_cnt[3:0] :g1_cnt[7:4];
assign column_green=( k==3'b000||k==3'b001||k==3'b010)? column_out: 8'b0;
assign column_red= (k==3'b010||k==3'b011||k==3'b100)? column_out: 8'b0;
freq_div#(23) M0(clk, rst, clk_cnt_dn);
freq_div#(21) M1(clk, rst, clk_fst);
freq_div#(19) M9(clk, rst, clk_fst2);
freq_div#(15) M2(clk, rst, clk_sel);
traffic M3(clk_fst,clk_cnt_dn,rst,day_night,g1_cnt,g2_cnt,light_led,k);
bcd_to_seg7 M4(count_out,seg7_out);
seg7_select#(6) M5(clk_sel,rst,seg7_sel);
idx_gen M6 (clk_out, rst, idx,k); 
row_gen M7 (clk_sel,rst,idx,row,idx_cnt);
rom_char M8 (idx_cnt,column_out);

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

module bcd_to_seg7(bcd_in, seg7);
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
endmodule

module seg7_select(clk, reset, seg7_sel);
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
endmodule

module light_cnt_dn_20 (clk, rst, enable, cnt);
input		clk, rst, enable;
output	[7:0]	cnt;
reg[7:0]	cnt;
always@(posedge clk or posedge rst) begin
if(rst)
	cnt= 8'b0; // initial state
else if(enable)begin  
	if(cnt== 8'b0) begin
		 cnt[7:4]= 4'b0010;
		 cnt[3:0]= 4'b0000;
		 //cnt[3:0]=cnt[3:0]-4'b0001;
	end
	else if(cnt[3:0] == 4'd0) begin  
		 cnt[3:0]=4'b1001;
		 cnt[7:4]=cnt[7:4]-4'b0001;
			  
	end
	else
		 cnt[3:0]=cnt[3:0]-4'b0001;  
end
else	
	cnt=8'b0;	
end
endmodule

module ryg_ctl (clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, g1_en, g2_en, light_led,k);
input	clk_fst, clk_cnt_dn, rst, day_night;
input[7:0]	g1_cnt, g2_cnt;
output	g1_en, g2_en;
output[5:0]	light_led;
output [2:0]k;
reg		g1_en, g2_en;
reg[5:0]	light_led;
reg[2:0]	mode,k;
always@(posedge clk_fst or posedge rst) begin
if (rst)begin
	light_led <= 6'b001_100; // g1 : r2
	mode <= 3'b0;
	g1_en <= 1'b0;
	g2_en <= 1'b0;
	k <= 3'b0;
   	end
else if(day_night == 1'b1)begin // day time
if(mode==3'd0) begin
	k<=3'b000;
	light_led <= 6'b001_100; // g1 : r2
	g1_en <= 1'b1; 	// g1 count down
	if(g1_cnt == 8'b0000_1000) 	// after 12 seconds
	mode <= mode + 3'b1; 
	end
else if(mode==3'd1) begin	// g1 flashes : r2
	k<=3'b001;
	if (g1_cnt == 8'b0000_0101) //after 3 seconds
	mode <= mode + 3'b1; 
	else
	light_led[3] <= clk_cnt_dn;	// g1 flashes
	end
else if(mode==3'd2) begin
	k<=3'b010;
	light_led = 6'b010_100; 	 // y1 : r2
	if (g1_cnt == 8'b0000_0000) begin	// after 5 seconds
	g1_en <= 1'b0;
	mode <= mode + 3'b1;	
	end
	end
else if(mode==3'd3) begin
	k<=3'b100;
	light_led <= 6'b100_001; 	// r1 : g2
	g2_en <= 1'b1;
	if(g2_cnt == 8'b0000_1000)	// after 12 seconds
	mode <= mode + 3'b1; 
	end
else if(mode==3'd4) begin
	//k<=3'b1001;	// r1 : g2 flashes
	if(g2_cnt == 8'b0000_0101)	// after 3 seconds
	mode <= mode + 3'b1; 
	else
	light_led[0] <= clk_cnt_dn;	// g2 flashes
	end
else if(mode==3'd5) 	begin	
	light_led <= 6'b100_010;	// r1 : y2
	if (g2_cnt == 8'b0000_0000) begin	// after 5 seconds
	g2_en <= 1'b0;
	mode <= 3'b0;
	end
	end
/*else begin	// back to mode0
	k <= 3'b001;
	light_led <= 6'b001_100; 	// g1 : r2
	g1_en <= 1'b1; // g1 count down
	if(g1_cnt == 8'b0000_1001) 	// after 20 seconds
	mode <= mode + 3'b1; 
	end*/
end
else if(day_night == 1'b0)begin  // night time
k=3'b011;
//row_en <= 2'b11;
light_led <= {{1'b0, clk_cnt_dn, 1'b0}, {1'b0, clk_cnt_dn, 1'b0}}; 
// y1 flashes : y2 flashes
g1_en <= 1'b0;
g2_en <= 1'b0;
end
end
endmodule

module traffic (clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, light_led,k);
input 	clk_fst, clk_cnt_dn, rst, day_night;
output[5:0]	light_led;
output[7:0]	g1_cnt;
output[7:0]	g2_cnt;
output[2:0]k;
//output clk_out;
wire		g1_en, g2_en;
wire[7:0]	g1_cnt;
wire[7:0]	g2_cnt;
wire[2:0]k;
//wire clk_out;
ryg_ctl M0(clk_fst,clk_cnt_dn,rst,day_night,g1_cnt,g2_cnt,g1_en,g2_en,light_led,k);
light_cnt_dn_20 M1(clk_cnt_dn,rst,g1_en,g1_cnt); // for light 1
light_cnt_dn_20 M2(clk_cnt_dn,rst,g2_en,g2_cnt); // for light 2 
//controll M3(clk_fst,clk_sel,k,clk_out);
endmodule

module rom_char(addr, data);
input[7:0]addr;
output[7:0]data;
reg[7:0]data;
always@(addr) begin
case(addr)
8'd0: data = 8'h60; 8'd1: data = 8'h60; // Blank
8'd2: data = 8'h30; 8'd3: data = 8'h78;
8'd4: data = 8'h18; 8'd5: data = 8'h34;
8'd6: data = 8'h22; 8'd7: data = 8'h66;
8'd8: data = 8'h60; 8'd9: data = 8'h60; // 0
8'd10: data = 8'h30; 8'd11: data = 8'h7C;
8'd12: data = 8'hB2; 8'd13: data = 8'h18;
8'd14: data = 8'h66; 8'd15: data = 8'h02;
8'd16: data = 8'hC0; 8'd17: data = 8'hC0;// 1
8'd18: data = 8'h60; 8'd19: data = 8'h78;
8'd20: data = 8'hB4; 8'd21: data = 8'h38;
8'd22: data = 8'h26; 8'd23: data = 8'h62;
8'd24: data = 8'h18; 8'd25: data = 8'h18;// red people
8'd26: data = 8'h3C; 8'd27: data = 8'h5A;
8'd28: data = 8'h5A; 8'd29: data = 8'h24;
8'd30: data = 8'h24; 8'd31: data = 8'h66;
8'd32: data = 8'h18; 8'd33: data = 8'h18;// yellow people
8'd34: data = 8'h3C; 8'd35: data = 8'h5A;
8'd36: data = 8'h5A; 8'd37: data = 8'h24;
8'd38: data = 8'h24; 8'd39: data = 8'h66;
8'd40: data = 8'h00; 8'd41: data = 8'h00;// blank
8'd42: data = 8'h00; 8'd43: data = 8'h00;
8'd44: data = 8'h00; 8'd45: data = 8'h00;
8'd46: data = 8'h00; 8'd47: data = 8'h00;

endcase
end
endmodule

module idx_gen(clk, rst, idx,k);
input clk, rst;
input[2:0]k;
output[7:0] idx;
reg[7:0]idx;
//wire [1:0]sel;
always@(posedge clk or posedge rst) begin
if(rst)begin
idx=8'd00;
end
else if(k==3'b000||k==3'b001)begin
//idx= 8'd0;
if(idx==8'd16)
idx= 8'd0;
else if(idx==8'd24)
idx=8'd0;
else
idx=idx+8'd08;
end
else if(k==3'b010)begin
if(idx==8'd40)
idx=8'd32;
else
idx=idx+8'd08;
end
else if(k==3'b100||k==3'b011)begin

idx= 8'd24;

end
//end
end
endmodule


module row_gen(clk, rst, idx, row, idx_cnt);
input clk, rst;
input[7:0]idx;
output[7:0] row;
output[7:0]idx_cnt;
//wire [7:0] idx,idx2;
reg[7:0] row;
reg[7:0]idx_cnt;
reg[2:0]cnt;
//assign idx0=(select==2'b00)?idx:idx2
always@(posedge clk or posedge rst) begin
if(rst) begin
row = 8'b1000_0000;
cnt= 3'd0;
idx_cnt= 8'd0;
end
else begin
row = {row[0],row[7:1]};	//(輪流將每一列LED致能)
cnt = cnt+3'd1;	//(從0數到7) 
idx_cnt = idx+cnt;	//(將初始位置加0到7)
end
end
endmodule
