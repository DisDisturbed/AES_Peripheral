`timescale 1ns / 1ps
module add_round_key(
    input  wire [127:0] key_in,         
    input  wire [127:0] state_in,
    
    output wire [127:0] rk
);
wire [127:0] rk_temp;
    
assign rk_temp = state_in ^ key_in;
assign rk = rk_temp ;
endmodule
