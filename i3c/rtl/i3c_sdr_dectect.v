module i3c_sdr_dectect (
    input  wire clk,
    input  wire rst_n,
    input  wire scl,               // Clock từ master
    inout  wire sda,               // Dữ liệu hai chiều
    input  wire stop_detected,
    input  wire start_detected,
    input  wire scl_rising,         // Cần tạo từ module edge detect ngoài
    output wire i3c_sdr_private_detect
    // output wire i3c_sdr_cmd_detect
);

    localparam BROADCAST_ADDR = 7'h7e;
    // Định nghĩa trạng thái
    localparam [3:0]
        IDLE      = 4'd0,
        BROADCAST = 4'd1,
        RW_BIT    = 4'd3,
        ACK_BIT   = 4'd4,
        STOP      = 4'd5;
 
    reg [3:0] state, next_state;
    reg [6:0] broadcast_addr;
    reg rw_sel;
    reg sda_en, sda_wdata;

    // Bus SDA hai chiều
    assign sda = sda_en ? sda_wdata : 1'bz;
    assign i3c_sdr_private_detect = (state == STOP)? 1 :0;
    // assign i3c_sdr_cmd_detect = (state == STOP )? 1 :0;

    // -----------------------------
    // Thanh ghi và biến trạng thái
    // -----------------------------

    reg [3:0] bit_cnt;   
    reg [7:0] shift_reg;

    // -----------------------------
    // 1) State register
    // -----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rw_sel <= 0;
            broadcast_addr <= 0;
            bit_cnt <= 0;
            state  <= IDLE;
            sda_en <= 0;
            sda_wdata <= 0;
            shift_reg <= 0;
        end 
        else begin
            state <= next_state;
            // Các hành động tuần tự liên quan đến dữ liệu
            case (state)
                BROADCAST: begin
                    if(scl_rising)begin
                        broadcast_addr <= {broadcast_addr[5:0], sda};
                        bit_cnt   <= bit_cnt + 1;
                    end
                end

                RW_BIT: begin
                    if(scl_rising)begin
                        rw_sel <= sda;
                    end
                end

                ACK_BIT: begin
                        sda_en <= 1;
                        sda_wdata <= 0;
                end

                default: begin
                    bit_cnt <= 0;
                    sda_en <= 0;
                end
            endcase
        end
    end


    // -----------------------------
    // 2) Next state logic + output combinational
    // -----------------------------
    // always @(rst_n, stop_detected, state,scl_rising , sda_en,bit_cnt,broadcast_addr,rw_sel,start_detected) begin
    always @(*) begin

        // Mặc định giữ nguyên giá trị
        if (!rst_n) begin
            next_state = 0;
        end
        else begin
            // Ưu tiên stop_detected
            if (stop_detected) next_state = IDLE;
            else
                case (state)
                    IDLE: begin
                        if (start_detected) begin
                            next_state = BROADCAST;
                        end
                        else next_state = IDLE;
                    end

                    BROADCAST: begin
                        if (bit_cnt >= 4'h7) begin
                            if(broadcast_addr == BROADCAST_ADDR) next_state = RW_BIT;
                            else next_state = STOP;
                        end
                        else next_state = BROADCAST;
                    end

                    RW_BIT: begin
                        if (scl_rising) begin
                           if(rw_sel == 0) next_state = ACK_BIT;
                            else next_state = IDLE;
                        end
                        else next_state = RW_BIT;
                    end

                    ACK_BIT: begin
                        if (scl_rising && sda_en) begin
                            next_state = STOP;     
                        end
                        else next_state = ACK_BIT;
                                          
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
