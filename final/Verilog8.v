module key_buf(clk, rst, press_valid, scan_code, display_code);  //左移存入數字
input 	clk, rst, press_valid;
input 	[3:0]scan_code;
output 	[3:0]display_code;
reg 		[3:0]display_code;
always@(posedge clk or posedge rst)begin
	if(rst)
		display_code = 4'b0000;  //initial value
	else
		display_code = press_valid ?  scan_code : 4'b0000;  //{Left_shift_value} : Previous_ value;
end
endmodule

