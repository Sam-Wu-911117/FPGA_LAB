module test4(clk, reset, seg7_sel, enable, seg7_out, dpt_out, carry, led_com);
input clk, reset, enable; //pin W16, C16, AA15
output[2:0] seg7_sel; //pin AB10, AB11, AA12 
output[6:0] seg7_out;  // pin AB7, AA7, AB6, AB5, AA9, Y9, AB8
output dpt_out, led_com, carry;
wire clk_count, clk_sel;
wire[3:0] count_out,count5,count4,count3,count2, count1, count0;

assign led_com= 1'b1;

assign count_out = (seg7_sel == 3'b101) ? count0 : 
					(seg7_sel == 3'b100) ? count1 :
					(seg7_sel == 3'b011) ? count2 : 
					(seg7_sel == 3'b010) ? count3 : 
					(seg7_sel == 3'b001) ? count4 : count5;
							
assign dpt_out = (seg7_sel == 3'b101) ? 1'b0 : (seg7_sel == 3'b100)? 1'b0 :
				(seg7_sel == 3'b011) ? 1'b0 : 
				(seg7_sel == 3'b010) ? 1'b1 : 
				(seg7_sel == 3'b001) ? 1'b0 :1'b1;
freq_div #(21) (clk, reset, clk_count); // slow
freq_div #(17) (clk, reset, clk_sel); // high
count_0_9(clk_count, reset, enable, count5);
count87__00_bcd(clk_count, reset, enable, count4, count3);
count_000_111_bcd(clk_count, reset, enable, count2,count1,count0);
bcd_to_seg7 (count_out, seg7_out);
seg7_select #(6) (clk_sel, reset, seg7_sel);
endmodule

//0~9
module count_0_9(clk, reset, enable, count_out);
    input clk, reset, enable;
    output[3:0] count_out;
    //output carry;
    reg[3:0] count_out;
    assign carry = (count_out== 4'b1001) ? 1 : 0;
    always@ (posedge clk or posedge reset)begin
        if(reset)
            count_out= 4'b0;
        else if(enable == 1) begin
            if(count_out == 4'b1001)
                count_out <= 0;//count_out back to 0
            else
                count_out <= count_out+1;//count_out add 1
        end
    end
endmodule

//87~00
module count87__00_bcd(clk, reset, enable, count1, count0);
input 	clk, reset, enable;
output 	[3:0] count1, count0;  //count0:個位數 count1:十位數
reg		[3:0]count1, count0;
//output 	carry;
//wire carry = (count1 == 4'b000 && count0 == 4'b0000) ? 1 : 0;  //00
always@ (posedge clk or posedge reset)begin
if(reset) begin
count1 = 4'b1000;  //87
count0 = 4'b0111;
end
else if(enable == 1'b1) begin
	if (count1 == 4'b0101 && count0 == 4'b1001) begin  //87
	count1 = 4'b1000;  //87
    count0 = 4'b0111;
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

///000~111
module count_000_111_bcd(clk, reset, enable, count2,count1, count0, carry);
input 	clk, reset, enable;
output 	[3:0]count2,count1, count0;
reg 		[3:0]count2,count1, count0;
//output 	carry;
//wire 	carry;
//assign carry = (count2==4'b0001 &count1 == 4'b0001 & count0 == 4'b0001) ? 1 : 0;  //count0:個位數 count1:十位數
always@ (posedge clk or posedge reset)begin
if(reset) begin
count2 <= 4'b0000;    
count1 <= 4'b0000;
count0 <= 4'b0000;
end
else if(enable == 1'b1) begin
	if (count2==4'b0001 &count1 == 4'b0001 & count0 == 4'b0001) begin  //23
    count2 = 4'b0000;
	count1 = 4'b0000;  //00
	count0 = 4'b0000;
	end
	else if(count0 == 4'b1001) begin
	count0 = 4'b0000;
	count1 = count1 + 1'b1;
	end
    else if(count1 == 4'b1001)begin
    count1 = 4'b0000;
    count2 = count2+1'b1;
    end
	else
	count0 = count0 + 1'b1;
	end
end
endmodule

module seg7_select(clk, reset, seg7_sel);
parameter num_use = 6;	//設參數
input	clk, reset;
output [2:0]seg7_sel;
reg [2:0]seg7_sel;
always@ (posedge clk or posedge reset) begin
if(reset == 1)	
seg7_sel = 3'b101;  //the rightmost one
else
	if(seg7_sel == 6 - num_use)
	seg7_sel = 3'b101; 
	else
	seg7_sel = seg7_sel - 3'b001;  //shift left
end
endmodule

module bcd_to_seg7(bcd_in, seg7);
input [3:0]bcd_in;
output [6:0]seg7;
reg[6:0] seg7;
always@ (bcd_in)begin
case(bcd_in)  //abcdefg
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
end
endmodule

module freq_div(clk_in, reset, clk_out);
parameter	exp = 20;   
input 		clk_in, reset;
output 		clk_out;
reg 			[exp - 1:0]divider;
integer 		i;
assign clk_out = divider[exp - 1];
always@ (posedge clk_in or posedge reset)	//正緣觸發
begin
if(reset)
for(i = 0; i < exp; i = i + 1) divider[i] = 1'b0;
else
divider = divider + 1'b1;
end
endmodule