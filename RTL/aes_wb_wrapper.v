`timescale 1ns / 1ps
module aes_wb_wrapper (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,    

    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire [31:0] in2,
    input  wire [31:0] in3, 

    output reg  [31:0] out0,
    output reg  [31:0] out1,
    output reg  [31:0] out2,
    output reg  [31:0] out3,

    output wire        ready
);

    wire        aes_done;
    wire [127:0] aes_ct;
    reg         aes_start;            
    wire [127:0] aes_pt = {in0, in1, in2, in3};

    // AES core
    wire aes_busy;
    AES_top AES_U (
        .clk(clk),
        .rst(rst),
        .start(aes_start),
        .plain_text_in(aes_pt),
        .statue(aes_done),
        .cyphertext_out(aes_ct),
        .busy(aes_busy)
    );

    reg busy;             
    reg start_latched;   

    assign ready = ~busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            aes_start <= 0;
            busy <= 0;
            start_latched <= 0;

            out0 <= 0;
            out1 <= 0;
            out2 <= 0;
            out3 <= 0;
        end else begin
            aes_start <= 0;
            if (start && busy)
                start_latched <= 1;
            if (!busy && (start || start_latched)) begin
                aes_start <= 1;
                busy <= 1;
                start_latched <= 0;
            end
            if (aes_done) begin
                {out3, out2, out1, out0} <= aes_ct;
                busy <= 0;
            end
        end
    end
endmodule
