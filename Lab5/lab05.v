`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/19 21:26:26
// Design Name: 
// Module Name: lab05
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab05(clk, rst, money_5, money_10, cancel, check, count_down, LED, DIGIT, DISPLAY);
    input clk;
    input rst;
    input money_5;
    input money_10;
    input cancel;
    input check;
    input count_down;
    output reg[15:0] LED;
    output [3:0] DIGIT;
    output [6:0] DISPLAY;
    reg[3:0] BCD3,BCD2,BCD1,BCD0;
    
    //clock
    wire clk26, clk16, clk13;
    ClockDivider #(.n(13)) clock_13(clk,clk13);
    ClockDivider #(.n(16)) clock_16(clk,clk16);
    ClockDivider #(.n(26)) clock_26(clk,clk26);
    
    //debounce
    wire money_5_d, money_10_d, cancel_d, check_d, count_d;
    debounce m5(money_5_d, money_5, clk16);
    debounce m10(money_10_d, money_10, clk16);
    debounce c(cancel_d, cancel, clk16);
    debounce cdeb(check_d, check, clk16);
    debounce countDeb(count_d, count_down, clk16);
    
    //one pulse
    wire money_5_one, money_10_one, cancel_one, check_one, count_one;
    onepulse m5one(money_5_one, clk16, money_5_d);
    onepulse m10one(money_10_one, clk16, money_10_d);
    onepulse c_one(cancel_one, clk16, cancel_d);
    onepulse cDone(check_one, clk1, check_d);
    onepulse countone(count_one, clk16, count_d);
    
    //7-SEG
    LED7SEG seven(DIGIT, DISPLAY, clk13, BCD3, BCD2, BCD1, BCD0);
    
    //sequential
    reg[3:0] next_BCD3,next_BCD2,next_BCD1,next_BCD0;
    reg [15:0] next_led;
    parameter INITIAL = 3'b000, DEPOSIT = 3'b001, RELEASE = 3'b010, CHANGE = 3'b011, AMOUNT = 3'b100;
    reg[2:0] state,next_state;
    reg[12:0] count,next_count;
    reg[8:0] bcd_delay,next_delay;
    reg[6:0] balance, next_balance;
    wire clk_select;
    assign clk_select = (state == INITIAL || state == DEPOSIT)?clk16:clk26;
    always @(posedge clk_select or posedge rst)begin
        if(rst)begin
            state <= INITIAL;
            BCD0 <= 4'b0000;
            BCD1 <= 4'b0000;
            BCD2 <= 4'b0000;
            BCD3 <= 4'b0000;
            next_led <= 16'b0;
            count <= 13'd0;
            bcd_delay<= 9'b0;
            balance <= 7'd0;
        end
        else begin
            state <= next_state;
            BCD0 <= next_BCD0;
            BCD1 <= next_BCD1;
            BCD2 <= next_BCD2;
            BCD3 <= next_BCD3;
            LED <= next_led;
            count <= next_count;
            bcd_delay<= next_delay;
            balance <= next_balance;
        end
    end
    
    //FSM
    always @(*)begin
        next_BCD0 = BCD0;
        next_BCD1 = BCD1;
        next_BCD2 = BCD2;
        next_BCD3 = BCD3;
        next_led <= LED;
        next_delay = bcd_delay;
        next_balance = balance;
        next_state = state;
        next_count = count;
        case(state)
            INITIAL:begin
                next_BCD0 = 4'd0;
                next_BCD1 = 4'd0;
                next_BCD2 = 4'd0;
                next_BCD3 = 4'd0;
                next_led = LED;
                next_state = DEPOSIT;
                next_balance = 7'd0;
                next_delay = 9'd0;
            end
            DEPOSIT:begin
                next_count = count+1;
                next_state = DEPOSIT;
                if(cancel_one)begin
                    next_count = 13'd0;
                    next_BCD2 = 4'd0;
                    next_BCD3 = 4'd0;
                    next_led = 16'b0;
                    next_state = CHANGE;
                end
                else if(money_5_one)begin
                    next_count = 13'd0;
                    if(BCD0 == 0 && BCD1 == 5) begin
                          next_BCD1 = BCD1;
                          next_BCD0 = BCD0;
                          next_BCD2 = 4'd9;
                          next_BCD3 = 4'd0;
                    end                   
                    else if(BCD0 == 4'd5)begin
                        if(BCD1<4'd5)begin
                            next_BCD1 = BCD1+1;
                            next_BCD0 = 4'd0;
                            next_BCD2 = (BCD1*10 + BCD0) / 5;
                            next_BCD3 = 4'd0;       
                        end
                    end 
                    else begin
                        next_BCD0 = 4'd5;
                    end
                end
                else if(money_10_one)begin
                    next_count = 13'd0;
                    if(BCD0 == 0 && BCD1 == 5) begin
                         next_BCD1 = BCD1;
                         next_BCD0 = BCD0;
                         next_BCD2 = 4'd9;
                         next_BCD3 = 4'd0;
                    end
                    if(BCD1<5)begin
                       next_BCD1 = BCD1+4'd1;    
                       next_BCD2 = (BCD1*10 + BCD0) / 5;
                       next_BCD3 = 4'd0;                   
                    end
                end 
                else if(check_one) begin
                     next_count = 13'd0;
                     next_BCD1 = BCD1;
                     next_BCD0 = BCD0;
                     next_BCD3 = BCD3;
                     next_BCD2 = BCD2;
                     next_led = 16'b0;
                     next_state = AMOUNT;                   
                end
                else if(count == 13'b1_1111_1111_1111)begin
                    next_count = 13'd0;
                    next_BCD2 = 4'd0;
                    next_BCD3 = 4'd0;
                    next_led = 16'b0;
                    next_state = CHANGE;
                end
            end
            AMOUNT : begin
                     next_count = 13'd0;
                     next_BCD1 = BCD1;
                     next_BCD0 = BCD0;
                     next_BCD3 = BCD3;
                     next_BCD2 = BCD2;
                     next_led = 16'b0;
                     
                     if(count_one) begin
                        next_BCD0 = BCD0;
                        next_BCD1 = BCD1;
                        next_BCD2 = BCD2-1;
                        next_BCD3 = 4'd0;
                     end
                     else if(cancel_one) begin
                         next_count = 13'd0;
                         next_BCD2 = 4'd0;
                         next_BCD3 = 4'd0;
                         next_state = CHANGE;
                     end
                     else if(check_one) begin
                         next_BCD1 = BCD1;
                         next_BCD0 = BCD0;
                         next_BCD3 = BCD3;
                         next_BCD2 = BCD2;
                         next_state = RELEASE;
                     end
            end
            RELEASE:begin
                    next_balance = (BCD1*10+BCD0) - (BCD3*10+BCD2);
                    next_led = 16'b1;
                    next_BCD3 = 4'd10;
                    next_BCD2 = 4'd11;
                    next_BCD1 = 4'd12;
                    next_BCD0 = 4'd13;
                   next_state = CHANGE;
            end
            CHANGE:begin
                if(BCD3!=0 || BCD2!=0)begin
                    next_BCD3 = 4'd0;
                    next_BCD2 = 4'd0;
                    next_BCD1 = balance/10;
                    next_BCD0 = balance - (balance/10)*10;
                    next_state = CHANGE;
                end
                else if(BCD1>0)begin
                    next_BCD1 = BCD1 - 4'd1;
                    next_state = CHANGE;
                end
                else if(BCD0>0)begin
                    next_BCD0 = BCD0 - 4'd5;
                    next_state = CHANGE;
                end
                else begin
                    next_BCD0 = 4'd0;
                    next_BCD1 = 4'd0;
                    next_BCD2 = 4'd0;
                    next_BCD3 = 4'd0;
                    next_state = INITIAL;
                end
            end
        endcase
   end
endmodule
