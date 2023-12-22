module  	collision(clk, reset, red, green, coll);
input		clk, reset;
input		[7:0]red, green;
output reg 	coll;
always@(posedge clk or posedge reset)
begin
	if(reset)
		coll<=1'b0;
	else if((red & green) != 8'b0)    //發生碰撞
		coll<=1'b1;
	else
		coll<=coll;
end
endmodule


module 	shift(left, right, reset, unable, out, clk);
input 		left, right, reset, clk, unable;
output reg	[3:0]out;
always@(posedge clk or posedge reset)
begin
	if(reset)
		out<=8'b0001;//row_control_bit
	else if(unable) 		//碰撞狀態
 		out<=8'b0000;
 	else if(left)
		out<={out[2:0],out[3]};
	else if(right)
		out<={out[0],out[3:1]};
 	else
  		out<=out;
end
endmodule
