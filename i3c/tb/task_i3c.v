task i3c_sdr_read(
    input [6:0] addr,
    input [7:0] exp_data
);
    reg [7:0] data;
    begin
      data = 0;
      $display("\n[READ-I3C ] time=%0t", $time);
      i3c_broadcast();
      if (tb.ack) begin
        $display("  %-14s : 0x%02h", "Addr", addr);
        tb.scl_en = 1;
        @(negedge tb.clk_tb); #1 tb.sda = 1; tb.sda_mode = 1;  
        @(negedge tb.clk_tb); #1 tb.sda = 0;
        shift_data_out({addr,1'b1}, 8);
        $write("  %-14s : %s", "Address-ACK", "" );
        check_ack();
        if (tb.ack) begin
          shift_data_in(data);
          $display("  %-14s : 0x%02h", "RDATA", data);
          $display("  %-14s : 0x%02h", "EXP_DATA", exp_data);
        end
        @(posedge tb.scl_bus);  tb.sda = 0; tb.sda_mode = 1;  
      end
      stop_pat();
      $display("  %-14s : %-10s", "Result", (exp_data == data && ((tb.check_ack_en)? tb.ack : 1)) ? "[PASS]" : "[FAILED]");
    end
endtask


task i3c_sdr_write(
    input [6:0] addr,
    input [7:0] data
);
    begin
      $display("\n[WRITE-I3C] time=%0t", $time);
      i3c_broadcast();
      
      if (tb.ack) begin
        $display("  %-14s : 0x%02h", "Addr", addr);
        tb.scl_en = 1;
        @(negedge tb.clk_tb); #1 tb.sda = 1; tb.sda_mode = 1;  
        @(negedge tb.clk_tb); #1 tb.sda = 0;
        shift_data_out({addr,1'b0}, 8);
        $write("  %-14s : %s", "Address-ACK", "" );
        check_ack();
        $display("  %-14s : 0x%02h", "WDATA", data);
        if (tb.ack) begin
          shift_data_out({data,~^data}, 9);
          // $display("  %-14s : [PASS]", "Result");
        end
        
      end
      stop_pat();
      $display("  %-14s : %-10s", "Result",   ((tb.check_ack_en)? tb.ack : 1) ? "[PASS]" : "[FAILED]");
      // if(tb.ack == 0) $display("  %-14s : %-10s", "Result",  "[FAILED]");
      
    end
endtask



task i3c_sdr_ccc_bc_write(
  		input [6:0] cmd,
        input [7:0] data
    );
    begin
        i3c_broadcast();
      	shift_data_out({cmd,~^cmd}, 9);
        check_ack();
      	shift_data_out({data,~^data}, 9);
        @(negedge tb.clk_tb);
        @(negedge tb.clk_tb); #1  tb.sda_mode = 0;  tb.scl_en =0;
    end
endtask

task i3c_sdr_ccc_direct_write(
  		input [6:0] cmd,
  		input [7:0] addr
    );
    begin
        i3c_broadcast();
      	shift_data_out({cmd,~^cmd}, 9);
      	@(negedge tb.clk_tb); #1  tb.sda = 1; tb.sda_mode = 1;  
        @(negedge tb.clk_tb); #1  tb.sda = 0;
      	shift_data_out({addr,1'b0}, 8);
        check_ack();
      	
        @(negedge tb.clk_tb);
        @(negedge tb.clk_tb); #1  tb.sda_mode = 0;  tb.scl_en =0;
    end
endtask

task i3c_broadcast();
    begin
      start_pat();
      shift_data_out(8'hFC, 8);
      tb.state = 1;
      // $write("Broadcast ACK:");
      $write("  %-14s : %s", "Broadcast-ACK", "");
	    check_ack();
      if(!tb.ack) tb.scl_en = 0;
    end
endtask

task i3c_broadcast_ccc(
        input [7:0] data
    );
    begin
        $display("broadcast_ccc: 0x%h", data);
        i3c_broadcast();
        if(tb.ack) begin
          tb.scl_en =1;
          shift_data_out({data,~^data}, 9);
          stop_pat();
        end
    end
endtask


task start_pat();
  begin
      @(negedge tb.clk_tb); #1  tb.sda_mode = 1; tb.sda = 1;
      @(negedge tb.clk_tb); #1  tb.sda = 0; tb.scl_en = 1;
      @(negedge tb.clk_tb); #1  tb.sda = 1;
      
  end
endtask

task stop_pat();
  begin
    
      @(negedge tb.clk_tb); #1 tb.sda_mode = 1; tb.sda = 0;  tb.scl_en = 0;
      @(negedge tb.clk_tb); #1 tb.sda = 1; 
      @(negedge tb.clk_tb); #1 tb.sda = 1; tb.sda_mode = 0;
  end

endtask


task check_ack();
    begin
        tb.sda_mode = 0;
        @(negedge tb.clk_tb);
        @(posedge tb.scl_bus);
      	// tb.ack =1;
        if(tb.sda_bus == 0) begin
          $display("[ACK]");
          tb.ack =1;
          tb.sda = 0;
          tb.sda_mode = 1;
          // return 1;
        end
        else begin
            $display("[NACK]");
            // return 0;
            tb.ack =0;
            end   
        @(negedge tb.scl_bus); 
        end
endtask

task shift_data_out(
        input [31:0] data,
        input [7:0] size
    );
    integer i;
    begin
    //     sda_mode = 1; //push-pull

        for(i = 0; i< size; i = i+1)begin
            @(negedge tb.clk_tb) tb.sda = data[size - i-1]; tb.sda_mode = 1;
            @(negedge tb.scl_bus);
        end
    end 
endtask

task shift_data_in(
        output [8:0] data
    );
    integer i;
    begin
        tb.sda_mode = 0; //push-pull
        for(i = 0; i< 8; i = i+1)begin
            @(posedge tb.scl_bus) data = {data[6:0],tb.sda_bus};
            // $display("sda : %b", tb.sda_bus);
            // @(posedge tb.scl_bus);
        end
    end 
endtask
// endpackage