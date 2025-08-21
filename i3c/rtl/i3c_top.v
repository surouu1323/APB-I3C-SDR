module i3c_top(
    input wire clk_apb, rst_n,
    input wire scl_bus,
    inout wire sda_bus,
    input        psel,
    input        pwrite,
    input        penable,
    input  [11:0] paddr,
    input  [31:0] pwdata,
    output [31:0] prdata,
    output        pready
     
);
    wire rd_en, wr_en;
    wire [7:0]  i3c_rx_data, i3c_tx_data;
    wire [6:0] dynamic_address;
    wire i3c_sdr_private_detect;
    wire i3c_rd_en, i3c_wr_en;
    wire i3c_en;
    wire i3c_rx_ready, i3c_tx_ready;
    wire busy_wire;

    wire start_detected, stop_detected, edge_detect,i3c_sdr_sr_detect;

    apb_slave apb_slave_inst(
        .clk(clk_apb),
        .psel(psel),
        .pwrite(pwrite),
        .penable(penable),
        .pready(pready),
        .wr_en(wr_en),
        .rd_en(rd_en)
    );

    i3c_regfile i3c_regfile_inst(
        .clk(clk_apb),
        .rst_n(rst_n),
        .addr(paddr),
        .wdata(pwdata),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .rdata(prdata),
        // .dynamic_address(dynamic_address),
        .i3c_tx_data(i3c_tx_data),  
        .i3c_rx_data(i3c_rx_data),
        .i3c_rd_en(i3c_rd_en),
        .i3c_wr_en(i3c_wr_en),
        .dynamic_address(dynamic_address),
        .i3c_en(i3c_en),
        .i3c_tx_ready(i3c_tx_ready),
        .i3c_rx_ready(i3c_rx_ready),
        .busy_wire(busy_wire)
    );
    

    start_stop_detector start_stop_detector_inst(
        .clk(clk_apb),
        .rst_n(rst_n),
        .sda_in(sda_bus),
        .scl_in(scl_bus),
        .start_detected(start_detected),
        .stop_detected(stop_detected),
        .edge_detect(edge_detect),
        .i3c_en(i3c_en)
    );

    i3c_sdr_dectect i3c_sdr_dectect_inst(
        .clk(clk_apb),
        .rst_n(rst_n),
        .sda(sda_bus),
        .scl(scl_bus),
        .start_detected(start_detected),
        .stop_detected(stop_detected),
        .scl_rising(edge_detect),
        // .i3c_sdr_cmd_detect(i3c_sdr_cmd_detect),
        .i3c_sdr_private_detect(i3c_sdr_private_detect)
    );

    // SM_sdr_broadcast SM_sdr_broadcast_inst(
    //     .clk(clk),
    //     .rst_n(rst_n),
    //     .sda(sda_bus),
    //     .scl(scl_bus),
    //     .stop_detected(stop_detected),
    //     .scl_rising(edge_detect),
    //     .start_detect(start_detected),
    //     .i3c_sdr_cmd_detect(i3c_sdr_cmd_detect)
    // );

    SM_sdr_private SM_sdr_private_inst(
        .clk(clk_apb),
        .rst_n(rst_n),
        .sda(sda_bus),
        .scl(scl_bus),
        .stop_detected(stop_detected),
        .scl_rising(edge_detect),
        .start_detect(start_detected),
        .dynamic_address_wire(dynamic_address),
        .i3c_sdr_sr_detect(i3c_sdr_private_detect),
        .wdata(i3c_rx_data),
        .rdata(i3c_tx_data),
        .i3c_rd_en(i3c_rd_en),
        .i3c_wr_en(i3c_wr_en),
        .i3c_tx_ready(i3c_tx_ready),
        .i3c_rx_ready(i3c_rx_ready),
        .busy_wire(busy_wire)
    );


endmodule