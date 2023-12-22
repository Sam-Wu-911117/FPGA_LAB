

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

module vaild (clk, rst, press, press_valid);  //用來防止手動按鍵盤有多次輸入
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
