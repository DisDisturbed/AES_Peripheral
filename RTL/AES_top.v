`timescale 1ns / 1ps
module AES_top(
    input  wire   clk,
    input  wire  rst,
    input  wire  start,         
    input  wire [127:0] plain_text_in,

    output reg   statue,          
    output reg  [127:0] cyphertext_out,
    output wire busy             
);

    reg [127:0] state_reg;
    reg [4:0]   count;
    wire [127:0] k_round_0;
    wire [127:0] k_loop;

    round_keys rk_k0(
        .sel(4'd0),
        .key(k_round_0)
    );

    round_keys rk_loop(
        .sel(count[3:0]),
        .key(k_loop)
    );

    wire [127:0] round_input = state_reg;

    wire [127:0] sb_out;
    genvar i;
    generate
        for(i=0; i<16; i=i+1) begin : sbox_l
            aes_sbox sb_inst(
                .a(round_input[i*8 + 7 : i*8]),
                .c(sb_out[i*8 + 7 : i*8])
            );
        end
    endgenerate

    wire [127:0] sr_out;
    row_shift rs1(.in(sb_out), .shifted(sr_out));

    wire [127:0] mc_out;
    mixcolumns mxc(.state_in(sr_out), .state_out(mc_out));

    wire [127:0] mix_mux_out;
    assign mix_mux_out = (count == 14) ? sr_out : mc_out;

    wire [127:0] next_state_comb;
    add_round_key addrk_step(
        .key_in(k_loop),
        .state_in(mix_mux_out),
        .rk(next_state_comb)
    );

    assign busy = (count != 0); 

    reg statue_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            state_reg <= 0;
            cyphertext_out <= 0;
            statue <= 0;
            statue_next <= 0;
        end else begin
            statue <= statue_next; 
            statue_next <= 0;

            if (count == 0) begin
                if (start) begin
                    state_reg <= plain_text_in ^ k_round_0;
                    count <= 1;
                end
            end else if (count <= 14) begin
                state_reg <= next_state_comb;

                if (count == 14) begin
                    cyphertext_out <= next_state_comb;
                    statue_next <= 1;
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end
endmodule
