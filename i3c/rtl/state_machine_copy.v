module state_machinee (
    input wire clk,
    input wire rst_n,
    input wire scl,               // Clock từ master
    inout wire sda,               // Dữ liệu hai chiều
    input stop_detected, start_detected

);
    reg [7:0] data_out;    // Dữ liệu nhận được
    reg data_ready ;        // Cờ báo nhận xong
    parameter SLAVE_ADDR = 7'h7e; // Địa chỉ slave cố định

    // Định nghĩa trạng thái bằng localparam
    localparam IDLE      = 4'h0;
    localparam BROADCAST = 4'd1;
    localparam RW_BIT    = 4'd2;
    localparam ADDR_ACK  = 4'd3;
    localparam ADDR      = 4'd4;
    localparam DATA      = 4'd5;
    localparam DATA_ACK  = 4'd6;
    localparam STOP      = 4'd7;


    reg [2:0] state;  // Biến trạng thái hiện tại

    reg rw_sel;
    reg [3:0] bit_cnt = 0;
    reg [7:0] shift_reg = 0;
    reg sda_out ;
    reg sda_en ; // Enable output cho SDA

    assign sda = (sda_en) ? sda_out : 1'bz;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 0;
            shift_reg <= 0;
            sda_out <= 1;
            sda_en <= 0;
            data_out <= 0;
            data_ready <= 0;
        end else begin
            if ( stop_detected )  state <= IDLE;// Phát hiện điều kiện STOP
            else
                case (state)
                    IDLE: begin
                        data_ready <= 0;
                        bit_cnt <= 0;
                        sda_en <= 0;
                        if (start_detected) begin
                            // Bắt đầu START condition
                            state <= BROADCAST;
                        end
                    end

                    BROADCAST: begin
                        if (scl_rising) begin
                               shift_reg <= {shift_reg[6:0], sda}; // Nhận bit
                                bit_cnt <= bit_cnt + 1; 
                                if (bit_cnt >= 6) begin
                                    state <= RW_BIT;
                                    bit_cnt <= 0;
                                end
                        end
                    end

                    RW_BIT: begin
                        if (scl_rising) begin
                                rw_sel <=  sda; // Nhận bit
                                state <= ADDR_ACK;
                            end
                    end

                    ADDR_ACK: begin
                        if (shift_reg[7:0] == 7'h7e | shift_reg[7:0] == 7'h77) begin
                            // Nhận đúng địa chỉ và là WRITE
                            sda_en <= 1;
                            sda_out <= 0; // Gửi ACK
                            if (scl_rising) state <= IDLE;
                        end else begin
                            // Không đúng địa chỉ → về IDLE
                            state <= IDLE;
                        end
                    end

                    ADDR: begin
                        if (scl_rising) begin
                               shift_reg <= {shift_reg[6:0], sda}; // Nhận bit
                                bit_cnt <= bit_cnt + 1; 
                                if (bit_cnt >= 6) begin
                                    state <= RW_BIT;
                                    bit_cnt <= 0;
                                end
                        end
                    end


                    DATA: begin
                        sda_en <= 0; // Nhả SDA
                        if (scl_rising) begin
                            shift_reg <= {shift_reg[6:0], sda}; // Nhận bit
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt == 7) begin
                                state <= DATA_ACK;
                                bit_cnt <= 0;
                            end
                        end
                    end

                    DATA_ACK: begin
                        sda_en <= 1;
                        sda_out <= 0; // ACK lại
                        data_out <= shift_reg;
                        data_ready <= 1;
                        state <= STOP;
                    end

                    STOP: begin
                        sda_en <= 0;
                        if (sda == 1 && scl == 1) begin
                            // Phát hiện điều kiện STOP
                            state <= IDLE;
                        end
                    end
            endcase
        end
    end

endmodule
