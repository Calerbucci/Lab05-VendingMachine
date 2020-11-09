`timescale 1ns / 1ps

// `define INITIAL 2'd0
// `define DEPOSIT 2'd1
// `define BUY 2'd2
// `define CHANGE 2'd3

`define INITIAL 3'd0
`define DEPOSIT 3'd1
`define AMOUNT 3'd2
`define RELEASE 3'd3
`define CHANGE 3'd4


`define M 4'd10
`define A 4'd11
`define S 4'd12
`define K 4'd13
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

module lab05(clk, rst, money_5, money_10, cancel,check, count_down, LED, DIGIT, DISPLAY);
    input clk;
    input rst;
    input money_5;
    input money_10;
    input cancel;
    input check;
    input count_down;
    output reg [15:0] LED;
    output reg [3:0] DIGIT;
    output reg [6:0] DISPLAY;
    
    wire clk_div_13, clk_div_16, clk_div_27;
    wire five_bounce, five_pulse;
    wire ten_bounce, ten_pulse;
    wire check_bounce, check_pulse;
    wire count_bounce, count_pulse;
    wire cancel_bounce, cancel_pulse;
    
    reg one_pulse,one_pulse2; // state_clk
    wire state_clk;
    reg [3:0] AN0, AN1, AN2, AN3, next_AN0, next_AN1, next_AN2, next_AN3, temp_AN0, temp_AN1,temp_AN2,temp_AN3,max, next_max, max_temp,min, BALANCE;
    reg [3:0] value;
    reg [2:0] state, next_state, buy_A, next_buy_A; 
    reg [29:0] ms_count;
    reg [29:0] ms_count2;
    reg flag_remaining ;
    
    
    
    clock_divider #(13) cdiv1(.clk(clk), .clk_div(clk_div_13));
    clock_divider #(16) cdiv2(.clk(clk), .clk_div(clk_div_16));
    clock_divider #(27) cdiv3(.clk(clk), .clk_div(clk_div_27));

    //debounce
    debounce debounce1(.pb_debounced(five_bounce), .pb(money_5), .clk(clk_div_16));
    debounce debounce2(.pb_debounced(ten_bounce), .pb(money_10), .clk(clk_div_16));
    debounce debounce3(.pb_debounced(check_bounce), .pb(check), .clk(clk_div_16));
    debounce debounce4(.pb_debounced(count_bounce), .pb(count_down), .clk(clk_div_16));
    debounce debounce5(.pb_debounced(cancel_bounce), .pb(cancel), .clk(clk_div_16));

    
    //onepulse
    onepulse onepulse1(.pb_debounced(five_bounce), .clk(clk_div_16), .pb_1pulse(five_pulse));
    onepulse onepulse2(.pb_debounced(ten_bounce), .clk(clk_div_16), .pb_1pulse(ten_pulse));
    onepulse onepulse3(.pb_debounced(check_bounce), .clk(clk_div_16), .pb_1pulse(check_pulse));
    onepulse onepulse4(.pb_debounced(count_bounce), .clk(clk_div_16), .pb_1pulse(count_pulse));
    onepulse onepulse5(.pb_debounced(cancel_bounce), .clk(clk_div_16), .pb_1pulse(cancel_pulse));
     
    always@(posedge clk) begin
        one_pulse <= 0;
        if(ms_count == 18000) begin
            ms_count <= 0;
            one_pulse <= 1;
        end
        else if(five_pulse || ten_pulse || count_pulse || check_pulse || cancel_pulse || state != `DEPOSIT) begin 
            ms_count <= 0;
        end
        else begin
            ms_count <= ms_count + 1;
        end
    end
       
