module key_decode(sel, column, press, scan_code);
input		[2:0]sel;		//選第幾列
input		[2:0]column;	//選第幾行
output 	press;
output	[3:0]scan_code;
reg		[3:0]scan_code;
reg 		press;

always@(sel or column)begin
	case(sel)
		3'b000:
			case(column)
				3'b011: begin scan_code = 4'b0001; press = 1'b1;end   // 1
				3'b101: begin scan_code = 4'b0010; press = 1'b1;end   // 2
				//3'b110: begin scan_code = 4'b0011; press = 1'b1;end   // 3
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		3'b001:
			case(column)
				//3'b011: begin scan_code = 4'b0100; press = 1'b1;end   // 4
				//3'b101: begin scan_code = 4'b0101; press = 1'b1;end   // 5
				//3'b110: begin scan_code = 4'b0110; press = 1'b1;end   // 6
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase 
		3'b010:
			case(column)
				//3'b011: begin scan_code = 4'b0111; press = 1'b1;end   // 7
				3'b101: begin scan_code = 4'b1000; press = 1'b1;end   // 8
				3'b110: begin scan_code = 4'b1001; press = 1'b1;end   // 9
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		3'b011:
			case(column)
				3'b101: begin scan_code = 4'b0000; press = 1'b1;end   // 0
				default:begin scan_code = 4'b1111; press = 1'b0;end
			endcase
		default:begin
			scan_code = 4'b1111; press = 1'b0;end
	endcase
end
endmodule
