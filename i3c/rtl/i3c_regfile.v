module i3c_regfile (
    input  wire        clk,
    input  wire        rst_n,

    // APB interface
    input  wire [11:0]  addr,       // địa chỉ word-aligned (0x00, 0x04, ...)
    input  wire [31:0] wdata,
    input  wire        wr_en,
    input  wire        rd_en,
    output reg  [31:0] rdata,

    // // I3C interface
    input  reg [7:0]  i3c_rx_data,
    output  wire        i3c_tx_ready,
    output  wire        i3c_rx_ready,

    output reg  [7:0]  i3c_tx_data,
    output wire [6:0] dynamic_address,
    // input  reg  [7:0]  DA_reg 
    input wire i3c_rd_en,
    input wire i3c_wr_en,
    output wire i3c_en,
    input wire busy_wire

);

    // Địa chỉ thanh ghi
    localparam ADDR_STATUS = 12'd0;
    localparam ADDR_CTRL   = 12'd4;
    localparam ADDR_TXDA   = 12'd8;
    localparam ADDR_RXDA   = 12'd12;
    localparam ADDR_DA     = 12'd16;

    // Thanh ghi
    reg [7:0] data_tx_reg;
    reg [7:0] data_rx_reg;
    reg [6:0] DA_reg ;
    reg       tx_empty;
    reg       rx_full;
    reg       busy;
    reg       en;
    reg       en_ack;

    assign i3c_en = en;
    assign dynamic_address = DA_reg;
    assign i3c_tx_ready = ~tx_empty;
    assign i3c_rx_ready = ~rx_full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_tx_reg <= 0;
            // data_rx_reg <= 0;
            DA_reg      <= 7'h77;
            tx_empty    <= 1'b1;
            rx_full     <= 1'b0;
            en <= 0;
            // en_ack <= 0;
        end else begin
            if (wr_en) begin
                case (addr)
                    ADDR_TXDA: begin
                        data_tx_reg <= wdata[7:0];
                        tx_empty    <= 1'b0;
                    end
                    ADDR_CTRL: begin
                        en <= wdata[0];
                    end
                    ADDR_DA: begin
                        DA_reg <= wdata[6:0];
                    end
                    default: ;
                endcase
            end
            else begin
                // Khi master đọc TX xong
                tx_empty <= (i3c_rd_en == 1) ? 1 : tx_empty;   
                if (rd_en && addr == ADDR_RXDA) rx_full <= 0;
                else if (i3c_wr_en == 1)  rx_full <=1;   
                else rx_full = rx_full;
            end
            
        end
    end


    always @(*) begin
        i3c_tx_data  = data_tx_reg;
        data_rx_reg  = i3c_rx_data ;
    end

    always @(*) begin
        en_ack = en;
        busy = busy_wire;
    end
    
    always @(rd_en) begin
        if(rd_en)
        case (addr)
            ADDR_STATUS: rdata = {28'h0, busy, tx_empty, rx_full, en_ack};
            ADDR_CTRL:   rdata = {31'h0,  en};
            ADDR_TXDA:   rdata = {24'h0, data_tx_reg};
            ADDR_RXDA:   rdata = {24'h0, data_rx_reg};
            ADDR_DA:     rdata = {25'h0, DA_reg};
            default:     rdata = 32'h0;
        endcase
        else  rdata = 32'h0;
    end

endmodule

