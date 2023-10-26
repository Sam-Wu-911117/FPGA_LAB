//七段顯示器Decoder -解碼原理
module lab02_01(bcd_in, seg7_sel, seg7_out, dpt_out);
    input [3:0] bcd_in; // pinAA15,AA14,AB18,AA18
    output [2:0] seg7_sel; //pin AB10,AB11,AA12
    output [6:0] seg7_out;
    // pin AB7,AA7,AB6,AB5,AA9,Y9,AB8
    output dpt_out; // pinAA8
    bcd_to_seg7 M1 (bcd_in, seg7_out);
    assign seg7_sel = 3'b101; // Use the rightmost segment
    assign dpt_out= 1'b0;
endmodule

module bcd_to_seg7(bcd_in, seg7);
    input[3:0] bcd_in;
    output[6:0] seg7;
    reg[6:0] seg7;
    always@ (bcd_in)begin
        case(bcd_in) // abcdefg
            4'b0000: seg7 = 7'b1111110; // 0
            4'b0001: seg7 = 7'b0110000; // 1
            4'b0010: seg7 = 7'b1101101; // 2
            4'b0011: seg7 = 7'b1111001; // 3
            4'b0100: seg7 = 7'b0110011; // 4
            4'b0101: seg7 = 7'b1011011; // 5
            4'b0110: seg7 = 7'b1011111; // 6
            4'b0111: seg7 = 7'b1110010; // 7
            4'b1000: seg7 = 7'b1111111; // 8
            4'b1001: seg7 = 7'b1111011; // 9
            default: seg7 = 7'b0000000;
        endcase
    end
endmodule
