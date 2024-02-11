`include "packet_parser.sv"
module parser_tb();
  logic CLK_tb;
  logic nreset_tb;
  logic [31:0] bus_tb;
  logic [31:0] phs_tb;
  PacketParser dut(
    .CLK(CLK_tb),
    .bus(bus_tb),
    .nreset(nreset_tb), 
    .phs(phs_tb)
  );
  always begin
    #5;
    CLK_tb = ~CLK_tb;
  end

  initial begin
    CLK_tb = 0;
    nreset_tb = 0;
    bus_tb = 0;

    #100;
  end


endmodule