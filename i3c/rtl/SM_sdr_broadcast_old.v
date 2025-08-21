module SM_sdr_broadcast (
    input  wire clk,
    input  wire rst_n,
    input  wire scl,
    inout  wire sda,
    input  wire stop_detected,
    input  wire start_detect,
    input  wire scl_rising,         // Cần tạo từ module edge detect ngoài
    input  wire i3c_sdr_cmd_detect
);

    // Định nghĩa trạng thái
    localparam [2:0]
        IDLE      = 3'd0,
        DATA      = 3'd1,
        STOP      = 3'd2,
        T_BIT     = 3'd3;
    reg [2:0] state, next_state;


    // -----------------------------
    // Thanh ghi và biến trạng thái
    // -----------------------------

    reg [3:0] bit_cnt;   
    reg [7:0] SDR_Cmd;

    // -----------------------------
    // 1) State register
    // -----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            bit_cnt     <= 0;
            SDR_Cmd     <= 0;
        end else begin
            state <= next_state;
            // Các hành động tuần tự liên quan đến dữ liệu
            case (state)
                DATA: begin
                    if(scl_rising)begin
                        SDR_Cmd <= {SDR_Cmd[6:0], sda};
                        bit_cnt  <= bit_cnt + 1;
                    end
                end
                default:begin
                    bit_cnt <= 0;
                end
            endcase
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
                        if (i3c_sdr_cmd_detect ) next_state = DATA;  
                        else next_state = IDLE;
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
