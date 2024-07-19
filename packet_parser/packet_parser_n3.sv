`include "parser_includes.sv"
import parser_typedefs_pkg::*;


module PacketParserN3 (
  input logic   [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1:0]    bus, 
  input logic                   CLK,
  input logic                   reset,
  input logic                   start_of_packet_i,
  output logic [(15 * 8 - 1):0] phs_o,
  output logic                  phs_valid_o
);

  typedef struct packed {
    logic [31:0]              sourceIP;
    logic [31:0]              destIP;
    logic [15:0]              protocol;
    logic [15:0]              length;
  } Struct_PseudoHeader;

  // State machine states
  
  logic [(`BUFFER_WIDTH_BITS - 1):0]   data_buffer ;
  logic [3 : 0]                       ipv4_opts_len;
  logic [16 * 32 - 1 : 0]             ipv4_opts_buf;
  logic [15:0]                        udp_checksum;
  logic [2:0]                         udp_checksum_carry;

  bit [(`COUNTER_WIDTH - 1):0]        data_ctr;
  bit [(`COUNTER_WIDTH - 1) : 0]      opts_ctr;

  bit [(`COUNTER_WIDTH - 1) : 0]        tcp_opts_ctr;
  // State machine logic
  parser_typedefs_pkg::N3_STATES                           currentState, nextState;

  // Header fields
  parser_typedefs_pkg::EthernetHeader                      ethernetHeader;
  parser_typedefs_pkg::IPv4Header                          underlay_ipv4Header;
  parser_typedefs_pkg::UDPHeader                           gtp_udpHeader;
  parser_typedefs_pkg::GTPHeader                           gtpHeader;
  parser_typedefs_pkg::PDUHeader                           pduHeader;
  parser_typedefs_pkg::IPv4Header                          tpdu_ipv4Header;
  parser_typedefs_pkg::UDPHeader                           tpdu_udpHeader;
  parser_typedefs_pkg::TCPHeader                           tpdu_tcpHeader;
  parser_typedefs_pkg::PHS_Struct                          phs;
  
  Struct_PseudoHeader                 pseudoHeader;

  // Counters for tracking bits received
  int                                 bitsReceived;

  always_ff @( posedge CLK ) begin : udp_checksum_calc
    if(reset) begin 
      udp_checksum        <= 0;
      udp_checksum_carry  <= 0;
    end else begin 
      {udp_checksum_carry, udp_checksum} <= pseudoHeader.sourceIP[31:16] + pseudoHeader.sourceIP[15:0] + pseudoHeader.destIP[31:16] + pseudoHeader.destIP[15:0] + pseudoHeader.protocol + pseudoHeader.length + tpdu_udpHeader.sourcePort + tpdu_udpHeader.destPort + tpdu_udpHeader.length;  
    end
  end : udp_checksum_calc

  always_ff @( posedge CLK ) begin : buffer_data
    if(reset) begin
      data_buffer <= 0;
    end else begin
      for (int i = 0; i < (`BUFFER_WIDTH * 8)  - 32; i = i + 1) begin
        data_buffer[i + 32] <= data_buffer[i];
      end
      // data_buffer[(`BUFFER_WIDTH * 8 - 1) : 32] <= data_buffer[((`BUFFER_WIDTH - 4) * 8 - 1) : 0];
      data_buffer[31 : 0] <= bus;
    end
  end


  always_ff @( posedge CLK) begin : counter_inc
    if(reset)begin
      data_ctr <= 0;
    end else begin
      data_ctr <= data_ctr + `BUS_WIDTH_B;
      if(start_of_packet_i == 1'b1) begin
        data_ctr <= `BUS_WIDTH_B;
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
      if  ( currentState  ==  N3_TCP_1_OPTS  ) begin 
        tcp_opts_ctr  <= tcp_opts_ctr + (`BUS_WIDTH_B);
      end
      if  ( (currentState == N3_IPV4_OPTS) || (currentState == N3_IPV4_1_OPTS) ) begin 
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
      currentState <= N3_IDLE;
    end else begin
      currentState <= nextState;
    end
    
  end

  always_ff @( posedge CLK ) begin : pseudoHeader_creation
    if(reset) begin 
      pseudoHeader <= 0;
    end else begin 

      if ((currentState == N3_UDP_1) && (nextState != N3_UDP_1))begin 
        pseudoHeader.sourceIP <= tpdu_ipv4Header.sourceIP;
        pseudoHeader.destIP   <= tpdu_ipv4Header.destIP;
        pseudoHeader.protocol <= tpdu_ipv4Header.protocol;

      end else if (currentState == N3_PAYLOAD) begin  
        pseudoHeader.length   <= tpdu_udpHeader.length;

      end else begin 
        pseudoHeader <= pseudoHeader;
      end
    end 
  end : pseudoHeader_creation

  always_comb begin : state_machine
  nextState <= currentState;
  case (currentState)
    N3_IDLE : begin

        ethernetHeader          <= 0;
        underlay_ipv4Header     <= 0;
        tpdu_tcpHeader          <= 0;
        gtp_udpHeader           <= 0;
        gtpHeader               <= 0;
        pduHeader               <= 0;
        tpdu_ipv4Header         <= 0;
        tpdu_udpHeader          <= 0;
        ipv4_opts_buf           <= 0;
        ipv4_opts_len           <= 0;
    end
    
    N3_ETH: begin
      if(data_ctr >= `ETH_HDR_SIZE_B) begin
        ethernetHeader <= data_buffer[(16 * 8) - 1: 16];
        nextState <= N3_IPV4;
      end

    end

    N3_IPV4: begin

      if(data_ctr >= `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        underlay_ipv4Header <= data_buffer[(`IPV4_HIGH_INDEX * 8) - 1 : (`IPV4_LOW_INDEX) * 8];
        if (data_buffer[(`IPV4_HIGH_INDEX * 8) - 5 : (`IPV4_HIGH_INDEX * 8) - 8] > 5) begin
          // ipv4_opts_len <= data_buffer[(`IPV4_HIGH_INDEX * 8) - 5 : (`IPV4_HIGH_INDEX * 8) - 8];
          ipv4_opts_len <= data_buffer[ `IPV4_LEFT_INDEX - `IPV4_VER_LEN_BITS -: `IPV4_IHL_LEN_BITS];
          $display("IPV4 left index = : %h IPv4 ver len bits = %h, IPv4 IHL len bits = %h", `IPV4_LEFT_INDEX, `IPV4_VER_LEN_BITS, `IPV4_IHL_LEN_BITS);
          nextState <= N3_IPV4_OPTS;
        end else begin 
          ipv4_opts_len <= 4'h5; 
          nextState <= N3_UDP;
        end
      end
    end

    N3_IPV4_OPTS : begin 

      ipv4_opts_buf[(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0] <= data_buffer[47 : 16];
      for (int i = 0; i < (`IPV4_OPTS_MAX_LEN - 1) * (`BUS_WIDTH_B * `BYTE_WIDTH); i = i + 1) begin
        ipv4_opts_buf[i + (`BUS_WIDTH_B * `BYTE_WIDTH)] <= ipv4_opts_buf[i];
      end
      if (opts_ctr < (ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4 - 1) begin 
        nextState <= N3_IPV4_OPTS;
      //Determine the next header type from protocol field in IPv4 header
      end else  begin 
        if (tpdu_ipv4Header.protocol == `PROTOCOL_UDP)begin 
          nextState <= N3_UDP;
        end else begin 
          nextState <= N3_IDLE;
        end
      end 

    end
    N3_UDP : begin
      if(data_ctr >= `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
        gtp_udpHeader <= data_buffer[`UDP_LEFT_INDEX -: `UDP_HDR_SIZE_BITS];
        nextState <= N3_GTP;
      end 
      // if(data_ctr >= `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B) begin 
      //   gtp_udpHeader <= data_buffer[ (`UDP_HIGH_INDEX * 8) - 1 : `UDP_LOW_INDEX * 8];
      //   // pseudoHeader.length <= gtp_udpHeader.length;
      //   nextState <= N3_GTP;
      // end 
    end

    N3_GTP : begin 
      if(data_ctr >= `GTP_HDR_SIZE_B + `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B + ((ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4)) begin 
        $display("IPv4 opts len : %h", ipv4_opts_len);
        $display("Data counter : %h", data_ctr);
        gtpHeader <= data_buffer[(`GTP_HIGH_INDEX * 8) - 1 : `GTP_LOW_INDEX * 8];
        nextState <= N3_PDU;
      end 
    end 

    N3_PDU : begin 

      if(data_ctr >= `PDU_HDR_SIZE_B + `GTP_HDR_SIZE_B + `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `ETH_HDR_SIZE_B + ((ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4)) begin 
        pduHeader <= data_buffer[ (`PDU_HIGH_INDEX * 8) - 1 : `PDU_LOW_INDEX * 8];
        nextState <= N3_IPV4_1;
      end

    end

    N3_IPV4_1 : begin 

      if(data_ctr >= `IPV4_HDR_SIZE_B + `GTP_OVERHEAD_SIZE + ((ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4)) begin 
        tpdu_ipv4Header <= data_buffer[(`IPV4_HDR_SIZE_B + (`IPV4_HDR_SIZE_B % 4)) * 8 - 1 : (`IPV4_HDR_SIZE_B % 4) * 8];
        $display("Value of searched index  = %h", data_buffer[(`IPV4_HDR_SIZE_B * 8) - 5 -: 4 ]);
        if (data_buffer[(`IPV4_HDR_SIZE_B * 8) - 5 -: 4] > 5) begin
          ipv4_opts_len <= data_buffer[(`IPV4_HDR_SIZE_B * 8) - 5 -: 4];
          nextState <= N3_IPV4_1_OPTS;
        end else begin 
          nextState <= N3_UDP_1;
        end
      end 

    end 

    N3_IPV4_1_OPTS : begin 
      ipv4_opts_buf[(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0] <= data_buffer[31 : 0];
      for (int i = 0; i < (`IPV4_OPTS_MAX_LEN - 1) * 32; i = i + 1) begin
        ipv4_opts_buf[i + 32] <= ipv4_opts_buf[i];
      end
      if (opts_ctr < (ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4 - 1) begin 
        nextState <= N3_IPV4_1_OPTS;
      end else begin 
        if (tpdu_ipv4Header.protocol == 17)begin 
          nextState <= N3_UDP_1;
        end else begin 
          nextState <= N3_TCP_1;
        end
      end
    end 

    N3_UDP_1 : begin 
      if(data_ctr >= `UDP_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `GTP_OVERHEAD_SIZE) begin 
        tpdu_udpHeader <= data_buffer[(`UDP_HDR_SIZE_B + (`UDP_HDR_SIZE_B % 4)) * 8 - 1 : (`UDP_HDR_SIZE_B % 4) * 8];
        // pseudoHeader.length   <=  tpdu_udpHeader.length;
        nextState <= N3_PAYLOAD;
      end 

    end 

    N3_TCP_1 : begin 
      if(data_ctr >= `TCP_HDR_SIZE_MIN_B + `IPV4_HDR_SIZE_B + `GTP_OVERHEAD_SIZE + ((ipv4_opts_len - `IPV4_HDR_MIN_LEN_W) * 4)) begin 
        tpdu_tcpHeader <= data_buffer[(`TCP_HDR_SIZE_MIN_B + (`TCP_HDR_SIZE_MIN_B % 4)) * 8 - 1 : (`TCP_HDR_SIZE_MIN_B % 4) * 8];
        nextState <= N3_PAYLOAD;
      end 
    end 

    N3_PAYLOAD : begin 
      if(data_ctr >= gtpHeader.length) begin 
        nextState <= N3_IDLE;
      end
    end 

    default: begin
    end
  endcase
  if(start_of_packet_i == 1'b1) begin
        nextState <= N3_ETH;
  end


  end : state_machine

  always_comb begin : phs_assign
    if(tpdu_ipv4Header.protocol == 17) begin 
      phs = {8'h03,tpdu_ipv4Header.typeOfService, tpdu_udpHeader.sourcePort, tpdu_udpHeader.destPort, tpdu_ipv4Header.protocol, tpdu_ipv4Header.sourceIP, tpdu_ipv4Header.destIP};
    end else begin 
      phs = {8'h03,tpdu_ipv4Header.typeOfService, tpdu_tcpHeader.sourcePort, tpdu_tcpHeader.destPort, tpdu_ipv4Header.protocol, tpdu_ipv4Header.sourceIP, tpdu_ipv4Header.destIP};
    end

    if(((currentState == N3_TCP_1) && (nextState != N3_TCP_1)) || ((currentState == N3_UDP_1) && (nextState != N3_UDP_1))) begin 
      phs_valid_o = 1'b1;
    end else begin 
      phs_valid_o = 1'b0;
    end 

  end

  // assign phs = {tpdu_ipv4Header.destIP, tpdu_ipv4Header.sourceIP, tpdu_ipv4Header.protocol, tpdu_udpHeader.sourcePort, tpdu_udpHeader.destPort, tpdu_ipv4Header.typeOfService, tpdu_ipv4Header.timeToLive};
  assign phs_o = phs;
  


endmodule


