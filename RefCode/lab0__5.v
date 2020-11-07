`timescale 1ns / 1ps

`define INITIAL 2'd0
`define DEPOSIT 2'd1
`define BUY 2'd2
`define CHANGE 2'd3

`define B 4'd10
`define E 4'd11
`define R 4'd12
`define J 4'd13
`define U 4'd14
`define S 4'd15

module clock_divider(clk, clk_div);
    parameter n = 13;
    input clk;
    output clk_div;
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
    
endmodule

module debounce (pb_debounced, pb, clk);
    output pb_debounced; // output after being debounced
    input pb; // input from a pushbutton
    input clk;
    reg [3:0] shift_reg; // use shift_reg to filter the bounce
    
    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule

module onepulse (pb_debounced, clk, pb_1pulse);
    input pb_debounced;
    input clk;
    output pb_1pulse;
    reg pb_1pulse;
    reg pb_debounced_delay;
    always @(posedge clk) begin
        if (pb_debounced == 1'b1 & pb_debounced_delay == 1'b0)
            pb_1pulse <= 1'b1;
        else
            pb_1pulse <= 1'b0;
        pb_debounced_delay <= pb_debounced;
    end
endmodule

module lab05(clk, rst, money_5, money_10, cancel, drink_A, drink_B, drop_money, enough_A, enough_B, DIGIT, DISPLAY);
    input clk;
    input rst;
    input money_5;
    input money_10;
    input cancel;
    input drink_A;
    input drink_B;
    output reg[9:0] drop_money;
    output reg enough_A;
    output reg enough_B;
    output reg [3:0] DIGIT;
    output reg [6:0] DISPLAY;
    
    wire clk_div_13, clk_div_16, clk_div_26;
    wire five_bounce, five_pulse;
    wire ten_bounce, ten_pulse;
    wire drinkA_bounce, drinkA_pulse;
    wire drinkB_bounce, drinkB_pulse;
    wire cancel_bounce, cancel_pulse;
    
    reg state_clk, one_pulse;
    reg [3:0] AN0, AN1, AN2, AN3, next_AN0, next_AN1, next_AN2, next_AN3, temp_AN0, temp_AN1;
    reg [3:0] value;
    reg [1:0] state, next_state, buy_A, next_buy_A, buy_B, next_buy_B;
    reg [9:0] next_drop_money;
    reg [29:0] ms_count;
    
    clock_divider #(13) cdiv1(.clk(clk), .clk_div(clk_div_13));
    clock_divider #(16) cdiv2(.clk(clk), .clk_div(clk_div_16));
    clock_divider #(26) cdiv3(.clk(clk), .clk_div(clk_div_26));
    
    debounce debounce1(.pb_debounced(five_bounce), .pb(money_5), .clk(clk_div_16));
    debounce debounce2(.pb_debounced(ten_bounce), .pb(money_10), .clk(clk_div_16));
    debounce debounce3(.pb_debounced(drinkA_bounce), .pb(drink_A), .clk(clk_div_16));
    debounce debounce4(.pb_debounced(drinkB_bounce), .pb(drink_B), .clk(clk_div_16));
    debounce debounce5(.pb_debounced(cancel_bounce), .pb(cancel), .clk(clk_div_16));
    
    onepulse onepulse1(.pb_debounced(five_bounce), .clk(clk_div_16), .pb_1pulse(five_pulse));
    onepulse onepulse2(.pb_debounced(ten_bounce), .clk(clk_div_16), .pb_1pulse(ten_pulse));
    onepulse onepulse3(.pb_debounced(drinkA_bounce), .clk(clk_div_16), .pb_1pulse(drinkA_pulse));
    onepulse onepulse4(.pb_debounced(drinkB_bounce), .clk(clk_div_16), .pb_1pulse(drinkB_pulse));
    onepulse onepulse5(.pb_debounced(cancel_bounce), .clk(clk_div_16), .pb_1pulse(cancel_pulse));
     
    always@(posedge clk) begin
        one_pulse <= 0;
        if(ms_count == 18000) begin
            ms_count <= 0;
            one_pulse <= 1;
        end
        else if(five_pulse || ten_pulse || drinkA_pulse || drinkB_pulse || cancel_pulse || state != `DEPOSIT) begin
            ms_count <= 0;
        end
        else begin
            ms_count <= ms_count + 1;
        end
    end
    
    always@(posedge clk) begin
        if(state == `INITIAL) begin
            state_clk = clk_div_16;
        end
        else begin
            if(state == `DEPOSIT) begin
                state_clk = clk_div_16;
            end 
            else begin
                if(state == `BUY) begin
                    state_clk = clk_div_26;
                end
                else begin
                    if(state == `CHANGE) begin
                        state_clk = clk_div_26;
                    end
                end
            end
        end
    end
    
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            AN0 <= 4'd0;
            AN1 <= 4'd0;
            AN2 <= 4'd0;
            AN3 <= 4'd0;
            buy_A <= 4'd0;
            buy_B <= 4'd0;
            state <= `INITIAL;
        end
        else begin
            AN0 <= next_AN0;
            AN1 <= next_AN1;
            AN2 <= next_AN2;
            AN3 <= next_AN3;
            buy_A <= next_buy_A;
            buy_B <= next_buy_B;
            state <= next_state;
        end
    end
    
    always@(posedge clk_div_26) begin
        if(rst) begin
            drop_money <= {10{1'b0}};
        end
        else begin
            drop_money <= next_drop_money;
        end
    end
    
    always@(posedge clk_div_13) begin
        case(DIGIT)
            4'b1110: begin
                value = {AN2[3], AN2[2], AN2[1], AN2[0]};
                DIGIT = 4'b1101;
            end
            4'b1101: begin
                value = {AN3[3], AN3[2], AN3[1], AN3[0]};
                DIGIT = 4'b1011;
            end
            4'b1011: begin
                value = {AN0[3], AN0[2], AN0[1], AN0[0]};
                DIGIT = 4'b0111;
            end
            4'b0111: begin
                value = {AN1[3], AN1[2], AN1[1], AN1[0]};
                DIGIT = 4'b1110;
            end
            default: begin
                value = {AN0[3], AN0[2], AN0[1], AN0[0]};
                DIGIT = 4'b1110;
            end
        endcase
    end
    
    always@(posedge clk_div_13) begin
        case(value)
            4'd0: DISPLAY = 7'b1000000;
            4'd1: DISPLAY = 7'b1111001;
            4'd2: DISPLAY = 7'b0100100;
            4'd3: DISPLAY = 7'b0110000;
            4'd4: DISPLAY = 7'b0011001;
            4'd5: DISPLAY = 7'b0010010;
            4'd6: DISPLAY = 7'b0000010;
            4'd7: DISPLAY = 7'b1111000;
            4'd8: DISPLAY = 7'b0000000;
            4'd9: DISPLAY = 7'b0010000;
            `B: DISPLAY = 7'b0000011;
            `E: DISPLAY = 7'b0000110;
            `R: DISPLAY = 7'b0101111;
            `J: DISPLAY = 7'b1110010;
            `U: DISPLAY = 7'b1100011;
            `S: DISPLAY = 7'b1010010;
            default: DISPLAY = 7'b1111111;
       endcase
    end
    
    always@(posedge state_clk) begin
        case(state)
            `INITIAL: begin
                next_AN0 = 4'd0;
                next_AN1 = 4'd0;
                next_AN2 = 4'd0;
                next_AN3 = 4'd0;
                next_state = `DEPOSIT;
                enough_A = 1'd0;
                enough_B = 1'd0;
                next_buy_A = 2'd0;
                next_buy_B = 2'd0;
                next_drop_money = {10{1'b0}};
            end
            `DEPOSIT: begin
                if(ten_pulse) begin
                    if(AN1 == 4'd9 && AN0 == 4'd5) begin
                        next_AN0 = AN0;
                        next_AN1 = AN1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                    else if(AN1 == 4'd9 && AN0 == 4'd0) begin
                        next_AN0 = 4'd5;
                        next_AN1 = AN1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                    else begin
                        next_AN0 = AN0;
                        next_AN1 = AN1 + 4'd1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                end
                else if(five_pulse) begin
                    if(AN1 == 4'd9 && AN0 == 4'd5) begin
                        next_AN0 = AN0;
                        next_AN1 = AN1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                    else if(AN0 == 4'd5) begin
                        next_AN0 = 4'd0;
                        next_AN1 = AN1 + 4'd1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                    else begin
                        next_AN0 = AN0 + 4'd5;
                        next_AN1 = AN1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                end
                else begin
                    next_AN0 = AN0;
                    next_AN1 = AN1;
                    next_AN2 = AN2;
                    next_AN3 = AN3;
                end

                if(AN1 >= 4'd3 || (AN1 >= 4'd2 && AN0 >= 4'd5)) begin
                    enough_A = 1'd1;
                    enough_B = 1'd1;
                end
                else if(AN1 >= 4'd2 && AN0 >= 4'd0)begin
                    enough_A = 1'd1;
                    enough_B = 1'd0;
                end
                else begin
                    enough_A = 1'd0;
                    enough_B = 1'd0;
                end
                
                if(cancel_pulse || one_pulse) begin
                    next_state = `CHANGE;
                    enough_A = 1'd0;
                    enough_B = 1'd0;
                    temp_AN0 = AN0;
                    temp_AN1 = AN1;
                end
                else if(buy_A == 2'd2 || buy_B == 2'd2) begin
                    next_state = `BUY;
                    enough_A = 1'd0;
                    enough_B = 1'd0;
                end
                else begin
                    next_state = state;
                    enough_A = enough_A;
                    enough_B = enough_B;
                end
                
                if(drinkA_pulse) begin
                    next_AN2 = 4'd0;
                    next_AN3 = 4'd2;
                    if(enough_A) begin
                        next_buy_A = buy_A + 2'd1;
                        next_buy_B = 2'd0;
                    end
                    else begin
                        next_buy_A = 2'd1;
                        next_buy_B = 2'd0;
                    end
                end
                else begin
                    if(drinkB_pulse) begin
                        next_AN2 = 4'd5;
                        next_AN3 = 4'd2;
                        if(enough_B) begin
                            next_buy_A = 2'd0;
                            next_buy_B = buy_B + 2'd1;
                        end
                        else begin
                            next_buy_A = 2'd0;
                            next_buy_B = 2'd1;
                        end
                    end
                    else begin
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                        next_buy_A = buy_A;
                        next_buy_B = buy_B;
                    end
                end
                
                next_drop_money = {10{1'b0}};
            end
            `BUY: begin
                if(buy_A == 2'd2) begin
                    next_AN0 = `R;
                    next_AN1 = `E;
                    next_AN2 = `E;
                    next_AN3 = `B;
                    temp_AN0 = AN0;
                    temp_AN1 = AN1 - 4'd2;
                end
                else if(buy_B == 2'd2) begin
                    next_AN0 = 4'd8;
                    next_AN1 = `S;
                    next_AN2 = `U;
                    next_AN3 = `J;
                    if(AN0 == 4'd0) begin
                        temp_AN0 = 4'd5;
                        temp_AN1 = AN1 - 4'd3;
                    end
                    else begin
                        temp_AN0 = 4'd0;
                        temp_AN1 = AN1 - 4'd2;
                    end
                end
                next_state = `CHANGE;
            end
            `CHANGE: begin
                next_AN0 = temp_AN0;
                next_AN1 = temp_AN1;
                next_AN2 = 4'd0;
                next_AN3 = 4'd0;
                if(temp_AN1 > 0) begin
                    temp_AN0 = temp_AN0;
                    temp_AN1 = temp_AN1 - 4'd1;
                    next_drop_money = {10{1'd1}};
                    next_state = state;
                end
                else if(temp_AN0 > 0) begin
                    temp_AN0 = temp_AN0 - 4'd5;
                    temp_AN1 = 4'd0;
                    next_drop_money = 10'b1111100000;
                    next_state = state;
                end
                else begin
                    temp_AN0 = temp_AN0;
                    temp_AN1 = temp_AN1;
                    next_drop_money = {10{1'd0}};
                    next_state = `INITIAL;
                end
            end
       endcase
    end
    
endmodule
