`inclue "packet_parser/parser_includes.sv"

`define MEM_DEPTH                     (100)

module MemController(
  input logic                         CLK,
  input logic                         reset,
  input logic [31:0]                  w_addr_in,
  input logic [`BUS_WIDTH - 1: 0]     data_in,
  input logic [31:0]                  r_addr_in,
  output logic [`BUS_WIDTH - 1 : 0]   data_out,
);

logic mem_ena;
logic [3 : 0] mem_wea;
logic mem_enb;
logic [31 : 0] mem_w_addr_i; 
logic [31 : 0] mem_r_addr_i;
logic [`BUS_WIDTH - 1 : 0]  mem_data_i;
logic [`BUS_WIDTH - 1 : 0]  mem_data_o;

logic mem_rsta_busy;
logic mem_rstb_busy;

design_1_blk_mem_gen_0_0 blk_mem(
  .clka(CLK),    
  .ena(mem_ena),
  .wea(mem_wea),         
  .addra(mem_w_addr_i),  
  .dina(mem_data_i),               
  .clkb(CLK),                     
  .rstb(reset),
  .enb(mem_enb),                    
  .addrb(mem_r_addr_i),                        
  .dout(mem_data_o),                           
  .rsta_busy(mem_rsta_busy),                  
  .rstb_busy(mem_rstb_busy)                
);

logic [`MAX_PAYLOAD_LEN * MEM_DEPTH - 1 : 0]circ_addr

endmodule