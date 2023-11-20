module count_date(clk, reset, seg7_sel, enable, seg7_out, dpt_out);
	input		clk, reset, enable;  //pin W16, C16, AA15	
	output	[2:0]seg7_sel; 		//pin AB10, AB11, AA12 
	output	[6:0]seg7_out; 		//pin AB7, AA7, AB6, AB5, AA9, Y9, AB8 
	output	dpt_out;	         	//pinAA8
	wire		clk_count, clk_sel;  
	wire		[3:0]count_out, count5, count4, count3, count2, count1, count0;

	assign dpt_out = (seg7_sel == 3'b101 ) ? 0 :   //選擇年月日期間分隔點亮燈
				  	(seg7_sel == 3'b100 ) ? 0 :
					(seg7_sel == 3'b011 ) ? 1 :
					(seg7_sel == 3'b010 ) ? 0 :
					(seg7_sel == 3'b001 ) ? 1 : 0; 
	assign count_out = (seg7_sel == 3'b101 ) ? count5 :  //選擇年月日期輸出燈位
				   	(seg7_sel == 3'b100 ) ? count4 :
				   	(seg7_sel == 3'b011 ) ? count3 :
				   	(seg7_sel == 3'b010 ) ? count2 :
				   	(seg7_sel == 3'b001 ) ? count1 : count0; 
	freq_div #(22) m1(clk, reset, clk_count);  // slow
	freq_div #(15) m2(clk, reset, clk_sel);	 // high
	date	m3(clk_count, reset, enable, count2, count3, carryM, count4, count5, carryD);
	month	m4(clk_count, reset, carryD, count2, count3, carryM);
	year	m5(clk_count, reset, carryM, count0, count1);
	bcd_to_seg7	m6(count_out, seg7_out);
	seg7_select #(6) m7(clk_sel, reset, seg7_sel);
endmodule


module year(clk, reset, enable, count1, count0);
	input		clk, reset, enable;
	output	[3:0]count1, count0;
	reg		[3:0]count1, count0;

	always@ (posedge clk or posedge reset)begin
		if(reset) begin
			count1 = 4'b0010;
			count0 = 4'b0001;
		end
		else if(enable == 1'b1) begin
			if(count1 == 4'b0100 && count0 == 4'b1000)begin //2048
				count1 = 4'b0010;  //從2021年開始
				count0 = 4'b0001;
			end
			else if(count0 == 4'b1001) begin  //數到9進位
				count0 = 4'b0000;
				count1 = count1 + 1'b1;
			end
			else
				count0 = count0 + 1'b1;
		end
	end
endmodule


module month(clk, reset, enable, count1, count0, carryM);
	input		clk, reset, enable;
	output	[3:0]count1, count0;  //count1:十位數 , count0:個位數
	output 	carryM;
	reg		[3:0]count1, count0;
	wire 		carry = (count1 == 4'b0001 && count0 == 4'b0010) ? 1 : 0; 

	assign carryM = enable && carry;
	always@ (posedge clk or posedge reset)begin
		if(reset) begin
			count1 = 4'b0000;
			count0 = 4'b0001;
		end
		else if(enable == 1'b1) begin
			if(count1 == 4'b0001 && count0 == 4'b0010)begin  //12月到1月
				count1 = 4'b0000;
				count0 = 4'b0001;
			end
			else if(count0 == 4'b1001) begin  //9月進位到10月
				count0 = 4'b0000;
				count1 = count1 + 1'b1;
			end
			else begin
				count0 = count0 + 1'b1;
			end
		end
	end
endmodule


module date(clk, reset, enable, month1, month0, carryM, count1, count0, carryD);
	input		clk, reset, enable, carryM;
	input		[3:0]month1, month0;
	output	[3:0]count1, count0;
	output	carryD;
	reg		[3:0]count1, count0;
	reg		[1:0]year;
	wire		[3:0]day1; 
	wire		[3:0]day0;

	assign carryD = (count1 == day1 && count0 == day0) ? 1'b1 : 1'b0;
	assign day1 = (month1 == 4'b0000 && month0 == 4'b0010) ? 4'b0010 : 4'b0011;  
	assign day0 = (month1 == 4'b0000 && month0 == 4'b0001) ? 4'b0001:
					(month1 == 4'b0000 && month0 == 4'b0010 && year != 2'b11) ? 4'b1001 :  //2月29
					(month1 == 4'b0000 && month0 == 4'b0010 && year == 2'b11) ? 4'b1000 :  //2月28
					(month1 == 4'b0000 && month0 == 4'b0011) ? 4'b0001 :  //3月31
					(month1 == 4'b0000 && month0 == 4'b0100) ? 4'b0000 :  //4月30
					(month1 == 4'b0000 && month0 == 4'b0101) ? 4'b0001 :  //5月31
					(month1 == 4'b0000 && month0 == 4'b0110) ? 4'b0000 :  //6月30
					(month1 == 4'b0000 && month0 == 4'b0111) ? 4'b0001 :  //7月31
					(month1 == 4'b0000 && month0 == 4'b1000) ? 4'b0001 :  //8月31
					(month1 == 4'b0000 && month0 == 4'b1001) ? 4'b0000 :  //9月30
					(month1 == 4'b0000 && month0 == 4'b1010) ? 4'b0001 :  //10月31
					(month1 == 4'b0000 && month0 == 4'b1011) ? 4'b0000 : 4'b0001;  //11月30, 12月31
	always@ (posedge clk or posedge reset)begin
		if(reset) begin
			count1 = 4'b0000;  //1號
			count0 = 4'b0001;
			year = 2'b00;
		end
		else if(enable == 1'b1) begin
			if(carryM == 1)
				year = year + 1'b1;
			if(count1 == day1 && count0 == day0)begin  //2月28,29；其他月30,31 歸零
				count1 = 4'b0000;
				count0 = 4'b0001;
			end
			else if(count0 == 4'b1001) begin  //0 ~ 28,29,30,31前
				count0 = 4'b0000;
				count1 = count1 + 1'b1;
			end
			else begin
				count0 = count0 + 1'b1;
			end
		end
	end
endmodule


module seg7_select(clk, reset, seg7_sel);
	parameter	num_use = 6;	
	input			clk, reset;
	output		[2:0]seg7_sel;
	reg			[2:0]seg7_sel;
	always@ (posedge clk or posedge reset) begin
		if(reset == 1)
			seg7_sel = 3'b101;	//the rightmost one
		else
			if(seg7_sel == 6 - num_use)
				seg7_sel = 3'b101; 
			else
				seg7_sel = seg7_sel - 3'b001;  //shift left
	end
endmodule


module bcd_to_seg7(bcd_in, seg7);
	input		[3:0]bcd_in;
	output	[6:0]seg7;
	reg		[6:0]seg7;
	always@ (bcd_in)
		case(bcd_in)  //abcdefg
			4'b0000: seg7 = 7'b1111110;  //0
			4'b0001: seg7 = 7'b0110000;  //1
			4'b0010: seg7 = 7'b1101101;  //2
			4'b0011: seg7 = 7'b1111001;  //3
			4'b0100: seg7 = 7'b0110011;  //4
			4'b0101: seg7 = 7'b1011011;  //5
			4'b0110: seg7 = 7'b1011111;  //6
			4'b0111: seg7 = 7'b1110000;  //7
			4'b1000: seg7 = 7'b1111111;  //8
			4'b1001: seg7 = 7'b1111011;  //9
			default: seg7 = 7'b0000000; 
		endcase
endmodule


module freq_div(clk_in, reset, clk_out);
	parameter 	exp = 20;   
	input 		clk_in, reset;
	output 		clk_out;
	reg			[exp - 1:0]divider;
	integer 		i;

	assign clk_out = divider[exp - 1];
	always@ (posedge clk_in or posedge reset)begin
		if(reset)
			for(i = 0; i < exp; i = i + 1)
				divider[i] = 1'b0;
		else
			divider = divider + 1'b1;
	end
endmodule