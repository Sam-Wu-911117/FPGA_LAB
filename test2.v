module PR2(clk, rst, row, sel, column_green, column_red);
input clk, rst; //pin W16,C16
input[1:0] sel;	//選擇LDE亮紅燈OR綠燈 //pin AA15, AA14 //最左邊兩個按鈕
output[7:0] row, column_green, column_red;
      //red Pin D7,D6,A9,C9,A8,C8,C11,B11;
     //row Pin T22,R21,C6,B6,B5,A5,B7,A7;
     //green Pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14;
wire clk_shift, clk_scan;
wire[7:0] idx_cnt;
wire[7:0] column_out;
assign column_green= (sel== 2'b01 || sel== 2'b11)? column_out: 8'b0;
assign column_red= (sel== 2'b10 || sel== 2'b11)? column_out: 8'b0;
freq_div#(22) M1 (clk,rst,clk_shift);
freq_div#(12) M2 (clk,rst,clk_scan);
row_gen M4 (clk_scan,rst,9'd0,row,idx_cnt);
rom_char M5 (clk_shift,rst,idx_cnt,column_out);
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

/*
[71:0]row0=72'b00000000 00000000 00000000 000000000000000000000000000000000000000000000000; 
[71:0]row1=72'b11111000 00011000 01111110 011111100001100001111110011111100011110000000000;
[71:0]row2=72'b10000100 00101000 01000010 000000100010100000000010000000100100001000000000;
[71:0]row3=72'b10000100 00001000 01000010 000000100000100000000010000000100100001000000000;
[71:0]row4=72'b11111000 00001000 01000010 011111100000100001111110011111100011110000000000;
[71:0]row5=72'b10000100 00001000 01000010 010000000000100001000000010000000100001000000000;
[71:0]row6=72'b10000100 00001000 01000010 010000000000100001000000010000000100001000000000;
[71:0]row7=72'b11111000 01111110 01111110 011111100111111001111110011111100011110000000000;
*/

module rom_char(clk, rst, addr, data);
input clk,rst;
input[7:0]addr;
output[7:0]data;
reg[7:0]data;
reg[71:0]row0;
reg[71:0]row1;
reg[71:0]row2;
reg[71:0]row3;
reg[71:0]row4;
reg[71:0]row5;
reg[71:0]row6;
reg[71:0]row7;
always@(posedge clk or posedge rst) begin
if(rst)begin
row0<=72'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000 ; 
row1<=72'b11111000_00011000_01111110_01111110_00011000_00011000_01111110_01111110_00000000 ; 
row2<=72'b10000100_00101000_01000010_00000010_00101000_00101000_01000000_01000000_00000000 ;
row3<=72'b10000100_00001000_01000010_00000010_00001000_00001000_01000000_01000000_00000000 ;
row4<=72'b11111000_00001000_01000010_01111110_00001000_00001000_01111110_01111110_00000000 ;
row5<=72'b10000100_00001000_01000010_01000000_00001000_00001000_01000000_01000010_00000000 ;
row6<=72'b10000100_00001000_01000010_01000000_00001000_00001000_01000000_01000010_00000000 ;
row7<=72'b11111000_01111110_01111110_01111110_01111110_01111110_01111110_00111100_00000000 ;
end
else begin
row0<={row0[70:0], row0[71]};
row1<={row1[70:0], row1[71]};
row2<={row2[70:0], row2[71]};
row3<={row3[70:0], row3[71]};
row4<={row4[70:0], row4[71]};
row5<={row5[70:0], row5[71]};
row6<={row6[70:0], row6[71]};
row7<={row7[70:0], row7[71]};
end
end
always@(addr) begin
case(addr)
8'd0:data <= row0[8:1];
8'd1:data <= row1[8:1];
8'd2:data <= row2[8:1];
8'd3:data <= row3[8:1];
8'd4:data <= row4[8:1];
8'd5:data <= row5[8:1];
8'd6:data <= row6[8:1];
8'd7:data <= row7[8:1];
endcase
end
endmodule

module row_gen(clk, rst, idx, row, idx_cnt);
input clk, rst;
input[8:0]idx;
output[8:0] row;
output[8:0]idx_cnt;
reg[7:0] row;
reg[8:0]idx_cnt;
reg[2:0]cnt;
always@(posedge clk or posedge rst) begin
if(rst) begin
row <= 8'b0000_0001;
cnt <= 3'd0;
idx_cnt <= 9'd0;
end
else begin
row <= {row[0],row[7:1]};//(輪流將每一列LED致能)
cnt <= cnt + 1'b1;//(從0數到7) 
idx_cnt <= idx + cnt;//(將初始位置加0到7)
end
end
endmodule
