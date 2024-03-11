
`include "parser_includes.sv"
import parser_typedefs_pkg::*;

module PacketParserN6 (
  input logic [`BUS_WIDTH - 1:0]              bus, 
  input logic                     CLK,
  input logic                     reset,
  input logic                     start_of_packet_i,
  output logic [(15 * 8 - 1):0]   phs_o,
  output logic                    phs_valid_o,
  output logic [31:0]             pay_last_word
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

  // Header fields
  parser_typedefs_pkg::EthernetHeader   ethernetHeader;
  parser_typedefs_pkg::IPv4Header       tpdu_ipv4Header;
  parser_typedefs_pkg::UDPHeader        tpdu_udpHeader;
  parser_typedefs_pkg::TCPHeader        tpdu_tcpHeader;
  parser_typedefs_pkg::PHS_Struct       phs;
  

  // Counters for tracking bits received
  int                                 bitsReceived;

  always_ff @( posedge CLK) begin : buffer_data
    if(reset) begin
      data_buffer <= 0;
    end else begin
      for (int i = 0; i < (`BUFFER_WIDTH * `BYTE_WIDTH)  - `BUS_WIDTH; i = i + 1) begin
        data_buffer[i + `BUS_WIDTH] <= data_buffer[i];
        // data_buffer[i] <= data_buffer[i + `BUS_WIDTH];
      end
      data_buffer[`BUS_WIDTH - 1 : 0] <= bus;
      // data_buffer[`BUFFER_WIDTH_BITS - 1 : `BUFFER_WIDTH_BITS - `BUS_WIDTH] <= bus;
    end
  end


  always_ff @( posedge CLK) begin : counter_inc
    if(reset)begin
      data_ctr <= 0;
    end else begin
      data_ctr <= data_ctr; 
      if(currentState != N6_IPV4_OPTS) begin 
        data_ctr <= data_ctr + 1;
      end
      if(start_of_packet_i == 1'b1) begin
        data_ctr <= 1;
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
        tcp_opts_ctr  <= tcp_opts_ctr + 1;
      end
      if  ( currentState == N6_IPV4_OPTS ) begin 
        opts_ctr <= opts_ctr + 1;
      end 
      if  ( start_of_packet_i ) begin 
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
  case (currentState)
    N6_IDLE : begin
        tcp_opts_buf            <= 0;
        tcp_opts_len            <= 0; 
        ethernetHeader          <= 0;
        tpdu_ipv4Header         <= 0;
        tpdu_udpHeader          <= 0;
        tpdu_tcpHeader          <= 0;
        ipv4_opts_buf           <= 0;
        ipv4_opts_len           <= 0;
        payload_buf             <= 0;
        ipv4_tot_len            <= 0;
      if(start_of_packet_i == 1'b1) begin
        nextState <= N6_ETH;
      end
    end
    
    N6_ETH: begin

      
      if(data_ctr * (`BUS_WIDTH / `BYTE_WIDTH) >= `ETH_HDR_SIZE_B) begin 
        ethernetHeader <= data_buffer[`ETH_LEFT_INDEX : `ETH_RIGHT_INDEX];
        nextState <= N6_IPV4;
      end

      // if(data_ctr * (`BUS_WIDTH / `BYTE_WIDTH) == `ETH_HDR_SIZE_B) begin 
      //   ethernetHeader <= data_buffer[(`ETH_HDR_SIZE_B * `BYTE_WIDTH) - 1 : 0];
      // end 
      // else if(data_ctr * (`BUS_WIDTH / `BYTE_WIDTH) > `ETH_HDR_SIZE_B) begin

      //   ethernetHeader <= data_buffer[(`ETH_HDR_SIZE_B + 2) * `BYTE_WIDTH - 1: 16];
      //   nextState <= N6_IPV4;
      // end

    end

    N6_IPV4: begin

      if(data_ctr * 4 >= `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        // tpdu_ipv4Header <= data_buffer[(`IPV4_HIGH_INDEX * 8) - 1 -: `IPV4_HDR_SIZE_B * 8 ];
        tpdu_ipv4Header <= data_buffer[`IPV4_LEFT_INDEX : `IPV4_RIGHT_INDEX ];
        
        // If IPv4 header length is bigger than minimum there are extra options field
        if (data_buffer[`IPV4_LEFT_INDEX - `IPV4_VER_LEN_BITS -: `IPV4_IHL_LEN_BITS] > 5) begin 
          ipv4_opts_len <= data_buffer[ `IPV4_LEFT_INDEX - `IPV4_VER_LEN_BITS -: `IPV4_IHL_LEN_BITS];
          nextState <= N6_IPV4_OPTS;
        end else begin 
          if (data_buffer[((`IPV4_HIGH_INDEX * 8) - 1 - (8 * 9)) -: 8] == 17) begin 
            nextState <= N6_UDP;
          end else begin 
            nextState <= N6_TCP;
          end
        end
      end
    end

    N6_IPV4_OPTS : begin 

      ipv4_opts_buf[31 : 0] <= data_buffer[47 : 16];
      for (int i = 0; i < (`IPV4_OPTS_MAX_LEN - 1) * 32; i = i + 1) begin
        ipv4_opts_buf[i + 32] <= ipv4_opts_buf[i];
      end
      if (opts_ctr < ipv4_opts_len - `IPV4_HDR_MIN_LEN_W - 1) begin 
        nextState <= N6_IPV4_OPTS;
      //Determine the next header type from protocol field in IPv4 header
      end else if (tpdu_ipv4Header.protocol == 17)begin 
        nextState <= N6_UDP;
      end else begin 
        nextState <= N6_TCP;
      end

    end
    N6_UDP : begin
      
      if(data_ctr * 4 >= `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        tpdu_udpHeader <= data_buffer[ (`UDP_HIGH_INDEX * 8) - 1 -: `UDP_HDR_SIZE_B * 8];
        nextState <= N6_PAYLOAD;
      end 
    end

    N6_TCP : begin 
      ipv4_tot_len <= tpdu_ipv4Header.totalLength;
      if(data_ctr * 4 >= `TCP_HDR_SIZE_MIN_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        tpdu_tcpHeader <= data_buffer[(22 * 8) - 1 : 16];
        if(data_buffer[(`TCP_HIGH_INDEX * 8 ) - 1 - (8 * 12) -: 4] > 5) begin 
          tcp_opts_len <= data_buffer[(`TCP_HIGH_INDEX * 8 ) - 1 - (8 * 12) -: 4];
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
      if((data_ctr + tpdu_ipv4Header.headerLength - 5) * 4 < tpdu_ipv4Header.totalLength + `ETH_HDR_OVERSIZE) begin 
        nextState <= N6_PAYLOAD;
      end else begin 
        nextState <= N6_IDLE;
      end
    end 

    default: begin
    end
  endcase


  end : state_machine

  // assign phs = {tpdu_ipv4Header.destIP, tpdu_ipv4Header.sourceIP, tpdu_ipv4Header.protocol, tpdu_udpHeader.sourcePort, tpdu_udpHeader.destPort, tpdu_ipv4Header.typeOfService, tpdu_ipv4Header.timeToLive};

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


