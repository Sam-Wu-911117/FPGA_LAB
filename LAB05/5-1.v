//設計一個可以用數字鍵0~9控制LED燈的功能
module LAB_05(clk, reset, column, sel, led, led_com);
input     clk, reset;       //pin W16, C16
input     [2:0]column;      //pin AA13, AB12, Y16
output     [2:0]sel;        //pin AB10, AB11, AA12
output     [9:0]led;        //pin E2, D3, C2, C1 , L2, L1, G2, G1, U2, N1
output     led_com;         //pin N20
assign led_com = 1'b1;
wire clk_sel;
wire[3:0] key_code;
freq_div#(13) (clk, reset, clk_sel);
key_led(clk_sel, reset, column, sel, key_code);
bcd_led(key_code, led);
endmodule


module freq_div(clk_in, reset, clk_out);
parameter 	exp = 20;   
input 		clk_in, reset;
output 		clk_out;
reg 			[exp - 1 : 0]divider;
integer 		i;


assign clk_out = divider[exp - 1];
always@ (posedge clk_in or posedge reset)begin	//正緣觸發
	if(reset)
		for(i = 0; i < exp; i = i + 1) divider[i] = 1'b0;
	else
		divider = divider + 1'b1;
	end
endmodule

module key_led(clk_sel, reset, column, sel, key_code);
input 	clk_sel, reset;
input 	[2:0]column;
output 	[2:0]sel;
output 	[3:0]key_code;
wire 		press;
wire 		[3:0]scan_code, key_code;

count4(clk_sel, reset, sel);
key_decode(sel, column, press, scan_code);
key_buf(clk_sel, rst, press, scan_code, key_code);
endmodule

module count4(clk, reset, sel);
input 	clk, reset;
output 	[2:0]sel;
reg 		[2:0]sel;

always@ (posedge clk or posedge reset)begin
	if(reset) begin
		sel <= 3'b0;
	end
	else if(sel == 3'b100) 
		sel <= 3'b0;
	else 
		sel <= sel + 1;
end
endmodule

module key_decode(sel, column, press, scan_code);
input 	[2:0]sel;  		//選第幾列
input 	[2:0]column;	//選第幾行
output 	press;
output 	[3:0]scan_code;
reg 		[3:0]scan_code;
reg 		press;

always@(sel or column) begin
	case(sel)
		3'b000:
			case(column)
				3'b011:  begin scan_code= 4'b0001; press = 1'b1; end  // 1
				3'b101:  begin scan_code= 4'b0010; press = 1'b1; end  // 2
				3'b110:  begin scan_code= 4'b0011; press = 1'b1; end  // 3
				default: begin scan_code= 4'b1111; press = 1'b0; end
			endcase
		3'b001:
			case(column)
				3'b011:  begin scan_code= 4'b0100; press = 1'b1; end  // 4
				3'b101:  begin scan_code= 4'b0101; press = 1'b1; end  // 5
				3'b110:  begin scan_code= 4'b0110; press = 1'b1; end  // 6
				default: begin scan_code= 4'b1111; press = 1'b0; end
			endcase
		3'b010:
			case(column)
				3'b011:  begin scan_code= 4'b0111; press = 1'b1; end  // 7
				3'b101:  begin scan_code= 4'b1000; press = 1'b1; end  // 8
				3'b110:  begin scan_code= 4'b1001; press = 1'b1; end  // 9
				default: begin scan_code= 4'b1111; press = 1'b0; end
			endcase
		3'b011:
			case(column)
				3'b101:  begin scan_code= 4'b0000; press = 1'b1; end // 0
				default: begin scan_code= 4'b1111; press = 1'b0; end
			endcase
		default:begin 
			scan_code= 4'b1111; press = 1'b0; end
		endcase
end
endmodule

module key_buf(clk, rst, press, scan_code, key_code);
input 	clk, rst, press;
input 	[3:0]scan_code;
output 	[3:0]key_code;
reg 		[3:0]key_code;

always@(posedge clk or posedge rst) begin
	if(rst)
		key_code = 4'b1111;  //initial value
	else
		key_code = (press) ? scan_code : key_code;
end
endmodule

module bcd_led(key_code, led);
input 	[3:0]key_code;
output 	[9:0]led;
reg 		[9:0]led;

always@(key_code) begin
	case(key_code)
		4'b0000: led = 10'b0000000001;  //0~9的顯示燈號
		4'b0001: led = 10'b0000000010;
		4'b0010: led = 10'b0000000100;
		4'b0011: led = 10'b0000001000;
		4'b0100: led = 10'b0000010000;
		4'b0101: led = 10'b0000100000;
		4'b0110: led = 10'b0001000000;
		4'b0111: led = 10'b0010000000;
		4'b1000: led = 10'b0100000000;
		4'b1001: led = 10'b1000000000;
		default: led = 10'b0000000000;
	endcase
end
endmodule
