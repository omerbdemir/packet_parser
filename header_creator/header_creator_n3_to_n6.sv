
`include "header_creator_includes.svh"
import header_creator_pkg::*;

module HeaderCreatorN3ToN6(

  input logic                                 CLK,
  input logic                                 reset,
  input logic   [`BUS_WIDTH_BITS - 1 : 0]     packet_bus_in,
  input header_creator_pkg::ADS_N3            ads_input_in,
  input                                       packet_id_in,
    
  input logic                                 start_of_packet_in,
  output logic  [15 : 0]                      packet_read_id_out,
  output logic                                packet_read_req_out,

  output logic  [`BUS_WIDTH_BITS - 1 : 0]     packet_bus_out,
  output logic  [15 : 0]                      packet_q_id_out

  );
  
  
  HC_N3_STATES                                currentState, nextState;
  header_creator_pkg::ADS_N3                  ads_input_reg;
  logic                                       packet_read_req_d;
  
  logic   [(`BUS_WIDTH_BITS * 16) - 1 : 0]    packet_buffer_in, packet_buffer_l, packet_buffer_r, packet_buffer_out;
  logic                                       buff_select_read;
  logic   [15 : 0]                            packet_id_d, packet_id_q;
  logic                                       mod_pkt_ready;
  logic                                       pkt_out_high_index;

  logic   [15 : 0]                            old_checksum_i;
  logic   [5  : 0]                            old_dscp_i;
  logic                                       checksum_req_i;
  logic   [15 : 0]                            new_checksum_i;
  logic                                       gnt_i;
  logic                                       is_ttl;

  logic   [7  : 0]                            pkt_ctr, pkt_ctr_l, pkt_ctr_r;
  logic   [15 : 0]                            pkt_len, pkt_len_l, pkt_len_r;
  logic                                       pkt_len_valid;

  assign is_ttl = (packet_buffer_in[pkt_ctr * `BUS_WIDTH_BITS - 65 -: 8] > 0) ? 1 : 0;
  
  checksum_gen checksum_gen_i(
  .clk          (CLK),
  .reset        (reset),
  .old_checksum (old_checksum_i),
  .removed_val  (old_dscp_i),
  .new_val      (ads_input_in.DSCP),
  .req          (checksum_req_i),
  .dec_ttl      (is_ttl),
  .gnt          (gnt_i),
  .new_checksum (new_checksum_i)
  );


  always_comb begin : out_buffering

    
  end

  always_comb begin : ping_pong_buff
    if(reset) begin 
      packet_buffer_l   <=  0;
      packet_buffer_r   <=  0;
      pkt_len_l         <=  0;
      pkt_len_r         <=  0;
    end else begin 
      if(buff_select_read) begin 
        packet_buffer_l   <=  packet_buffer_in;
        packet_buffer_r   <=  packet_buffer_r;
        pkt_len_l         <=  pkt_len;
        pkt_len_r         <=  pkt_len_r;
      end else begin 
        packet_buffer_r   <=  packet_buffer_in;
        packet_buffer_l   <=  packet_buffer_l;
        pkt_len_r         <=  pkt_len_r;
        pkt_len_l         <=  pkt_len_l;
      end 
    end
  end

  assign  pkt_ctr   =   ( buff_select_read ) ? pkt_ctr_l  :   pkt_ctr_r;
  always_ff @( posedge(CLK) ) begin : packet_buffering
    if(reset) begin 

      packet_buffer_in      <=  0;
      buff_select_read      <=  0;
      pkt_ctr_l             <=  0;
      pkt_ctr_r             <=  0;
      mod_pkt_ready         <=  0;

    end else begin

      pkt_ctr_l             <=  pkt_ctr_l;
      pkt_ctr_r             <=  pkt_ctr_r;

      packet_buffer_in[`BUS_WIDTH_BITS - 1 : 0] <= packet_bus_in;
      for (int i = 0 ; i < (`BUS_WIDTH_BITS * 16); i += 1) begin
        packet_buffer_in[i + `BUS_WIDTH_BITS] <= packet_buffer_in[i];
      end
      if (gnt_i) begin
        packet_buffer_in[pkt_ctr * `BUS_WIDTH_BITS -80 -1 -: 16] <= new_checksum_i;          
      end
      if ( (pkt_ctr * `BUS_WIDTH_BITS >= pkt_len * 8) && (pkt_len_valid) ) begin 
        buff_select_read      <=  ~buff_select_read;
      end 
      if (currentState == N3_PKT_MODIFY) begin 
        packet_buffer_in[pkt_ctr * `BUS_WIDTH_BITS + 24 - 1 -: 6]  <=  ads_input_reg.DSCP[5:0];
      end 


      if ( buff_select_read ) begin 
        pkt_ctr_l   <=  pkt_ctr_l + 1;
      end else begin 
        pkt_ctr_r   <=  pkt_ctr_r + 1;
      end 
    end
  end
  
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
        old_checksum_i  <=  packet_buffer_in[pkt_ctr * `BUS_WIDTH_BITS - 81 -: 16];
        old_dscp_i      <=  packet_buffer_in[pkt_ctr * `BUS_WIDTH_BITS - 9  -: 6];
        checksum_req_i  <=  1;
      end 
    end
  end
  
  always_comb begin : signal_assignment
    packet_read_req_d <=  0;
    packet_id_d       <=  0;
    case (currentState)
      N3_IDLE:  begin 
        packet_read_req_d   <= 1;
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
    nextState         =   currentState;
    case (currentState)
      N3_IDLE: begin 
        if(start_of_packet_in == 1'h1) begin 
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
        if(pkt_ctr * `BUS_WIDTH_BITS >= pkt_len * 8) begin 
          nextState = N3_IDLE;
        end 
      end
    endcase
  end 
  
  always @(posedge CLK) begin : state_transition
    if (reset) begin 
      currentState        <= N3_IDLE;
    end else begin 
      ads_input_reg       <= ads_input_in;
      currentState        <= nextState;
    end 
  end

  always_ff @( posedge CLK ) begin : registers
    if (reset) begin 
      ads_input_reg       <=  0;
      pkt_len             <=  0;
      pkt_len_valid       <=  0;
    end else begin 
      ads_input_reg       <=  ads_input_in;
      pkt_len_valid       <=  pkt_len_valid;
      if ( currentState == N3_IDLE ) begin 
        
        pkt_len_valid     <=  0;

      end else begin 
        if( pkt_ctr * `BUS_WIDTH_BITS >= 32) begin 
          pkt_len           <=  packet_buffer_in[pkt_ctr * `BUS_WIDTH_BITS - 16 - 1 -: 16];
          pkt_len_valid     <=  1;
        end else begin 
          pkt_len_valid     <=  pkt_len_valid;
        end 

      end 
    end
  end
  
  assign packet_read_req_out  = packet_read_req_d;
  assign packet_read_id_out        = packet_id_d;
endmodule