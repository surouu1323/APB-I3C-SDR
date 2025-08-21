module apb_slave(
  input wire clk,
  input wire psel, pwrite, penable,
  output wire pready,
  output reg wr_en, rd_en
);
  // Giữ nguyên handshake logic
  assign pready = 1'b1;

  always @(*) begin
    wr_en = (psel && penable && pwrite);
    rd_en = (psel && penable && !pwrite);
  end
endmodule