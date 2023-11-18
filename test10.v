module 	test10(clk, row, red, green, column, sel, reset);
	input 		reset, clk;  //pin C16, W16      		
	input 		[2:0]column; //AA13,AB12,Y16			
	output		[7:0]red, row, green;	
	//row:				pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
	//column_red:		pin D7, D6, A9, C9, A8, C8, C11, B11
	//column_green:	pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14 
	output 		[2:0]sel; //AB10, AB11, AA12	
	wire 		clk_work, press, press_vaild;
	wire		[1:0]coll;
	wire 		[3:0]keycode, scancode;
	wire		[4:0]addr;
	wire		[2:0]idx;
	wire		[7:0]hor, ver;

	assign 	addr = { coll, idx };
	key_decode 	M1 (sel, column, press, scancode);
	key_buff 	M2 (clk_work, reset, press_valid, scancode, keycode);
	vaild		M3 (clk_work, reset, press, press_valid);
	count6  	M4 (clk_work, reset, sel);
	move		M5 (reset, coll[1], keycode, ver, hor, clk_work);
	
	freq_div#(14) 	M6 (clk, reset, clk_work);

	map		M7 (addr,green);
	idx		M8 (clk_work, reset, idx, row);
	mix		M9 (ver, hor, row, red);
	collision 	M10 (clk_work, reset, red, green, coll);
endmodule


module		map(addr,data);
	input		[4:0]addr;
	output reg 	[7:0]data;
	always@(addr)begin
		case(addr)
			5'd0  	:data=8'b1111_1101;//map1
			5'd1  	:data=8'b1000_0001;
			5'd2  	:data=8'b1011_1111;
			5'd3  	:data=8'b1000_0001;
			5'd4  	:data=8'b1111_1101;
			5'd5  	:data=8'b1001_0001;
			5'd6  	:data=8'b1100_0101;
			5'd7  	:data=8'b1111_1111;

			5'd8  	:data=8'b1111_1111;//map2
			5'd9  	:data=8'b1000_1001;
			5'd10	:data=8'b1010_0101;
			5'd11	:data=8'b1001_0101;
			5'd12	:data=8'b1101_0001;
			5'd13	:data=8'b1001_0111;
			5'd14	:data=8'b1111_0000;
			5'd15	:data=8'b1111_1111;
	
			5'd16 	:data=8'b00111100;
			5'd17 	:data=8'b01000010;
			5'd18	:data=8'b10100101;
			5'd19	:data=8'b10000001;
			5'd20	:data=8'b10100101;
			5'd21	:data=8'b10011001;
			5'd22	:data=8'b01000010;
			5'd23	:data=8'b00111100;
	
			5'd24 	:data=8'b1111_1111;
			5'd25 	:data=8'b1111_1111;
			5'd26	:data=8'b1111_1111;
			5'd27	:data=8'b1111_1111;
			5'd28	:data=8'b1111_1111;
			5'd29	:data=8'b1111_1111;
			5'd30	:data=8'b1111_1111;
			5'd31	:data=8'b1111_1111;
			default	:data=8'b0000_0000;
		endcase
	end
endmodule


module 	idx(clk, reset, idx, row);
	input		 reset, clk;
	output reg	[2:0]idx;
	output reg	[7:0]row;
	always@(posedge clk or posedge reset)begin
		if(reset) begin
			idx<=3'b000;
			row<=8'b1000_0000;
		end
		else begin
			idx<=idx+3'b001;
			row<={row[0],row[7:1]};
		end
	end
endmodule


module 	mix(ver, hor, row, red);
	input	[7:0]ver, hor, row;
	output 	[7:0]red;

	assign 	red=(row == ver)?hor:8'b0000_0000;

endmodule


