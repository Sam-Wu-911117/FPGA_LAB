module	move(reset, unable, keycode, ver, hor, clk);
input 		reset, clk, unable;
input 		[3:0]keycode;
output 	[7:0]ver, hor;
wire		left1, right1,left2, right2, up, down;
assign 	left1  =  ~keycode[3]&  ~keycode[2]& ~keycode[1]&  keycode[0] ;//press_1
assign 	right1 = ~keycode[3]&  ~keycode[2]& keycode[1]&  ~keycode[0] ;//press_2
assign 	left2  = keycode[3]&  ~keycode[2]& ~keycode[1]&  ~keycode[0] ;//press_3
assign 	right2 = keycode[3]&  ~keycode[2]& ~keycode[1]&   keycode[0] ;////press_4
//assign 	up    =  keycode[1]& ~keycode[2];
//assign	   down  =  keycode[3];
shift S1(left1, right1, reset, unable, hor, clk); //left & right
shift S2(left2, , right2, unable, hor, clk); //up & down
endmodule

module 	mix(ver, hor, row, red);
input		[3:0]ver, hor, row;
output 	[3:0]red;
assign 	red= (ver==row)?hor:8'b0;
endmodule
