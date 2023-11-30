module final_project (clk, row, red, green, column, sel, reset);
input clk,reset;    // pin W16,C16 		
input 	[2:0]column;	//AA13,AB12,Y16	
output	[7:0]red, row, green;	
		// red:D7,D6,A9,C9,A8,C8,C11,B11
		//row:T22,R21,C6,B6,B5,A5,B7,A7
		//green:A10,B10,A13,A12,B12,D12,A15,A14
output 	[2:0]sel;		//AB10,AB11,AA12	
wire 	ck, press, press_vaild, coll;
wire 	[3:0]keycode, scancode, addr;
wire	[2:0]idx;
wire	[7:0]hor, ver;
assign 	addr = { coll, idx };


freq_div#(14) 	M6 (clk, reset, ck);
endmodule

module freq_div(clk_in, reset, clk_out);
parameter exp = 20;   
input clk_in, reset;
output clk_out;
reg[exp-1:0] divider;
integer i;
assign clk_out= divider[exp-1];
always@ (posedge clk_in or posedge reset)	//正緣觸發
begin
if(reset)
for(i=0; i < exp; i=i+1)
divider[i] = 1'b0;
else
divider = divider+ 1'b1;
end
endmodule