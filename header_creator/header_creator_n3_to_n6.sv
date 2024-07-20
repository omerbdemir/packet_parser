
`include "header_creator_includes.svh"
import header_creator_pkg::*;

module HeaderCreatorN3ToN6(
  input logic                               CLK,
  input logic                               reset,
  input logic   [`BUS_WIDTH_BITS - 1 : 0]   packet_bus_i,
  input logic                               start_of_packet_i,
  input header_creator_pkg::ADS_N3          ads_input_i,

  output logic  [15 : 0]                    packet_id_o,
  output logic                              packet_read_req_o
);


HC_N3_STATES                                currentState, nextState;
header_creator_pkg::ADS_N3                  ads_input_reg;
logic                                       packet_read_req_d;
logic   [(`BUS_WIDTH_BITS * 16) - 1 : 0]    packet_buffer;
logic   [15 : 0]                            packet_id_d, packet_id_q;
logic   [15 : 0]                            old_checksum_i;
logic   [5  : 0]                            old_dscp_i;
logic                                       checksum_req_i;
logic   [7  : 0]                            pkt_ctr;
logic                                       gnt_i;
logic   [15 : 0]                            new_checksum_i;
logic                                       is_ttl;

assign is_ttl = (packet_buffer[pkt_ctr * `BUS_WIDTH_BITS - 65 -: 8] > 0) ? 1 : 0;

checksum_gen checksum_gen_i(
  .clk          (CLK),
  .reset        (reset),
  .old_checksum (old_checksum_i),
  .removed_val  (old_dscp_i),
  .new_val      (ads_input_i.DSCP),
  .req          (checksum_req_i),
  .gnt          (gnt_i),
  .new_checksum (new_checksum_i)
);
always_ff @( posedge(CLK) ) begin : packet_buffering
  if(reset) begin 
    packet_buffer   <= 0;
    pkt_ctr         <= 0;
  end else begin 
    pkt_ctr       <= pkt_ctr + 1;
    packet_buffer[`BUS_WIDTH_BITS - 1 : 0] <= packet_bus_i;
    for (int i = 0 ; i < (`BUS_WIDTH_BITS * 16); i += 1) begin
      packet_buffer[i + `BUS_WIDTH_BITS] <= packet_buffer[i];
    end
    if(gnt_i) begin
        if(is_ttl) begin 
          
          packet_buffer[pkt_ctr * `BUS_WIDTH_BITS -48 -1 -: 16] <= new_checksum_i + (9'b100000000);

        end 
    end
  end
end

// assign old_checksum_i =   packet_buffer[pkt_ctr * `BUS_WIDTH_BITS - 81 -: 16];
// assign old_dscp_i     =   packet_buffer[pkt_ctr * `BUS_WIDTH_BITS - 9  -: 6];
// 512'h000000000000000000000000000000000000000000000000 45110027 6daf099e 3d110674 489605bc a647a346 94564a73
// 512'h000000000000000000000000000000000000000000000000 45110027 6daf099e 3d110674 489605bc a647a346 94564a73
always_comb begin : old_vals
  old_dscp_i          <=  old_dscp_i;
  old_checksum_i      <=  old_checksum_i;
  checksum_req_i      <=  0;
  if(currentState == N3_IDLE)begin 
    old_checksum_i    <=  0;
    old_dscp_i        <=  0;
    checksum_req_i    <=  0;
  end   
  if(currentState == N3_PKT_RCV) begin 
    if(pkt_ctr * `BUS_WIDTH_BITS >= 96) begin 
      old_checksum_i  <=  packet_buffer[pkt_ctr * `BUS_WIDTH_BITS - 81 -: 16];
      old_dscp_i      <=  packet_buffer[pkt_ctr * `BUS_WIDTH_BITS - 9  -: 6];
      checksum_req_i  <=  1;
    end 
  end
end

always_comb begin : signal_assignment
  packet_read_req_d <= 0;
  packet_id_d       <= 0;
  case (currentState)
    N3_IDLE:  begin 
      packet_read_req_d <= 1;
    end
    N3_PKT_RCV: begin 
         
    end 

    N3_PKT_MODIFY: begin 

    end 

    N3_PKT_FWD: begin 

    end 
  endcase
  
end

always_comb begin : state_machine
  nextState         = currentState;
  case (currentState)
    N3_IDLE: begin 
      if(start_of_packet_i == 1'h1) begin 
        nextState = N3_PKT_RCV;
      end 
    end
    N3_PKT_RCV: begin 
      if(pkt_ctr * `BUS_WIDTH_BITS >= 96) begin 
        nextState = N3_PKT_MODIFY;
      end
    end
    N3_PKT_MODIFY: begin  
      if(gnt_i) begin 
        nextState = N3_PKT_FWD;
      end
    end
    N3_PKT_FWD: begin 
      nextState = N3_IDLE;
    end
  endcase
end 

always @(posedge CLK) begin : state_transition
  if (reset) begin 
    currentState        <= N3_IDLE;
    ads_input_reg       <= 0;
  end else begin 
    ads_input_reg       <= ads_input_i;
    currentState        <= nextState;
  end 
end

assign packet_read_req_o  = packet_read_req_d;
assign packet_id_o        = packet_id_d;
endmodule