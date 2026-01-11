`timescale 1ns/1ps

module fpga_top(input M100_clk_i,
                input reset_i,
                input rx_i,
                output tx_o,
//                output temp,
                output stb,
                output led1,led2,led4,
                output trigger);

parameter SYS_CLK_FREQ = 10000000;
parameter NUM_SLAVES = 7;
wire temp;
wire tx_o_tmp;
wire loader_reset;
wire [31:0] loader_reg_o;
wire reset;
wire irq_ack_o;

wire clk_i, locked;
clk_wiz_1 clkwiz1
(
// Clock out ports
       .clk_out1(clk_i),
// Status and control signals
       .reset(1'b0),
       .locked(locked),
// Clock in ports
       .clk_in1(M100_clk_i)
);

//Wishbone master interface signals for core
wire data_wb_cyc_o;
wire data_wb_stb_o;
wire data_wb_we_o;
wire [31:0] data_wb_adr_o;
wire [31:0] data_wb_dat_o;
wire [3:0] data_wb_sel_o;
wire data_wb_stall_i;
wire data_wb_ack_i;
wire [31:0] data_wb_dat_i;
wire data_wb_err_i;
wire data_wb_rst_i;
wire data_wb_clk_i;

wire inst_wb_cyc_o;
wire inst_wb_stb_o;
wire inst_wb_we_o;
wire [31:0] inst_wb_adr_o;
wire [31:0] inst_wb_dat_o;
wire [3:0] inst_wb_sel_o;
wire inst_wb_stall_i;
wire inst_wb_ack_i;
wire [31:0] inst_wb_dat_i;
wire inst_wb_err_i;
wire inst_wb_rst_i;
wire inst_wb_clk_i;



wire mtip;
wire rx_irq_o;
wire [7:0] rx_byte;

assign tx_o = tx_o_tmp;
assign temp = tx_o_tmp;

//Wishbone slave signals for peripherals
wire [NUM_SLAVES-1 : 0] wb_cyc_i;
wire [NUM_SLAVES-1 : 0] wb_stb_i;
wire [NUM_SLAVES-1 : 0] wb_we_i;
wire [31:0] wb_adr_i [NUM_SLAVES-1 : 0];
wire [31:0] wb_dat_i [NUM_SLAVES-1 : 0];
wire [3:0] wb_sel_i [NUM_SLAVES-1 : 0];
wire [NUM_SLAVES-1 : 0] wb_stall_o;
wire [NUM_SLAVES-1 : 0] wb_ack_o;
wire [31:0] wb_dat_o [NUM_SLAVES-1 : 0];
wire [NUM_SLAVES-1 : 0] wb_err_o;
wire [NUM_SLAVES-1 : 0] wb_rst_i;
wire [NUM_SLAVES-1 : 0] wb_clk_i;
reg [NUM_SLAVES-1 : 0] r_stb;

wire [31:0] slave_adr_begin [NUM_SLAVES-1 : 0];
wire [31:0] slave_adr_end [NUM_SLAVES-1 : 0];

assign slave_adr_begin[0] = 32'h0000_0000;
assign slave_adr_end[0] = 32'h1000_0000;

assign slave_adr_begin[1] = 32'h0000_0000;
assign slave_adr_end[1] = 32'h1000_0000;

assign slave_adr_begin[2] = 32'h1000_8000;
assign slave_adr_end[2] = 32'h1000_800F;

assign slave_adr_begin[3] = 32'h1000_8010;
assign slave_adr_end[3] = 32'h1000_8013;

assign slave_adr_begin[4] = 32'h1000_8014;
assign slave_adr_end[4] = 32'h1000_8014;

assign slave_adr_begin[5] = 32'h1000_8020;
assign slave_adr_end[5] = 32'h1000_8023;

assign slave_adr_begin[6] = 32'h1000_8030;
assign slave_adr_end[6] = 32'h1000_8058; // 4 for data in and out 1 for status 1 for control 1for rst


assign wb_cyc_i[0] = inst_wb_cyc_o;
assign wb_stb_i[0] = inst_wb_stb_o;
assign wb_we_i[0] = inst_wb_we_o;
assign wb_adr_i[0] = inst_wb_adr_o;
assign wb_dat_i[0] = inst_wb_dat_o;
assign wb_sel_i[0] = inst_wb_sel_o;
assign wb_rst_i[0] = ~reset;
assign wb_clk_i[0] = clk_i;
assign inst_wb_dat_i = wb_dat_o[0];
assign inst_wb_ack_i = wb_ack_o[0];
assign inst_wb_stall_i = wb_stall_o[0];
assign inst_wb_err_i = wb_err_o[0];
assign inst_wb_rst_i = ~reset;
assign inst_wb_clk_i = clk_i;

assign stb = wb_stb_i[3];

genvar i;
generate
    for (i = 1; i<NUM_SLAVES ;i=i+1)
    begin
        assign wb_cyc_i[i] = data_wb_cyc_o;
        assign wb_stb_i[i] = data_wb_stb_o & ((slave_adr_begin[i] <= wb_adr_i[i]) && (wb_adr_i[i] <= slave_adr_end[i]));
        assign wb_we_i[i] = data_wb_we_o;
        assign wb_adr_i[i] = data_wb_adr_o;
        assign wb_dat_i[i] = data_wb_dat_o;
        assign wb_sel_i[i] = data_wb_sel_o;
        if(i == 4)
            assign wb_rst_i[i] = ~reset_i;
        else
            assign wb_rst_i[i] = ~reset;
        assign wb_clk_i[i] = clk_i;
    end
endgenerate

//Register strobe signals
always @(posedge wb_clk_i[0] or posedge wb_rst_i[0])
begin
    if(wb_rst_i[0])
        r_stb <= 0;
    else
        r_stb <= wb_stb_i;
end

reg [31:0] r_data_wb_dat_i;
reg r_data_wb_err_i;
reg r_data_wb_stall_i;
reg r_data_wb_ack_i;
reg valid;
integer k;
always @(*)
begin
    valid = 1'b0;
    for (k = 1; k < NUM_SLAVES && valid != 1'b1; k = k+1)
    begin
        if(r_stb[k])
        begin
            r_data_wb_dat_i = wb_dat_o[k];
            r_data_wb_stall_i = wb_stall_o[k];
            r_data_wb_err_i = wb_err_o[k];
            r_data_wb_ack_i = wb_ack_o[k];
            valid = 1'b1;
        end
        else
        begin
            r_data_wb_dat_i = 32'b0;
            r_data_wb_stall_i = 1'b0;
            r_data_wb_err_i = 1'b0;
            r_data_wb_ack_i = 1'b0;
        end
    end
end


assign data_wb_dat_i = r_data_wb_dat_i;
assign data_wb_ack_i = r_data_wb_ack_i;
assign data_wb_stall_i = r_data_wb_stall_i;
assign data_wb_err_i = r_data_wb_err_i;
assign data_wb_clk_i = clk_i;
assign data_wb_rst_i = ~reset;

assign reset = loader_reset & reset_i;

core_wb #(.reset_vector(32'h0))
    core0(.reset_i(reset), //active-low reset
          .clk_i(clk_i),
          //Wishbone interface for data memory
          .data_wb_cyc_o(data_wb_cyc_o),
          .data_wb_stb_o(data_wb_stb_o),
          .data_wb_we_o(data_wb_we_o),
          .data_wb_adr_o(data_wb_adr_o),
          .data_wb_dat_o(data_wb_dat_o),
          .data_wb_sel_o(data_wb_sel_o),
          .data_wb_stall_i(data_wb_stall_i),
          .data_wb_ack_i(data_wb_ack_i),
          .data_wb_dat_i(data_wb_dat_i),
          .data_wb_err_i(data_wb_err_i),
          .data_wb_rst_i(data_wb_rst_i),
          .data_wb_clk_i(data_wb_clk_i),
          //Wishbone interface for instruction memory
          .inst_wb_cyc_o(inst_wb_cyc_o),
          .inst_wb_stb_o(inst_wb_stb_o),
          .inst_wb_we_o(inst_wb_we_o),
          .inst_wb_adr_o(inst_wb_adr_o),
          .inst_wb_dat_o(inst_wb_dat_o),
          .inst_wb_sel_o(inst_wb_sel_o),
          //.inst_wb_stall_i(inst_wb_stall_i),
          //.inst_wb_ack_i(inst_wb_ack_i),
          .inst_wb_dat_i(inst_wb_dat_i),
          .inst_wb_err_i(inst_wb_err_i),
          //.inst_wb_rst_i(inst_wb_rst_i),
          //.inst_wb_clk_i(inst_wb_clk_i),
          //Interrupts
          .meip_i(1'b0),
          .mtip_i(mtip),
          .msip_i(1'b0),
          .fast_irq_i({15'b0,rx_irq_o}),
          .irq_ack_o(irq_ack_o));

memory_2rw_wb #(.ADDR_WIDTH(16))
    memory(.port0_wb_cyc_i(wb_cyc_i[0]),
           .port0_wb_stb_i(wb_stb_i[0]),
           .port0_wb_we_i(wb_we_i[0]),
           .port0_wb_adr_i(wb_adr_i[0]),
           .port0_wb_dat_i(wb_dat_i[0]),
           .port0_wb_sel_i(wb_sel_i[0]),
           .port0_wb_stall_o(wb_stall_o[0]),
           .port0_wb_ack_o(wb_ack_o[0]),
           .port0_wb_dat_o(wb_dat_o[0]),
           .port0_wb_err_o(wb_err_o[0]),
           .port0_wb_rst_i(wb_rst_i[0]),
           .port0_wb_clk_i(wb_clk_i[0]),

           .port1_wb_cyc_i(wb_cyc_i[1]),
           .port1_wb_stb_i(wb_stb_i[1]),
           .port1_wb_we_i(wb_we_i[1]),
           .port1_wb_adr_i(wb_adr_i[1]),
           .port1_wb_dat_i(wb_dat_i[1]),
           .port1_wb_sel_i(wb_sel_i[1]),
           .port1_wb_stall_o(wb_stall_o[1]),
           .port1_wb_ack_o(wb_ack_o[1]),
           .port1_wb_dat_o(wb_dat_o[1]),
           .port1_wb_err_o(wb_err_o[1]),
           .port1_wb_rst_i(wb_rst_i[1]),
           .port1_wb_clk_i(wb_clk_i[1]));

mtime_registers_wb #(.mtime_adr(32'h1000_8000),
                     .mtimecmp_adr(32'h1000_8008))
    mtime_regs(.wb_cyc_i(wb_cyc_i[2]),
               .wb_stb_i(wb_stb_i[2]),
               .wb_we_i(wb_we_i[2]),
               .wb_adr_i(wb_adr_i[2]),
               .wb_dat_i(wb_dat_i[2]),
               .wb_sel_i(wb_sel_i[2]),
               .wb_stall_o(wb_stall_o[2]),
               .wb_ack_o(wb_ack_o[2]),
               .wb_dat_o(wb_dat_o[2]),
               .wb_err_o(wb_err_o[2]),
               .wb_rst_i(wb_rst_i[2]),
               .wb_clk_i(wb_clk_i[2]),
               .mtip_o(mtip));

uart_wb #(.SYS_CLK_FREQ(SYS_CLK_FREQ), .BAUD(57600))
    uart0(.wb_cyc_i(wb_cyc_i[3]),
          .wb_stb_i(wb_stb_i[3]),
          .wb_we_i(wb_we_i[3]),
          .wb_adr_i(wb_adr_i[3]),
          .wb_dat_i(wb_dat_i[3]),
          .wb_sel_i(wb_sel_i[3]),
          .wb_stall_o(wb_stall_o[3]),
          .wb_ack_o(wb_ack_o[3]), 
          .wb_dat_o(wb_dat_o[3]),
          .wb_err_o(wb_err_o[3]),
          .wb_rst_i(wb_rst_i[3]),
          .wb_clk_i(wb_clk_i[3]),

          .rx_i(rx_i),
          .tx_o(tx_o_tmp),
          .rx_byte_o(rx_byte),
          .rx_irq_o(rx_irq_o));

loader_wb #(.SYS_CLK_FREQ(SYS_CLK_FREQ))
    loader0(.wb_cyc_i(wb_cyc_i[4]),
            .wb_stb_i(wb_stb_i[4]),
            .wb_we_i(wb_we_i[4]),
            .wb_adr_i(wb_adr_i[4]),
            .wb_dat_i(wb_dat_i[4]),
            .wb_sel_i(wb_sel_i[4]),
            .wb_stall_o(wb_stall_o[4]),
            .wb_ack_o(wb_ack_o[4]),
            .wb_dat_o(wb_dat_o[4]),
            .wb_err_o(wb_err_o[4]),
            .wb_rst_i(wb_rst_i[4]),
            .wb_clk_i(wb_clk_i[4]),

            .uart_rx_irq(rx_irq_o),
            .uart_rx_byte(rx_byte),
            .reset_o(loader_reset),
            .led1(led1), .led2(led2), .led4(led4));

gpio_wb   gpio(.wb_cyc_i(wb_cyc_i[5]),
          .wb_stb_i(wb_stb_i[5]),
          .wb_we_i(wb_we_i[5]),
          .wb_adr_i(wb_adr_i[5]),
          .wb_dat_i(wb_dat_i[5]),
          .wb_sel_i(wb_sel_i[5]),
          .wb_stall_o(wb_stall_o[5]),
          .wb_ack_o(wb_ack_o[5]),
          .wb_dat_o(wb_dat_o[5]),
          .wb_err_o(wb_err_o[5]),
          .wb_rst_i(wb_rst_i[5]),
          .wb_clk_i(wb_clk_i[5]),
          .trigger_o(trigger)
          );
          
        reg [31:0] aes_in0, aes_in1, aes_in2, aes_in3;
         wire aes_start_pulse; 
         reg start_pulse_reg; 
         wire [31:0] aes_out0, aes_out1, aes_out2, aes_out3;
         wire        aes_ready; 
          
          //-----------------------------------------------------
// AES register address decode
//-----------------------------------------------------
wire aes_addr_valid =
    (wb_adr_i[6] == 32'h1000_8030) || // in0
    (wb_adr_i[6] == 32'h1000_8034) || // in1
    (wb_adr_i[6] == 32'h1000_8038) || // in2
    (wb_adr_i[6] == 32'h1000_803C) || // in3
    (wb_adr_i[6] == 32'h1000_8040) || // start
    (wb_adr_i[6] == 32'h1000_8044) || // ready
    (wb_adr_i[6] == 32'h1000_8048) || // out0
    (wb_adr_i[6] == 32'h1000_804C) || // out1
    (wb_adr_i[6] == 32'h1000_8050) || // out2
    (wb_adr_i[6] == 32'h1000_8054);   // out3

reg [31:0] aes_read_latch;

always @(posedge clk_i) begin
    if (wb_rst_i[6]) begin
        aes_read_latch <= 32'd0;
    end
    else if (wb_cyc_i[6] && wb_stb_i[6] && !wb_we_i[6] && aes_addr_valid) begin
        case (wb_adr_i[6])
            32'h1000_8048: aes_read_latch <= aes_out0;
            32'h1000_804C: aes_read_latch <= aes_out1;
            32'h1000_8050: aes_read_latch <= aes_out2;
            32'h1000_8054: aes_read_latch <= aes_out3;
            32'h1000_8044: aes_read_latch <= {31'b0, aes_ready};
            default:       aes_read_latch <= 32'd0;
        endcase
    end
end

assign wb_dat_o[6] = aes_read_latch;

always @(posedge clk_i) begin
    if (wb_rst_i[6]) begin
        aes_in0 <= 32'd0;
        aes_in1 <= 32'd0;
        aes_in2 <= 32'd0;
        aes_in3 <= 32'd0;
        start_pulse_reg <= 1'b0;
    end
    else begin
        start_pulse_reg <= 1'b0;

        if (wb_cyc_i[6] && wb_stb_i[6] && wb_we_i[6] && aes_addr_valid) begin
            case (wb_adr_i[6])
                32'h1000_8030: aes_in0 <= wb_dat_i[6];
                32'h1000_8034: aes_in1 <= wb_dat_i[6];
                32'h1000_8038: aes_in2 <= wb_dat_i[6];
                32'h1000_803C: aes_in3 <= wb_dat_i[6];
                32'h1000_8040: start_pulse_reg <= 1'b1;
            endcase
        end
    end
end


      
        assign aes_start_pulse = start_pulse_reg;

        assign wb_ack_o[6]   = wb_cyc_i[6] && wb_stb_i[6] && aes_addr_valid;
        assign wb_stall_o[6] = 1'b0;
        assign wb_err_o[6]   = wb_cyc_i[6] && wb_stb_i[6] && !aes_addr_valid;

         aes_wb_wrapper aes_inst (
             .clk(clk_i),
             .rst(wb_rst_i[6]),
             .start(aes_start_pulse),
             .in0(aes_in0), 
             .in1(aes_in1),
             .in2(aes_in2),
             .in3(aes_in3),
             .out0(aes_out0),
             .out1(aes_out1),
             .out2(aes_out2),
             .out3(aes_out3),
             .ready(aes_ready)
         );
endmodule

