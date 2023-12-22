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
