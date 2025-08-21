
// import tb_pkg::*;

module tb;
  `include "../tb/task_i3c.v"
  `include "../tb/task_apb.v"

  reg clk_tb, clk_apb;
  reg rst_n;
  wire sda_bus;
  reg scl_bus;
  reg sda;
  reg scl_en;
  reg sda_mode;
  reg ack;
  reg check_ack_en;
  pullup(sda_bus);
  integer state;

  reg         psel;
  reg         pwrite;
  reg         penable;
  reg [11:0]  paddr;
  reg [31:0]  pwdata;
  wire [31:0] prdata;
  wire        pready;
    
  i3c_top i3c_top_inst(
    .clk_apb(clk_apb),
    .rst_n(rst_n),
    .sda_bus(sda_bus),
    .scl_bus(scl_bus),
    .psel(psel),
    .pwrite(pwrite),
    .penable(penable),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready)
  );
  
	initial begin
        clk_apb = 0;
        forever   #5 clk_apb = ~clk_apb;
   	end

  initial begin
    clk_tb = 0;
    forever  #30 clk_tb = ~clk_tb; 
  end
  
 	always @(posedge clk_tb) scl_bus = (scl_en) ? ~scl_bus : 1;
  assign sda_bus = (sda_mode) ? sda : 1'bz;
  
    initial begin
      $dumpfile("./dump.vcd");
      $dumpvars(0,tb.i3c_top_inst);
      // $dumpfile("./sim/dump_dec.vcd");
      // $dumpvars(0,sda_bus,scl_bus);
    end

    initial begin
        // Init
      	rst_n = 0;
        sda = 1;
        scl_bus = 1;
        scl_en = 0 ;
        sda_mode = 0 ;
      	state = 0;

        psel    = 0;
        pwrite  = 0;
        penable = 0;
        paddr   = 12'h0;
        pwdata  = 32'h0;
        check_ack_en = 0;
      	#10 rst_n = 1;
      	#20;
      	
      // i3c_sdr_write(7'h77,8'h55);
      // i3c_sdr_read(7'h77);
      // i3c_broadcast();
      // i3c_broadcast_ccc(7'h07);


      check_ack_en = 0;
      apb_write(12'd4, 32'h1);
      apb_write(12'd8, 32'hff);

      apb_read(12'd0, 32'b1);
      apb_read(12'd4, 32'b1);
      apb_read(12'd8, 32'hff);

      
      i3c_sdr_read(7'h77,8'hff);

      i3c_sdr_write(7'h77,8'hAA);

      apb_read(12'd12, 32'hAA);


      #100;
      $finish;
        
    end
  

  
endmodule
