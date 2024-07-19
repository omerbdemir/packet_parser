module checksum_test();
  timeunit 1ns;
  logic CLK;
  int temp1, temp2, temp3;

  interface cs_intf(input logic clk);

    logic           reset;
    logic [15 : 0]  old_checksum;
    logic [15 : 0]  removed_val;
    logic [15 : 0]  new_val;
    logic [15 : 0]  new_checksum;
    logic           req;
    logic           gnt;


    clocking cb_cs @(posedge clk);
      default input #1 output #2;
      output posedge reset;
      input new_checksum, gnt;

      output old_checksum, removed_val, new_val, req;
    endclocking

    task reset_all();
      reset         = 0;
      old_checksum  = 0;
      removed_val   = 0;
      new_val       = 0;
      req           = 0;
    endtask

    task set_vals(input logic [15 : 0] old_check,
                  input logic [15 : 0] old_val,
                  input logic [15 : 0] new_val);
      @(cb_cs);
      cb_cs.old_checksum  <=  old_check;
      cb_cs.removed_val   <=  old_val;
      cb_cs.new_val       <=  new_val;
    endtask

    task wait_gnt();
      @(posedge cb_cs.gnt);
    endtask

  endinterface
  always begin 
    CLK = 0;
    forever #5 CLK = ~CLK ;
  end

  cs_intf   tb_int(CLK);

  checksum_gen dut(
    .clk(tb_int.clk),
    .reset(tb_int.reset),
    .old_checksum(tb_int.old_checksum),
    .removed_val(tb_int.removed_val),
    .new_val(tb_int.new_val),
    .req(tb_int.req),
    .gnt(tb_int.gnt),
    .new_checksum(tb_int.new_checksum)
  );

  initial begin
    // tb_int.reset_all();
    @(tb_int.cb_cs) tb_int.cb_cs.old_checksum   <=  0;
    @(tb_int.cb_cs) tb_int.cb_cs.old_checksum   <=  16'h5a5a;
    @(tb_int.cb_cs) tb_int.cb_cs.reset          <=  0;
    @(tb_int.cb_cs) tb_int.cb_cs.reset          <=  1;
    @(tb_int.cb_cs) tb_int.cb_cs.reset          <=  0;
    tb_int.set_vals(16'h1234, 16'h0023, 16'h0023);
    tb_int.cb_cs.req                            <=  1;
    @(tb_int.cb_cs);
    tb_int.cb_cs.req                            <=  0;
    tb_int.wait_gnt();

    for (int i = 0; i < 30000 ; i = i + 1) begin
      temp1 = $urandom_range(16'hffff, 0);
      temp2 = $urandom_range(16'hffff, 0);
      tb_int.set_vals(temp1, temp2, temp2);
      tb_int.cb_cs.req                            <=  1;
      @(tb_int.cb_cs);
      tb_int.cb_cs.req                            <=  0;
      tb_int.wait_gnt();
      // $display("Old checksum %h, new checksum %h  Time: %0t\n", temp1, tb_int.cb_cs.new_checksum, $time);
      if (temp1 != tb_int.cb_cs.new_checksum) begin
        $display("Error");
      end

    end

    #100;
    $stop();
  end

endmodule