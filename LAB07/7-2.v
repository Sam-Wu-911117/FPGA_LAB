//在LED矩陣製作行人號誌：
//綠燈倒數前20秒：小綠人走動
//綠燈倒數剩下5秒：小綠人跑動
//黃燈：小紅人
//紅燈：小紅人

module LAB_07(clk, rst, day_night, light_led, led_com, seg7_out, seg7_sel, row,
column_green, column_red);
input clk;//pin W16
input rst;//C16
input day_night;//AA20
output[11:0] light_led;//pin E2 ,D3 ,C2 ,c1, L2, L1, G2, G1, U2, N1, AA2, AA1
output led_com;//pin N20
output[2:0] seg7_sel;//pin AB10 ,AB11, AA12
output[6:0] seg7_out;//pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
output[7:0] row, column_green, column_red;
//row:pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
// R pin D7, D6, A9, C9, A8, C8, C11, B11
// G pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
wire led_com;
wire clk_cnt_dn;
wire clk_fst;
wire clk_sel;
wire clk_scan;
wire[7:0] column_out, column_out1, column_out2;
wire[7:0] g1_cnt;
wire[7:0] g2_cnt;
wire[3:0] count_out;
wire[2:0] mode;
wire[3:0] idx, idx1, idx2, idx_cnt;
assign led_com= 1'b1;
assign count_out= (day_night == 1'b0 )? 4'b0000 :
(seg7_sel == 3'b101)? g1_cnt[3:0] :
(seg7_sel == 3'b100)? g1_cnt[7:4] :
(seg7_sel == 3'b011)? g2_cnt[3:0] :
g2_cnt[7:4] ;
freq_div#(23) M0(clk, rst, clk_cnt_dn);
freq_div#(21) M1(clk, rst, clk_fst);
freq_div#(15) M2(clk, rst, clk_sel);
traffic M3(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, {light_led[11:9],light_led[2:0]}, mode);
bcd_to_seg7 M4(count_out, seg7_out);
seg7_select#(4) M5(clk_sel, rst, seg7_sel);
assign column_green= (mode<3'b010)? column_out1: 8'b0;
assign column_red= (mode>3'b001)? column_out2: 8'b0;
assign idx=(mode == 3'b000)?idx1:idx2;
freq_div#(12) M6 (clk, rst, clk_scan);
idx_gen i1(clk_cnt_dn, rst, idx1);
idx_gen i2(clk_fst, rst, idx2);
row_gen r1(clk_scan, rst, idx, row, idx_cnt);
rom_char1 c1(idx_cnt, column_out1);
rom_char2 c2(idx_cnt, column_out2);
endmodule

module rom_char1(addr, data);
input[3:0]addr;
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
endcase
end
endmodule

module rom_char2(addr, data);
input[3:0]addr;
output[7:0]data;
reg[7:0]data;
always@(addr) begin
case(addr)
8'd0: data = 8'h18; 8'd1: data = 8'h18;// red people
8'd2: data = 8'h3C; 8'd3: data = 8'h5A;
8'd4: data = 8'h5A; 8'd5: data = 8'h24;
8'd6: data = 8'h24; 8'd7: data = 8'h66;

8'd8: data = 8'h18; 8'd9: data = 8'h18;// red people
8'd10: data = 8'h3C; 8'd11: data = 8'h5A;
8'd12: data = 8'h5A; 8'd13: data = 8'h24;
8'd14: data = 8'h24; 8'd15: data = 8'h66;
endcase
end
endmodule

module idx_gen(clk, rst, idx);
input clk, rst;
output[3:0] idx;
reg[3:0]idx;
always@(posedge clk or posedge rst) begin
if(rst)
idx= 4'b0000;
else if(idx==4'b1000)
idx= 4'b0000;
else
idx=idx+4'b1000;
end
endmodule

module row_gen(clk, rst, idx, row, idx_cnt);
input clk, rst;
input[3:0]idx;
output[7:0] row;
output[3:0]idx_cnt;
reg[7:0] row;
reg[3:0]idx_cnt;
reg[2:0]cnt;
always@(posedge clk or posedge rst) begin
if(rst) begin
row = 8'b1000_0000;
cnt= 3'd0;
idx_cnt= 4'd0;
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
cnt = cnt+1'b1;
idx_cnt = idx + cnt;
end
end
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset) //???t??o
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule

module seg7_select(clk, reset, seg7_sel);
parameter num_use = 6 ; 
input clk, reset;
output[2:0] seg7_sel;
reg [2:0]seg7_sel;
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

module bcd_to_seg7(bcd_in, seg7);
input[3:0]bcd_in;
output[6:0]seg7;
reg[6:0]seg7;
always@ (bcd_in)
case(bcd_in) // abcdefg
4'b0000: seg7 = 7'b1111110; // 0
4'b0001: seg7 = 7'b0110000; // 1
4'b0010: seg7 = 7'b1101101;
4'b0011: seg7 = 7'b1111001;
4'b0100: seg7 = 7'b0110011;
4'b0101: seg7 = 7'b1011011;
4'b0110: seg7 = 7'b1011111;
4'b0111: seg7 = 7'b1110010;
4'b1000: seg7 = 7'b1111111;
4'b1001: seg7 = 7'b1111011;
default: seg7 = 7'b0000000;
endcase
endmodule

module traffic (clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, light_led, mode);
input clk_fst, clk_cnt_dn, rst, day_night;
output[5:0] light_led;
output[7:0] g1_cnt;
output[7:0] g2_cnt;
output[2:0]mode;
wire g1_en, g2_en;
wire[7:0]g1_cnt;
wire[7:0]g2_cnt;
ryg_ctl M0(clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, g1_en, g2_en,
light_led, mode);
light_cnt_dn_29 M1(clk_cnt_dn, rst, g1_en,g1_cnt); // for light 1
light_cnt_dn_29 M2(clk_cnt_dn, rst, g2_en,g2_cnt); // for light 2
endmodule

module ryg_ctl (clk_fst, clk_cnt_dn, rst, day_night, g1_cnt, g2_cnt, g1_en, g2_en,
light_led, mode);
input clk_fst, clk_cnt_dn, rst, day_night;
input[7:0]g1_cnt, g2_cnt;
output g1_en, g2_en;
output[5:0] light_led;
output[2:0]mode;
reg g1_en, g2_en;
reg[5:0]light_led;
reg[2:0]mode;
always@(posedge clk_fst or posedge rst) begin
if (rst)begin
light_led <= 6'b001_100; // g1 : r2
mode <= 3'b000;
g1_en <= 1'b0;
g2_en <= 1'b0;
end
else if(day_night == 1'b1) // day time
case(mode)
3'd0: begin
light_led <= 6'b001_100; // g1 : r2
g1_en <= 1'b1; // g1 count down
if(g1_cnt == 8'b0000_1001) // after 20 seconds
mode <= mode + 3'b001;
end
3'd1: begin // g1 flashes : r2
if (g1_cnt == 8'b0000_0100) //after 5 seconds
mode <= mode + 3'b001;
else
light_led[3] <= clk_cnt_dn; // g1 flashes
end
3'd2: begin
light_led = 6'b010_100; // y1 : r2
if (g1_cnt == 8'b0000_0000) begin // after 4 seconds
g1_en <= 1'b0;
mode <= mode + 3'b001;
end
end
3'd3: begin
light_led <= 6'b100_001; // r1 : g2
g2_en <= 1'b1;
if(g2_cnt == 8'b0000_1001) // after 20 seconds
mode <= mode + 3'b001;
end
3'd4: begin // r1 : g2 flashes
if(g2_cnt == 8'b0000_0100) // after 5 seconds
mode <= mode + 3'b001;
else
light_led[0] <= clk_cnt_dn; // g2 flashes
end
3'd5: begin
light_led <= 6'b100_010; // r1 : y2
if (g2_cnt == 8'b0000_0000) begin // after 4 seconds
g2_en <= 1'b0;
mode <= 3'b000;
end
end
default: begin // back to mode0
light_led <= 6'b001_100; // g1 : r2
g1_en <= 1'b1; // g1 count down
if(g1_cnt == 8'b0000_1001) // after 20 seconds
mode <= mode + 3'b001;
end
endcase
else if(day_night == 1'b0)begin // night time
light_led <= {{1'b0, clk_cnt_dn, 1'b0}, {1'b0, clk_cnt_dn, 1'b0}};
// y1 flashes : y2 flashes
g1_en <= 1'b0;
g2_en <= 1'b0;
end
end
endmodule

module light_cnt_dn_29 (clk, rst, enable, cnt);
input clk, rst, enable;
output[7:0]cnt;
reg[7:0]cnt;
always@(posedge clk or posedge rst) begin
if(rst)
cnt= 8'b0; // initial state
else if(enable) // 0 -> 29 -> 24 -> ... -> 1 -> 0 -> 29
if(cnt==8'b0)
cnt= 8'b0010_1001; // 29
else if(cnt[3:0] == 4'd0) begin // 20 -> 19, 10 -> 09
cnt[7:4]= cnt[7:4]-4'b0001 ;
cnt[3:0]=4'b1001;
end
else
cnt[3:0]=cnt[3:0]-1'b1; // 19 -> 18, 18 -> 17, 17 -> 16, ?K
else cnt=8'b0;
end
endmodule
