
`include "parser_includes.sv"
import parser_typedefs_pkg::*;

module PacketParserN6 (
  input logic   [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1:0]    bus, 
  input logic                                           CLK,
  input logic                                           reset,
  input logic                                           start_of_packet_i,
  output logic  [(15 * 8 - 1):0]                        phs_o,
  output logic                                          phs_valid_o,
  output logic  [31:0]                                  pay_last_word,

  input wire                                            w_ready,
  output wire   [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0]  mem_out,
  output wire                                           mem_w_valid
);

  logic [(`BUFFER_WIDTH_BITS - 1):0]     data_buffer ;
  logic [3 : 0]                         ipv4_opts_len;
  logic [16 * 32 - 1 : 0]               ipv4_opts_buf;
  logic [15 : 0]                        ipv4_tot_len;
  
  logic [16 * 32 - 1 : 0]               tcp_opts_buf;
  logic [3 : 0]                         tcp_opts_len;

  logic [(500 * 8 - 1) : 0]             payload_buf;
  bit [(`COUNTER_WIDTH - 1) : 0]        data_ctr;
  bit [(`COUNTER_WIDTH - 1) : 0]        opts_ctr;
  bit [(`COUNTER_WIDTH - 1) : 0]        tcp_opts_ctr;
  // State machine logic
  parser_typedefs_pkg::N6_STATES        currentState, nextState;


  logic [11 : 0]                        buff_out_index;
  logic [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0] mem_out_i;
  logic                                 mem_w_valid_i;
  logic                                 write_mem_start_i;
  logic   [(`COUNTER_WIDTH - 1) : 0]      ip_first_chunk_id;
  // Header fields
  parser_typedefs_pkg::EthernetHeader   ethernetHeader;
  parser_typedefs_pkg::IPv4Header       tpdu_ipv4Header;
  parser_typedefs_pkg::UDPHeader        tpdu_udpHeader;
  parser_typedefs_pkg::TCPHeader        tpdu_tcpHeader;
  parser_typedefs_pkg::PHS_Struct       phs;
  

  // Counters for tracking bits received
  int                                   bitsReceived;
  logic                                  w_last_pkt;
  // assign w_last_pkt     = (data_ctr > (tpdu_ipv4Header.totalLength - `ETH_HDR_SIZE_B)) ? 1 : 0;
  assign mem_out        = mem_out_i;
  assign mem_w_valid    = mem_w_valid_i;

  always_ff @( posedge CLK ) begin : ip_first_chunk_proc

    if (reset) begin 
      ip_first_chunk_id <= 0;
    end else begin 
      if((data_ctr >= `ETH_HDR_SIZE_B) && (currentState == N6_ETH)) begin 
        ip_first_chunk_id <= data_ctr;
      end
      if(currentState == N6_IDLE) begin 
        ip_first_chunk_id <= 0;
      end 
    end 
  end

  always_ff @(posedge CLK ) begin : last_pkt_proc
    if(reset) begin 
      w_last_pkt <= 0;
    end else begin 
      if((currentState == N6_IDLE) && (write_mem_start_i == 1)) begin 
        w_last_pkt <= 1;
      end else begin 
        w_last_pkt <= 0;
      end 
    end 
  end 


  always_ff @( posedge CLK) begin : mem_out_proc
    if (reset) begin 
      write_mem_start_i <= 0;
      mem_out_i <= 0;
      mem_w_valid_i <= 0;
    end else begin
      if((currentState == N6_ETH) && (nextState != N6_ETH)) begin 
        write_mem_start_i <= 1'b1;
      end
      if(write_mem_start_i == 1) begin 
        mem_out_i <= data_buffer[ ((ip_first_chunk_id % `ETH_HDR_SIZE_B) + `BUS_WIDTH_B) * `BYTE_WIDTH - 1 -: (`BUS_WIDTH_B * `BYTE_WIDTH)];
      end 
    end   
  end 

  always_ff @( posedge CLK) begin : buffer_data
    if(reset) begin
      data_buffer <= 0;
    end else begin
      for (int i = 0; i < (`BUFFER_WIDTH_BITS)  - (`BUS_WIDTH_B * `BYTE_WIDTH); i = i + 1) begin
        data_buffer[i + (`BUS_WIDTH_B * `BYTE_WIDTH)] <= data_buffer[i];
      end
      data_buffer[(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0] <= bus;
    end
  end


  always_ff @( posedge CLK) begin : counter_inc
    if(reset)begin
      data_ctr <= 0;
    end else begin
      data_ctr <= data_ctr + `BUS_WIDTH_B; 
      if(start_of_packet_i == 1'b1) begin
        data_ctr <= (`BUS_WIDTH_B);
      end 
    end

  end

  always_ff @( posedge CLK) begin : opts_ctr_inc
    if(reset) begin 
      opts_ctr      <= 0;
      tcp_opts_ctr  <= 0;
    end else begin 
      tcp_opts_ctr    <= tcp_opts_ctr;
      opts_ctr        <= opts_ctr;
      if  ( currentState  ==  N6_TCP_OPTS  ) begin 
        tcp_opts_ctr  <= tcp_opts_ctr + (`BUS_WIDTH_B);
      end
      if  ( currentState == N6_IPV4_OPTS ) begin 
        opts_ctr <= opts_ctr + (`BUS_WIDTH_B);
      end 
      if  ( start_of_packet_i) begin 
        tcp_opts_ctr  <= 0;
        opts_ctr      <= 0;
      end
    end 
  end

  always_ff @( posedge CLK) begin : state_transition
    if(reset) begin
      currentState <= N6_IDLE;
    end else begin
      currentState <= nextState;
    end
    
  end

  always_ff @(currentState, data_ctr, start_of_packet_i, opts_ctr) begin : state_machine
  nextState <= currentState;
  ethernetHeader          <= ethernetHeader;
  tpdu_ipv4Header         <= tpdu_ipv4Header;
  tpdu_udpHeader          <= tpdu_udpHeader ;
  tpdu_tcpHeader          <= tpdu_tcpHeader ;
  ipv4_opts_buf           <= ipv4_opts_buf  ;
  ipv4_opts_len           <= ipv4_opts_len  ;
  tcp_opts_buf            <= tcp_opts_buf   ;
  tcp_opts_len            <= tcp_opts_len   ;
  payload_buf             <= payload_buf    ;
  // ip_first_chunk_id       <= ip_first_chunk_id;

  case (currentState)
    N6_IDLE : begin

        tcp_opts_buf              <= 0;
        tcp_opts_len              <= 0; 
        ethernetHeader            <= 0;
        tpdu_ipv4Header           <= 0;
        tpdu_udpHeader            <= 0;
        tpdu_tcpHeader            <= 0;
        ipv4_opts_buf             <= 0;
        ipv4_opts_len             <= 0;
        payload_buf               <= 0;
        ipv4_tot_len              <= 0;
        // ip_first_chunk_id         <= 0;

      if(start_of_packet_i == 1'b1) begin
        nextState <= N6_ETH;
      end
    end
    
    N6_ETH: begin
      if(data_ctr >= `ETH_HDR_SIZE_B) begin 
        ethernetHeader <= data_buffer[`ETH_LEFT_INDEX : `ETH_RIGHT_INDEX];
        // ip_first_chunk_id <= data_ctr;
        nextState <= N6_IPV4;
      end
    end

    N6_IPV4: begin
      if(data_ctr >= `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        tpdu_ipv4Header <= data_buffer[`IPV4_LEFT_INDEX : `IPV4_RIGHT_INDEX ];
        // If IPv4 header length is bigger than minimum there are extra options field
        if (data_buffer[`IPV4_LEFT_INDEX - `IPV4_VER_LEN_BITS -: `IPV4_IHL_LEN_BITS] > 5) begin 
          ipv4_opts_len <= data_buffer[ `IPV4_LEFT_INDEX - `IPV4_VER_LEN_BITS -: `IPV4_IHL_LEN_BITS];
          nextState <= N6_IPV4_OPTS;
        end else begin 
          if (data_buffer[((`IPV4_LEFT_INDEX) - (`LEN_TILL_PROTOCOL_B * `BYTE_WIDTH)) -: 8] == `PROTOCOL_UDP) begin 
            nextState <= N6_UDP;
          end else if (data_buffer[((`IPV4_LEFT_INDEX) - (`LEN_TILL_PROTOCOL_B * `BYTE_WIDTH)) -: 8] == `PROTOCOL_TCP) begin 
            nextState <= N6_TCP;
          end
        end
      end
    end

    N6_IPV4_OPTS : begin 

      ipv4_opts_buf[(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0] <= data_buffer[47 : 16];
      for (int i = 0; i < (`IPV4_OPTS_MAX_LEN - 1) * (`BUS_WIDTH_B * `BYTE_WIDTH); i = i + 1) begin
        ipv4_opts_buf[i + (`BUS_WIDTH_B * `BYTE_WIDTH)] <= ipv4_opts_buf[i];
      end
      if (opts_ctr < (ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4 - 1) begin 
        nextState <= N6_IPV4_OPTS;
      //Determine the next header type from protocol field in IPv4 header
      end else  begin 
        if (tpdu_ipv4Header.protocol == `PROTOCOL_UDP)begin 
          nextState <= N6_UDP;
        end else if (tpdu_ipv4Header.protocol == `PROTOCOL_TCP) begin 
          nextState <= N6_TCP;
        end else begin 
          nextState <= N6_IDLE;
        end
      end 
    end
    N6_UDP : begin
      
      if(data_ctr >= `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        tpdu_udpHeader <= data_buffer[ `UDP_LEFT_INDEX -: `UDP_HDR_SIZE_BITS];
        nextState <= N6_PAYLOAD;
      end 
    end

    N6_TCP : begin  
      ipv4_tot_len <= tpdu_ipv4Header.totalLength;
      if(data_ctr >= `TCP_HDR_SIZE_MIN_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B + ((ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4)) begin 
        tpdu_tcpHeader <= data_buffer[ (data_ctr - ((ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4)) * 8 - `TILL_IPV4_HDR_BITS - 1 -: `TCP_HDR_SIZE_BITS];
        $display("data_ctr : %h ipv4_opts_len : %h \n", data_ctr, ipv4_opts_len);
        if(data_buffer[(`TCP_LEFT_INDEX )- (`LEN_TILL_OFFSET_B * `BYTE_WIDTH) -: `TCP_OFFSET_LEN_BITS] > 5) begin 
          tcp_opts_len <= data_buffer[(`TCP_LEFT_INDEX ) - (`LEN_TILL_OFFSET_B * `BYTE_WIDTH ) -: `TCP_OFFSET_LEN_BITS];
          nextState <= N6_TCP_OPTS;
        end else begin 
          nextState <= N6_PAYLOAD;
        end 
      end 
    end 

    N6_TCP_OPTS : begin 
      tcp_opts_buf[31 : 0] <= data_buffer[47 : 16];
      for (int i = 0; i < (`TCP_OPTS_MAX_LEN / 4 - 1) * 32; i = i + 1) begin
        tcp_opts_buf[i + 32] <= tcp_opts_buf[i];
      end 
      if  ( tcp_opts_ctr  < tcp_opts_len - `TCP_OPTS_MIN_LEN / 4 - 1) begin 
        nextState <= N6_TCP_OPTS;
      end else begin 
        nextState <= N6_PAYLOAD;
      end
    end

    N6_PAYLOAD : begin 
      payload_buf[31 : 0] <= data_buffer[47 : 16];
      for(int i = 0; i < (`MAX_PAYLOAD_LEN / 4 - 1) * 32; i = i + 1) begin 
        payload_buf[i + 32] <= payload_buf[i];
      end
      if( data_ctr < tpdu_ipv4Header.totalLength + `ETH_HDR_OVERSIZE) begin 
        nextState <= N6_PAYLOAD;
      end else begin 
        nextState <= N6_IDLE;
      end
    end 

    default: begin
    end
  endcase


  end : state_machine

  always_comb begin : phs_assign
    if(tpdu_ipv4Header.protocol == 17) begin 
      phs = {8'h06,tpdu_ipv4Header.typeOfService, tpdu_udpHeader.sourcePort, tpdu_udpHeader.destPort, tpdu_ipv4Header.protocol, tpdu_ipv4Header.sourceIP, tpdu_ipv4Header.destIP};
    end else begin 
      phs = {8'h06,tpdu_ipv4Header.typeOfService, tpdu_tcpHeader.sourcePort, tpdu_tcpHeader.destPort, tpdu_ipv4Header.protocol, tpdu_ipv4Header.sourceIP, tpdu_ipv4Header.destIP};
    end

    if(((currentState == N6_TCP) && (nextState != N6_TCP)) || ((currentState == N6_UDP) && (nextState != N6_UDP))) begin 
      phs_valid_o = 1'b1;
    end else begin 
      phs_valid_o = 1'b0;
    end 

  end
  assign phs_o = phs;
  assign pay_last_word = payload_buf[31:0];


endmodule


