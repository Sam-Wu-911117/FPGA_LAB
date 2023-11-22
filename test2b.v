//在LCD矩陣由右往左移動依序顯示你的學號，可選擇顯示之顏色為黃綠紅。 可切換方向
module test02_c(clk, reset,enable, row, sel, column_green, column_red,selrl);
input clk, reset,enable,selrl;//pin W16,C16,AA15,AA14
input[1:0] sel; //選擇LDE亮紅燈OR綠燈
//pin AB20,AA20
output[7:0] row, column_green, column_red;
//row:pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
//row Pin T22,R21,C6,B6,B5,A5,B7,A7;
//green Pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14;
wire clk_shift, clk_scan;
wire[2:0] cnt;
wire[7:0] column_out;
assign column_green= (sel== 2'b01 || sel== 2'b11)? column_out: 8'b0;
assign column_red= (sel== 2'b10 || sel== 2'b11)? column_out: 8'b0;
freq_div#(20) M1 (clk, reset, clk_shift);
freq_div#(12) M2 (clk, reset, clk_scan);
idx_gen M3 ( clk_shift, reset,enable,cnt, column_out,selrl); 
row_gen M4 (clk_scan, reset,  row, cnt);
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;   
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset) //正緣觸發
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule

module idx_gen(clk, rst,enable,cnt, column_out,selrl);
input clk, rst,enable,selrl;
input [2:0] cnt;
output[7:0] column_out;
reg[71:0]idx0;
reg[71:0]idx1;
reg[71:0]idx2;
reg[71:0]idx3;
reg[71:0]idx4;
reg[71:0]idx5;
reg[71:0]idx6;
reg[71:0]idx7;
assign column_out=(cnt==3'd0)?idx7[71:64]:(cnt==3'd1)?idx0[71:64]:
(cnt==3'd2)?idx1[71:64]:(cnt==3'd3)?idx2[71:64]:
(cnt==3'd4)?idx3[71:64]:(cnt==3'd5)?idx4[71:64]:
(cnt==3'd6)?idx5[71:64]:(cnt==3'd7)?idx6[71:64]:idx7[71:64];
always@(posedge clk or posedge rst) begin
if(rst)begin
idx0<=72'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000 ; 
idx1<=72'b11111000_00011000_01111110_01111110_00011000_00011000_01111110_01111110_00000000 ; 
idx2<=72'b10000100_00101000_01000010_00000010_00101000_00101000_01000000_01000000_00000000 ;
idx3<=72'b10000100_00001000_01000010_00000010_00001000_00001000_01000000_01000000_00000000 ;
idx4<=72'b11111000_00001000_01000010_01111110_00001000_00001000_01111110_01111110_00000000 ;
idx5<=72'b10000100_00001000_01000010_01000000_00001000_00001000_01000000_01000010_00000000 ;
idx6<=72'b10000100_00001000_01000010_01000000_00001000_00001000_01000000_01000010_00000000 ;
idx7<=72'b11111000_01111110_01111110_01111110_01111110_01111110_01111110_00111100_00000000 ;
end
else if(enable)begin
idx0<=(selrl==1)?{idx0[70:0], idx0[71]}:{idx0[0],idx0[71:1]};
idx1<=(selrl==1)?{idx1[70:0], idx1[71]}:{idx1[0],idx1[71:1]};
idx2<=(selrl==1)?{idx2[70:0], idx2[71]}:{idx2[0],idx2[71:1]};
idx3<=(selrl==1)?{idx3[70:0], idx3[71]}:{idx3[0],idx3[71:1]};
idx4<=(selrl==1)?{idx4[70:0], idx4[71]}:{idx4[0],idx4[71:1]};
idx5<=(selrl==1)?{idx5[70:0], idx5[71]}:{idx5[0],idx5[71:1]};
idx6<=(selrl==1)?{idx6[70:0], idx6[71]}:{idx6[0],idx6[71:1]};
idx7<=(selrl==1)?{idx7[70:0], idx7[71]}:{idx7[0],idx7[71:1]};
end

else begin
idx0=idx0;
idx1=idx1;
idx2=idx2;
idx3=idx3;
idx4=idx4;
idx5=idx5;
idx6=idx6;
idx7=idx7;
end
end
endmodule

module row_gen(clk, rst,  row, cnt);
input clk, rst;
output[7:0] row;
output[2:0]cnt;
reg[7:0] row;
reg[2:0]cnt;
always@(posedge clk or posedge rst) begin
if(rst) begin
row <= 8'b0000_0001;
cnt <= 3'd0;
end
else begin
row <= {row[0],row[7:1]};//(輪流將每一列LED致能)
cnt <= cnt+3'b1;//(從0數到7) 
end
end
endmodule