module  collision(clk, reset, red, green, coll);
	input		clk, reset;
	input		[7:0]red, green;
	output reg 	[1:0]coll;
	always@(posedge clk or posedge reset)begin
		if(reset)
			coll<=1'b0;
		else if((red & green) != 8'b0)
			coll<=2'b11;
		else if((red | green) == 8'b11010001 && red == 8'b01000000)
			coll<=2'b01;
		else if((red | green) == 8'b11110001 && red == 8'b00000001)
			coll<=2'b10;
		else
			coll<=coll;
	end
endmodule


module key_decode(sel, column, press, scan_code);
	input[2:0]sel;
	input[2:0] column;
	output press;
	output[3:0] scan_code;
	reg[3:0] scan_code;
	reg press;
	always@(sel or column) begin
		case(sel)
			3'b000:
				case(column)
					3'b101: begin scan_code= 4'b0010; press = 1'b1; end // 2
					default: begin scan_code= 4'b1111; press = 1'b0; end
				endcase
			3'b001:
				case(column)
					3'b011: begin scan_code= 4'b0100; press = 1'b1; end // 4
					3'b110: begin scan_code= 4'b0110; press = 1'b1; end // 6
					default: begin scan_code= 4'b1111; press = 1'b0; end
				endcase
			3'b010:
				case(column)
					3'b101: begin scan_code= 4'b1000; press = 1'b1; end // 8
					default: begin scan_code= 4'b1111; press = 1'b0; end
				endcase
			default:
				begin scan_code= 4'b1111; press = 1'b0; end
		endcase
	end
endmodule


module key_buff(clk, rst, press_valid, scan_code, key_code);
	input clk, rst, press_valid;
	input[3:0] scan_code;
	output[3:0]key_code;
	reg[3:0]key_code;
	always@(posedge clk or posedge rst) begin
		if(rst)
			key_code= 4'b0000;// initial value
		else
			key_code= press_valid?scan_code:4'b0000;
	end
endmodule


module count6(clk_in, reset, sel);
	input clk_in, reset;
	output [2:0]sel;
	reg[2:0] sel;
	always@ (posedge clk_in or posedge reset)begin
		if(reset)
			sel = 3'b000;
		else if(sel==3'b101)begin
			sel = 3'b000;
		end
		else begin
			sel = sel+1'b1;
		end
	end
endmodule


module vaild (clk, rst, press, press_valid);
	input  press, clk, rst;
	output press_valid;
	reg [5:0] gg;
	assign press_valid = ~(gg[5] || (~press));
	always@(posedge clk or posedge rst)begin
		if(rst)
			gg <= 6'b0;
		else
			gg <= {gg[4:0], press};
	end
endmodule


module shift1(left, right, reset, unable, out, clk);
	input 		left, right, reset, clk, unable;
	output reg	[7:0]out;

	always@(posedge clk or posedge reset)begin
		if(reset)
			out<=8'b0000_0010;
		else if(unable) 		
 			out<=8'b0000_0000;
 		else if(left)
			out<=out<<1;
		else if(right)
			out<=out>>1;
 		else
  			out<=out;
	end
endmodule

module 	shift2(left, right, reset, unable, out, clk);
	input 		left, right, reset, clk, unable;
	output reg	[7:0]out;

	always@(posedge clk or posedge reset)begin
		if(reset)
			out<=8'b1000_0000;
		else if(unable) 		
 			out<=8'b0000_0000;
 		else if(left)
			out<=out<<1;
		else if(right)
			out<=out>>1;
 		else
	  		out<=out;
	end
endmodule


module	move(reset, unable, keycode, ver, hor, clk);
	input 		reset, clk, unable;
	input 		[3:0]keycode;
	output 		[7:0]ver, hor;
	wire		left, right, up, down;

	assign 	left   =~keycode[1]&  keycode[2];
	assign 	right =  keycode[1]&  keycode[2];
	assign 	up    =  keycode[1]& ~keycode[2];
	assign	down=  keycode[3];

	shift1 S1(left, right, reset, unable, hor, clk); //left & right
	shift2 S2(up, down, reset, unable, ver, clk); //up & down

endmodule


module freq_div(clk_in, reset, clk_out);
	parameter exp = 20;   
	input clk_in, reset;
	output clk_out;
	reg[exp-1:0] divider;
	integer i;
	assign clk_out= divider[exp-1];
	always@ (posedge clk_in or posedge reset)begin
		if(reset)
			for(i=0; i < exp; i=i+1)
				divider[i] = 1'b0;
		else
			divider = divider+ 1'b1;
	end
endmodule
