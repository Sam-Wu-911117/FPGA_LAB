//做出以下迷宮，需有倒數計時20秒的功能顯示於七段顯示器上，星星為起始位置，走到右上出口處即通關，撞牆或倒數20秒數完要顯示全版綠，通關時需顯示綠色笑臉，若撞牆、倒數完、順利通關皆須使倒數計時器暫停，迷宮及笑臉如下：
module  test8a(clk, row, red, green, column, sel, reset, seg7_out, dpt);
  input   	reset, clk; //pin C16, W16     
  input   	[2:0]column; //AA13,AB12,Y16	
  output  	[6:0]seg7_out; //pin AB7, AA7, AB6, AB5, AA9, Y9, AB8 
  output  	dpt; //pinAA8
  output  	[7:0]red, row, green;
  //row:				pin T22 ,R21 ,C6 ,B6 ,B5 ,A5 ,B7 ,A7
  //column_red:		pin D7, D6, A9, C9, A8, C8, C11, B11
  //column_green:	pin A10 ,B10 ,A13 ,A12 ,B12 ,D12 ,A15 ,A14 
  output  	[2:0]sel; //AB10, AB11, AA12  
  wire    	[3:0]count_out, count1, count0;
  wire   	clk_work, clk_count, press, press_vaild;
  wire  	[1:0]coll;
  wire   	[3:0]keycode, scancode;
  wire  	[4:0]addr;
  wire  	[2:0]idx;
  wire  	[7:0]hor, ver;

  assign count_out = (sel == 3'b101 ) ? count0 :
						(sel == 3'b100 ) ? count1 : 4'b1111;
  assign dpt = 1'b0;
  assign addr = {coll, idx};
  assign enable = (coll[1]) ? 1'b0 : 1'b1;

  key_decode  	M1(sel, column, press, scancode);
  key_buff  		M2(clk_work, reset, press_valid, scancode, keycode);
  vaild  			M3(clk_work, reset, press, press_valid);
  count6   		M4(clk_work, reset, sel);
  move  			M5(reset, coll[1], keycode, ver, hor, clk_work);  
  freq_div#(14)  M6(clk, reset, clk_work);
  freq_div#(23)  M7(clk, reset, clk_count);
  map  				M8(addr,green);
  idx  				M9(clk_work, reset, idx, row);
  mix  				M10(ver, hor, row, red);
  collision  		M11(clk_work, reset, red, green, coll, count1, count0);
  count_20_00_bcd c1(clk_count, reset, enable, count1, count0);
  bcd_to_seg7(count_out, seg7_out);
endmodule


module count_20_00_bcd(clk, reset, enable, count1, count0);
  input clk, reset, enable;
  output[3:0] count1, count0;
  reg[3:0] count1, count0;
  always@ (posedge clk or posedge reset)begin
  	if(reset) begin
		  count1 = 4'b0010;
		  count0 = 4'b0000;
	  end
	  else if(enable == 1'b1) begin
  		if (count1 == 4'b0000 && count0 == 4'b0000) begin
			  count1 = 4'b0010;
			  count0 = 4'b0000;
	    end
	    else if(count0 == 4'b0000) begin
		    count0 = 4'b1001;
		    count1 = count1 - 1'b1;
	    end
	    else
		    count0 = count0 - 1'b1;
	  end
  end
endmodule

module  map(addr,data);
  input  		[4:0]addr;
  output reg 	[7:0]data;

  always@(addr)begin
    case(addr)
      5'd0   :data=8'b1111_1011;//map
      5'd1   :data=8'b1000_1001;
      5'd2   :data=8'b1010_1101;
      5'd3   :data=8'b1010_1101;
      5'd4   :data=8'b1010_1101;
      5'd5   :data=8'b1010_0101;
      5'd6   :data=8'b1001_0001;
      5'd7   :data=8'b1101_1111;
 
      5'd16  :data=8'b00111100;
      5'd17  :data=8'b01000010;
      5'd18  :data=8'b10100101;
      5'd19  :data=8'b10000001;
      5'd20  :data=8'b10100101;
      5'd21  :data=8'b10011001;
      5'd22  :data=8'b01000010;
      5'd23  :data=8'b00111100;
 
      5'd24  :data=8'b1111_1111;
      5'd25  :data=8'b1111_1111;
      5'd26  :data=8'b1111_1111;
      5'd27  :data=8'b1111_1111;
      5'd28  :data=8'b1111_1111;
      5'd29  :data=8'b1111_1111;
      5'd30  :data=8'b1111_1111;
      5'd31  :data=8'b1111_1111;
      default :data=8'b0000_0000;
    endcase
  end
endmodule


module  idx(clk, reset, idx, row);
  input   reset, clk;
  output reg [2:0]idx;
  output reg [7:0]row;
  always@(posedge clk or posedge reset)begin
    if(reset) begin
      idx <= 3'b000;
      row <= 8'b1000_0000;
    end
    else begin
      idx <= idx + 3'b001;
      row <= {row[0],row[7:1]};
    end
  end
endmodule


module  mix(ver, hor, row, red);
  input  	[7:0]ver, hor, row;
  output  	[7:0]red;

  assign  red = (row == ver) ? hor : 8'b0000_0000;
endmodule


module  collision(clk, reset, red, green, coll, count1, count0);
  input  clk, reset;
  input  [7:0]red, green;
  input  [3:0] count1, count0;
  output reg  [1:0]coll;
  always@(posedge clk or posedge reset)begin
    if(reset)
      coll<=1'b0;
    else if((red & green) != 8'b0)
      coll<= 2'b11;
    else if(count1 == 4'b0000 && count0 == 4'b0000)
      coll<= 2'b11;
    else if((red | green) == 8'b11111111 && red == 8'b00000100)
      coll<= 2'b10;
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
      sel = sel + 1'b1;
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

module  shift1(left, right, reset, unable, out, clk);
  input   left, right, reset, clk, unable;
  output reg [7:0]out;

  always@(posedge clk or posedge reset)begin
    if(reset)
      out<=8'b0010_0000;
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

module  shift2(left, right, reset, unable, out, clk);
  input   left, right, reset, clk, unable;
  output reg [7:0]out;

  always@(posedge clk or posedge reset)begin
    if(reset)
      out<=8'b0000_0001;
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


module move(reset, unable, keycode, ver, hor, clk);
  input   reset, clk, unable;
  input   [3:0]keycode;
  output   [7:0]ver, hor;
  wire  left, right, up, down;

  assign  left   =~keycode[1]&  keycode[2];
  assign  right =  keycode[1]&  keycode[2];
  assign  up    =  keycode[1]&~keycode[2];
  assign down=  keycode[3];

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
  always@ (posedge clk_in or posedge reset) begin
    if(reset)
      for(i=0; i < exp; i=i+1)
        divider[i] = 1'b0;
    else
      divider = divider+ 1'b1;
  end
endmodule


module seg7_select(clk, reset, seg7_sel);
  parameter num_use= 6; 
  input  clk, reset;
  output[2:0] seg7_sel;
  reg [2:0] seg7_sel;
  always@ (posedge clk or posedge reset) begin
    if(reset == 1)
      seg7_sel = 3'b101; // the rightmost one
    else if(seg7_sel == 6 -num_use)
        seg7_sel = 3'b101; 
    else
      seg7_sel = seg7_sel-3'b001; // shift left
  end
endmodule

module bcd_to_seg7(bcd_in, seg7);
  input[3:0] bcd_in;
  output[6:0] seg7;
  reg[6:0] seg7;
  always@ (bcd_in)
    case(bcd_in) // abcdefg
      4'b0000: seg7 = 7'b1111110; // 0
      4'b0001: seg7 = 7'b0110000; // 1
      4'b0010: seg7 = 7'b1101101; // 2
      4'b0011: seg7 = 7'b1111001; // 3
      4'b0100: seg7 = 7'b0110011; // 4
      4'b0101: seg7 = 7'b1011011; // 5
      4'b0110: seg7 = 7'b1011111; // 6
      4'b0111: seg7 = 7'b1110000; // 7
      4'b1000: seg7 = 7'b1111111; // 8
      4'b1001: seg7 = 7'b1111011; // 9
      default: seg7 = 7'b0000000; 
    endcase
endmodule