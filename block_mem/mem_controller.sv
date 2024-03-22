`include "packet_parser/parser_includes.sv"

`define MEM_DEPTH                     (100)

module MemController(
  input wire                          CLK,
  input wire                          reset,
  //Write signals
  input wire [`BUS_WIDTH - 1: 0]      data_in,
  input wire [`BUS_WIDTH_B - 1 : 0]   byte_valid,
  input wire                          wen,
  input wire                          w_last_pkt,
  output wire [3 : 0]                 id_out,
  //Read signals
  input wire                          ren,
  input wire [3:0]                    r_id_in,
  output wire [`BUS_WIDTH - 1 : 0]    data_out,
  output wire                         r_last_pkt,

  output wire                         w_ready,
  output wire                         r_ready                    
);

logic [`BUS_WIDTH - 1 : 0]    mem_data_o;

logic                         mem_rsta_busy;
logic                         mem_rstb_busy;

wire                          mem_ena;
wire  [`BUS_WIDTH - 1 : 0]    mem_data;
wire  [31 : 0]                mem_w_addr; 
wire  [`BUS_WIDTH_B - 1 : 0]  mem_wea;
wire                          mem_enb;
wire  [31 : 0]                mem_r_addr;

design_1_blk_mem_gen_0_0 blk_mem(
  .clka             (CLK),    
  .ena              (mem_ena),
  .wea              (mem_wea),         
  .addra            (mem_w_addr),  
  .dina             (mem_data),               
  .clkb             (CLK),                     
  .rstb             (reset),
  .enb              (mem_enb),                    
  .addrb            (mem_r_addr),                        
  .doutb            (mem_data_o),                           
  .rsta_busy        (mem_rsta_busy),                  
  .rstb_busy        (mem_rstb_busy)                
);

wire  [3 : 0]   r_pkt_id;

logic           mem_read_en;

logic [3 : 0]   circ_addr;
logic [int'($clog2(`MAX_PAYLOAD_LEN / 4)) + ($clog2(`MAX_PAYLOAD_LEN / 4) == 0 ? -1 : 0) : 0]  mem_w_addr_i;
logic [int'($clog2(`MAX_PAYLOAD_LEN / 4)) + ($clog2(`MAX_PAYLOAD_LEN / 4) == 0 ? -1 : 0) : 0]  mem_r_addr_i;


assign mem_data     =   data_in;
assign mem_wea      =   byte_valid;
assign mem_ena      =   wen;
assign mem_data     =   data_in;
assign mem_w_addr   =   {circ_addr, mem_w_addr_i};

assign mem_enb      =   mem_read_en | ren;

assign data_out     =   mem_data_o;
assign id_out       =   circ_addr;
assign mem_r_addr   =   {{$size(mem_r_addr) - $size(r_id_in) - $size(mem_r_addr_i){1'b0}},r_id_in, mem_r_addr_i};

assign w_ready      =   ~mem_rsta_busy;
assign r_ready      =   ~mem_rstb_busy;

always_ff @( posedge CLK ) begin : write_process
  if(reset) begin 
    mem_w_addr_i  <= 0;
    circ_addr     <= 0;
  end else begin 
    if(wen) begin 
      mem_w_addr_i <= mem_w_addr_i + 1;
    end 
    if(w_last_pkt) begin 
      mem_w_addr_i  <= 0;
      circ_addr     <= circ_addr + 1;
    end 

  end 
  
end

always_ff @( posedge CLK ) begin : blockName
  if(reset) begin 
    mem_r_addr_i  <=  0;
    mem_read_en   <=  0'b0;
  end else begin 
    if (ren) begin 
      mem_read_en   <=  1'b1;
    end 
    if  (r_last_pkt) begin 
      mem_read_en   <=  0'b0;
    end 
    if (mem_enb) begin 
      // mem_r_addr_i <= mem_r_addr_i + 1;
    end 
    if (r_last_pkt) begin 
      mem_r_addr_i <= 0;
    end 
  end 
end

endmodule