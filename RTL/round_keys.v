`timescale 1ns / 1ps


module round_keys(
    input wire [3:0] sel,
    output wire [127:0] key
    
    );
    reg [127:0] keys [14:0] ;
    integer i = 0;
    initial begin
    $readmemh("round_keys.mem" ,keys);
    end 
    assign key = keys[sel];
    
endmodule