assign state_clk = (state == `INITIAL || state == `DEPOSIT || state == `AMOUNT) ? clk_div_16 : clk_div_27;
      
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            AN0 <= 4'd0;
            AN1 <= 4'd0;
            AN2 <= 4'd0;
            AN3 <= 4'd0;
            buy_A <= 4'd0;
            max <=0;
            state <= `INITIAL;
        end
        else begin
            AN0 <= next_AN0;
            AN1 <= next_AN1;
            AN2 <= next_AN2;
            AN3 <= next_AN3;
            buy_A <= next_buy_A;
            max <= next_max-1;            
            state <= next_state;
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
            `M: DISPLAY = 7'b0101010;   //M          //7'b0000011
            `A: DISPLAY = 7'b0100000;   //A          //7'b0000110
            `S: DISPLAY = 7'b1010010;   //S          //7'b0101111
            `K: DISPLAY = 7'b0001010;   //K          //7'b1110010
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
                LED = 16'h0000;
                next_buy_A = 3'd0;
            end
            `DEPOSIT: begin
                if(ten_pulse) begin
                    if(AN1 == 4'd5 && AN0 == 4'd0) begin
                        next_AN0 = AN0;
                        next_AN1 = AN1;
                        next_AN2 = AN2; 
                        next_AN3 = AN3;
                    end
                    else if(AN1 == 4'd4 && AN0 == 4'd5) begin
                        next_AN0 = 4'd0;
                        next_AN1 = 4'd5;
                        next_AN2 = 4'd9; 
                        next_AN3 = AN3;
                        flag_remaining = 1'b1;
                    end
                    else if(AN1 == 4'd4 && AN0 == 4'd0) begin
                        next_AN0 = 4'd0;
                        next_AN1 = 4'd5;
                        next_AN2 = 4'd9; 
                        next_AN3 = AN3;
                    end
                    else begin
                        next_AN0 = AN0;
                        next_AN1 = AN1 + 4'd1;
                        next_AN2 = (((AN1 + 4'd1) * 10) + AN0) / 5; 
                        next_AN3 = AN3;
                    end
                end
                else if(five_pulse) begin
                    if(AN1 == 4'd5 && AN0 == 4'd0) begin
                        next_AN0 = AN0;
                        next_AN1 = AN1;
                        next_AN2 = AN2;
                        next_AN3 = AN3;
                    end
                    else if(AN1 == 4'd4 && AN0 == 4'd5) begin
                        next_AN0 = 4'd0;
                        next_AN1 = 4'd5;
                        next_AN2 = 4'd9; 
                        next_AN3 = AN3;
                    end
                    else if(AN0 == 4'd5) begin
                        next_AN0 = 4'd0;
                        next_AN1 = AN1 + 4'd1;
                        next_AN2 = ((AN1 + 4'd1) * 10)/5; 
                        next_AN3 = AN3;
                    end
                    else begin
                        next_AN0 = AN0 + 4'd5;
                        next_AN1 = AN1;
                        next_AN2 = (((AN1  * 10) + (AN0 + 4'd5)))/5; 
                        next_AN3 = AN3;
                    end
                end
                else begin
                    next_AN0 = AN0;
                    next_AN1 = AN1;
                    next_AN2 = AN2;
                    next_AN3 = AN3;
                end

                if(cancel_pulse || one_pulse) begin 
                    next_state = `CHANGE;
                    temp_AN0 = AN0;
                    temp_AN1 = AN1;
                end
                else if(buy_A == 3'd1 ) begin 
                    next_state = `AMOUNT; 
                    temp_AN2 = AN2;               
                end
                else begin
                    next_state = state;
                end
                
               if(check_pulse) begin
                     if(AN1 >=1 || AN0 > 0) begin
                         next_buy_A = buy_A + 3'd1;                                          
                     end
                     else begin
                        next_buy_A = 3'd0;                   
                     end
                 end
             end
            `AMOUNT: begin                                 
                    next_max = temp_AN2;                   
                    max_temp = temp_AN2;
                    min = 4'd1;
                    
                    if(cancel_pulse) begin
                        next_state = `CHANGE;
                        temp_AN0 = AN0;
                        temp_AN1 = AN1;
                    end
                    else if(buy_A == 3'd2) begin
                        next_state = `RELEASE; 
                         temp_AN0 = AN0;
                         temp_AN1 = AN1;           
                         temp_AN2 = AN2;
                         temp_AN3 = AN3;         
                    end
                    else begin
                        next_state = state;
                    end
                    
                    if(count_pulse) begin                                       
                               if(max == 4'd1) begin
                                   // next_max = max_temp;
                                    next_AN2 = max_temp;
                                    next_buy_A = 4'd1;
                                end
                                else begin                                
                                   // next_max = max-1; 
                                    next_AN2 = max;
                                    next_buy_A = 4'd1;
                                end  
                             // next_AN2 = max;                            
                     end
                     if(check_pulse) begin
                            next_buy_A = buy_A + 3'd1;                        
                     end                  
            end
            `RELEASE: begin   
                       
                    BALANCE = ((AN1*10) + AN0)-(AN2*5);
                  
                        LED = 16'hFFFF;
                        next_AN0 = `K;
                        next_AN1 = `S;
                        next_AN2 = `A;
                        next_AN3 = `M;
                        temp_AN1= BALANCE%10;
                        temp_AN0= BALANCE/10;
//                        temp_AN0 = BALANCE%10; //AN0
//                        temp_AN1 = BALANCE/10;//AN1 - 4'd2                   
                                        
                next_state = `CHANGE;                                                                                                           
            end
            `CHANGE: begin
                LED = 16'h0000;
                next_AN0 = temp_AN0;
                next_AN1 = temp_AN1;
                next_AN2 = 4'd0;
                next_AN3 = 4'd0;
                if(temp_AN1 > 0) begin
                    temp_AN0 = temp_AN0;
                    temp_AN1 = temp_AN1 - 4'd1;
                    next_state = state;
                end
                else if(temp_AN0 > 0) begin
                    temp_AN0 = temp_AN0 - 4'd5;
                    temp_AN1 = 4'd0;
                    next_state = state;
                end
                else begin
                    temp_AN0 = temp_AN0;
                    temp_AN1 = temp_AN1;
                    next_state = `INITIAL;
                end
            end
       endcase
    end
    
endmodule
