//LED矩陣由上往下移動依序顯示數字9-0，可選擇顯示之顏色為黃綠紅
module LAB_04(clk, rst, row, sel, column_green, column_red);
input clk, rst; //clk: pin W16 rst: pin C16
input[1:0] sel;	//選擇LDE亮紅燈OR綠燈
//pin AA15 ,AA14
output[7:0] row, column_green, column_red;
//row:pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
//column_green pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14
// column_red pin D7, D6, A9, C9, A8, C8, C11, B11
//column_green/red比照Lab1
wire clk_shift, clk_scan;
wire[6:0] idx, idx_cnt;
wire[7:0] column_out;
assign column_green= (sel== 2'b01 || sel== 2'b11)? column_out: 8'b0;
assign column_red= (sel== 2'b10 || sel== 2'b11)? column_out: 8'b0;
freq_div#(22) M1 (clk, reset, clk_shift);
freq_div#(12) M2 (clk, reset, clk_scan);
idx_gen  M3(clk_shift, rst, idx); 
row_gen  M4(clk_scan, rst, idx, row, idx_cnt);
rom_char M5(idx_cnt, column_out);
endmodule

module rom_char(addr, data);
input[6:0]addr;
output[7:0]data;
reg[7:0]data;
always@(addr) begin
case(addr)
7'd0: data = 8'h00; 7'd1: data = 8'h00; // Blank
7'd2: data = 8'h00; 7'd3: data = 8'h00;
7'd4: data = 8'h00; 7'd5: data = 8'h00;
7'd6: data = 8'h00; 7'd7: data = 8'h00;
7'd8: data = 8'h3C; 7'd9: data = 8'h42; // 0
7'd10: data = 8'h46; 7'd11: data = 8'h4A;
7'd12: data = 8'h52;	7'd13: data = 8'h62;
7'd14: data = 8'h3C;	7'd15: data = 8'h00;
7'd16: data = 8'h08;	7'd17: data = 8'h18;// 1
7'd18: data = 8'h08;	7'd19: data = 8'h08;
7'd20: data = 8'h08;	7'd21: data = 8'h08;
7'd22: data = 8'h1C;	7'd23: data = 8'h00;
7'd24: data = 8'h3C;	7'd25: data = 8'h42;// 2
7'd26: data = 8'h42;	7'd27: data = 8'h04;
7'd28: data = 8'h08;	7'd29: data = 8'h10;
7'd30: data = 8'h7E;	7'd31: data = 8'h00;
7'd32: data = 8'h3C; 	7'd33: data = 8'h42;// 3
7'd34: data = 8'h02;		7'd35: data = 8'h3C;
7'd36: data = 8'h02;		7'd37: data = 8'h42;
7'd38: data = 8'h3C;		7'd39: data = 8'h00;
7'd40: data = 8'h1C; 	7'd41: data = 8'h24;// 4
7'd42: data = 8'h44;		7'd43: data = 8'h44;
7'd44: data = 8'h44;		7'd45: data = 8'h7E;
7'd46: data = 8'h04;		7'd47: data = 8'h00;
7'd48: data = 8'h7E;		7'd49: data = 8'h40;//5
7'd50: data = 8'h40;		7'd51: data = 8'h7C;
7'd52: data = 8'h02;		7'd53: data = 8'h42;
7'd54: data = 8'h3C;		7'd55: data = 8'h00;

	7'd56: data = 8'h3C;	7'd57: data = 8'h40;  //6
	7'd58: data = 8'h40;	7'd59: data = 8'h7C;
	7'd60: data = 8'h42;	7'd61: data = 8'h42;
	7'd62: data = 8'h3C;	7'd63: data = 8'h00;

	7'd64: data = 8'h3C;	7'd65: data = 8'h42;  //7
	7'd66: data = 8'h42;	7'd67: data = 8'h42;
	7'd68: data = 8'h2 ;	7'd69: data = 8'h2;
	7'd70: data = 8'h2 ;	7'd71: data = 8'h00;

	7'd72: data = 8'h3C;	7'd73: data = 8'h42;  //8
	7'd74: data = 8'h42;	7'd75: data = 8'h3C;
	7'd76: data = 8'h42;	7'd77: data = 8'h42;
	7'd78: data = 8'h3C;	7'd79: data = 8'h00;

	7'd80: data = 8'h3C;	7'd81: data = 8'h42;  //9
	7'd82: data = 8'h42;	7'd83: data = 8'h3E;
	7'd84: data = 8'h2 ;	7'd85: data = 8'h2 ;
	7'd86: data = 8'h3C;	7'd87: data = 8'h00;
endcase
end
endmodule

module idx_gen(clk, rst, idx);
input clk, rst;
output[6:0] idx;
reg[6:0]idx;
always@(posedge clk or posedge rst)begin  //加分題
    if(rst)
        idx = 7'd80;
    else if(idx == 7'd0)
        idx = 7'd80;
    else
        idx = idx - 7'd01;  //idx = idx + 7'b01 下往上
end
endmodule

module row_gen(clk, rst, idx, row, idx_cnt);
input clk, rst;
input[6:0]idx;
output[7:0] row;
output[6:0]idx_cnt;
reg[7:0] row;
reg[6:0]idx_cnt;
reg[2:0]cnt;
always@(posedge clk or posedge rst) begin
if(rst) begin
row <= 8'b0000_0001;
cnt <= 3'd0;
idx_cnt <= 7'd0;
end
else begin
row <= {row[0], row[7:1]};  //輪流將每一列LED致能
cnt <= cnt + 1'b1;          //從0數到7 
idx_cnt <= idx + cnt;       //將初始位置加0到7
end
end
endmodule

module freq_div(clk_in, reset, clk_out);
parameter	exp = 20;   
input 		clk_in, reset;
output 		clk_out;
reg 			[exp - 1:0]divider;
integer 		i;
assign clk_out = divider[exp - 1];
always@ (posedge clk_in or posedge reset)	//正緣觸發
begin
if(reset)
for(i = 0; i < exp; i = i + 1) divider[i] = 1'b0;
else
divider = divider + 1'b1;
end
endmodule
