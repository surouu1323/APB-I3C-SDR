module SM_sdr_private (
    input  wire clk,
    input  wire rst_n,
    input  wire scl,               // Clock từ master
    inout  wire sda,               // Dữ liệu hai chiều
    input  wire stop_detected,
    input  wire scl_rising,         // Cần tạo từ module edge detect ngoài
    input  wire start_detect,
    input wire [6:0] dynamic_address_wire,
    output reg [7:0] wdata,
    input  wire [7:0] rdata,
    input  wire i3c_sdr_sr_detect,
    output wire i3c_wr_en,
    output wire i3c_rd_en,
    input  wire        i3c_tx_ready,
    input  wire        i3c_rx_ready,
    output  wire busy_wire
);

    // Định nghĩa trạng thái
    localparam [4:0]
        IDLE      = 5'd0,
        Sr_START  = 5'd1,
        RW_BIT    = 5'd2,
        ADDR      = 5'd3,
        DATA      = 5'd4,
        ACK_BIT   = 5'd5,
        STOP      = 5'd6,
        T_BIT     = 5'd7;


    reg [4:0] state, next_state;


    // -----------------------------
    // Thanh ghi và biến trạng thái
    // -----------------------------

    reg [3:0] bit_cnt;   
    reg [7:0] shift_reg;
    reg rw_sel;
    reg sda_out;
    reg sda_en;
    reg [6:0] addr;

    // Bus SDA hai chiều
    assign sda = (sda_en & i3c_sdr_sr_detect) ? sda_out : 1'bz;

    assign busy_wire = (state != IDLE);
    // -----------------------------
    // 1) State register
    // -----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            bit_cnt     <= 0;
            shift_reg   <= 0;
            wdata       <= 0;
            addr        <= 0;
            rw_sel      <= 0;
        end else begin
            state <= next_state;

            // Các hành động tuần tự liên quan đến dữ liệu
            case (state)
                DATA, ADDR: begin
                    if(scl_rising)begin
                        if(state == ADDR) addr <= {addr[5:0], sda};
                        else if(state == DATA && (!rw_sel)) wdata <= {wdata[6:0], sda};
                        bit_cnt  <= bit_cnt + 1;
                    end
                end

                RW_BIT: begin
                    if(scl_rising)begin
                        rw_sel <= sda;
                    end
                end

                default: bit_cnt  <= 0;
            endcase
        end
    end

    assign i3c_rd_en = (state == STOP && (rw_sel == 1)) ? 1 :0;
    assign i3c_wr_en = (state == STOP && (rw_sel == 0)) ? 1 :0;


    // -----------------------------
    // 3) output register
    // -----------------------------
    always @(negedge scl or negedge rst_n or posedge scl_rising) begin
        if (!rst_n) begin
            sda_out <= 1;
            sda_en <= 0;
        end else begin
            // Các hành động tuần tự liên quan đến dữ liệu
            if(state == ACK_BIT) begin
                if( (rw_sel &&  i3c_tx_ready == 1) || (rw_sel==0 && i3c_rx_ready)) begin
                    sda_en <= 1;
                end
                else sda_en <= 0;
                sda_out <= 0;
            end
            else if(state == DATA) begin
                    if(rw_sel) begin
                        sda_en <= 1;
                        sda_out <= rdata[7-bit_cnt];
                        // bit_cnt <= bit_cnt + 1'b1;
                    end
                    else sda_en <= 0;
            end
            else begin
                sda_en <= 0;
                sda_out <= 1;
            end
        end
    end


    // -----------------------------
    // 2) Next state logic + output combinational
    // -----------------------------
    always @(*) begin
        // Mặc định giữ nguyên giá trị
        if (!rst_n) begin
            next_state = IDLE;
        end
        else begin
            // Ưu tiên stop_detected
            if (stop_detected) next_state = IDLE;
            else
                case (state)
                    IDLE: begin
                        if (i3c_sdr_sr_detect && start_detect) next_state = ADDR;  
                        else next_state = IDLE;
                    end

                    ADDR: begin
                        if (bit_cnt >= 4'h7) begin
                            if (addr == dynamic_address_wire) next_state = RW_BIT;
                            else next_state = IDLE;
                        end
                        else next_state = ADDR;
                    end

                    RW_BIT: begin
                        if (scl_rising) begin
                            next_state = ACK_BIT;
                        end
                        else next_state = RW_BIT;
                    end
                    
                    ACK_BIT: begin
                        if(addr == dynamic_address_wire && scl_rising &&(sda_out==0))  begin
                            if(sda_en)next_state = DATA ;      
                            else next_state=STOP;
                        end
                        else next_state = ACK_BIT;
                    end

                    DATA: begin
                        if (bit_cnt >= 4'd8) begin
                            next_state = T_BIT;
                        end
                        else next_state = DATA;
                    end

                    T_BIT:begin
                        if (scl_rising) begin
                            next_state = STOP;
                        end
                        else next_state = T_BIT;
                    end

                    STOP: begin
                        if(stop_detected)  next_state = IDLE;
                        else next_state = STOP;
                    end

                    default: next_state = IDLE;
                endcase
        end
    end

endmodule
