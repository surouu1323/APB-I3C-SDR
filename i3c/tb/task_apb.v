// -----------------------------
// APB write task
// -----------------------------
task apb_write(
    input [11:0] addr,
    input [31:0] data
);
    begin
        @(posedge tb.clk_apb); #1;
        tb.psel    <= 1;
        tb.pwrite  <= 1;
        tb.penable <= 0;
        tb.paddr   <= addr;
        tb.pwdata  <= data;
        @(posedge tb.clk_apb); #1;
        tb.penable <= 1;
        @(posedge tb.clk_apb); #1;

        $display("\n[WRITE-APB] time=%0t", $time);
        $display("  %-14s : %-12s", "Addr",  $sformatf("0x%03h", addr));
        $display("  %-14s : %-12s", "WDATA", $sformatf("0x%08h", data));
        $display("  %-14s : %-12s", "Result", "[DONE]");

        tb.psel    <= 0;
        tb.pwrite  <= 0;
        tb.penable <= 0;
    end
endtask


// -----------------------------
// APB read task
// -----------------------------
task apb_read(
    input [11:0] addr,
    input [31:0] exp_data
);
    begin
        @(posedge tb.clk_apb);
        tb.psel    <= 1;
        tb.pwrite  <= 0;
        tb.penable <= 0;
        tb.paddr   <= addr;
        @(posedge tb.clk_apb);
        tb.penable <= 1;
        @(posedge tb.clk_apb);

        $display("\n[READ-APB ] time=%0t", $time);
        $display("  %-14s : %-12s", "Addr",     $sformatf("0x%03h", addr));
        $display("  %-14s : %-12s", "RDATA",    $sformatf("0x%08h", tb.prdata));
        $display("  %-14s : %-12s", "EXP_DATA", $sformatf("0x%08h", exp_data));
        $display("  %-14s : %-12s", "Result",   (exp_data == tb.prdata) ? "[PASS]" : "[FAILED]");

        tb.psel    <= 0;
        tb.penable <= 0;
    end
endtask