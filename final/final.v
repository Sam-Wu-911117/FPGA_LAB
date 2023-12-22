module final(clk, row, red, green, column, sel, reset, seg7_out,enable);

input 	reset, clk,enable;  // pin C16,W16(10MHz),AA15   		
input 	[2:0]column;	//AA13,AB12,Y16	
output	[7:0]row,red,green;		
//red:D7,D6,A9,C9.A8,C8,C11,B11
//green:A10,B10,A13,A12,B12,D12,A15,A14
//row:T22,R21,C6,B6,B5,A5,B7,A7
output  [2:0]sel;		//AB10,AB11,AA12	
output  [6:0]seg7_out; // pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
wire 		ck, press, press_vaild, coll1, coll2,clk_shift,clk_scan;
wire	[3:0]keycode, scancode, addr1, addr2;
//wire	[2:0]idx;
wire  [6:0]idx,idx_cnt;
wire	[7:0]hor, ver;
wire  [3:0] count_out, count5, count4, count3, count2, count1, count0;
//assign 	addr1 = { coll1, idx };
//assign 	addr2 = { coll2, idx };
key_decode 	M1 (sel, column, press, scancode);
key_buf 	M2 (ck, reset, press_valid, scancode, keycode);
vaild		M3 (ck, reset, press, press_valid);
count6  	M4 (ck, reset, sel);

move		M5 (reset, coll1, keycode, ver1, hor1, ck);
	
freq_div#(14) M7 (clk, reset, ck);
freq_div#(22) M8 (clk, reset, clk_shift);
freq_div#(12) M9 (clk, reset, clk_scan);
freq_div #(15) (clk,reset,clk_sel);
//rom_char1		M7 (idx_cnt,green1);
//rom_char2		M77 (idx_cnt,green2);
idx_gen  M10(clk_shift, reset, idx); 
row_gen  M11(clk_scan, reset, idx, row, idx_cnt);

//idx		M8 (ck, reset, idx, row);

mix		M12 (ver1, hor1, row, red1);

collision 	M14 (ck, reset, red1, green1, coll);

map M16 (idx_cnt,green);

bcd_to_seg7(count_out,seg7_out);
seg7_select #(6) (clk_sel, reset, seg7_sel);
endmodule
