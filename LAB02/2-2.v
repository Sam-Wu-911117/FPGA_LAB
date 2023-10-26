//在七段顯示器上顯示 0-to-9 的上數計數器
module count_0_9_top(clk, reset, enable, seg7_sel, seg7_out, dpt_out, carry, led_com);
    input clk, reset, enable; //pin W16,C16,AA15
    output[2:0] seg7_sel; //pin AB10,AB11,AA12
    output[6:0] seg7_out; // pin AB7,AA7,AB6,AB5,AA9,Y9,AB8
    output dpt_out, carry, led_com;//pinAA8,E2,N20
    wire clk_work;
    wire[3:0] count_out;
    freq_div# (21)M1 (clk,reset,clk_work);
    count_0_9 M2 (clk_work,reset,enable,count_out,carry);
    bcd_to_seg7 M3 (count_out,seg7_out);
    assign seg7_sel = 3'b101;
    assign dpt_out = 1'b0; //七段顯示器右下角小點不亮
    assign led_com = 1'b1; //上排LED亮燈
endmodule

module freq_div(clk_in,reset,clk_out);
    parameter exp=20;
    input clk_in,reset;
    output clk_out;
    reg[exp-1:0] divider;
    integer i;
    assign clk_out=divider[exp-1];
    always@ (posedge clk_in or posedge reset)begin
        if(reset)
            for(i=0;i<exp;i=i+1)
                divider[i]=1'b0;
        else
            divider=divider+1'b1;
    end
endmodule

module count_0_9(clk, reset, enable, count_out, carry);
    input clk, reset, enable;
    output[3:0] count_out;
    output carry;
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
