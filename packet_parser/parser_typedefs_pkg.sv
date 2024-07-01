

  // typedef logic [7:0] EthernetAddress;
  // typedef logic [7:0] octet;
  // Ethernet Header


package parser_typedefs_pkg;
  typedef enum logic[3:0]{
    N3_IDLE,
    N3_ETH,
    N3_IPV4,
    N3_IPV4_OPTS,
    N3_UDP,
    N3_GTP,
    N3_PDU,
    N3_IPV4_1,
    N3_IPV4_1_OPTS,
    N3_UDP_1,
    N3_TCP_1,
    N3_TCP_1_OPTS,
    N3_PAYLOAD
  }N3_STATES;

  typedef struct packed {
    logic [7 : 0]             msg_type;
    logic [15 : 0]            length;
    logic [31 : 0]            teid;
    logic [15 : 0]            seq_num;
    logic [7 : 0]             n_pdu;
    logic [7 : 0]             nxt_hdr_type;
  } GTPHeader;

  typedef struct packed {
    logic [7 : 0]             length;
    logic [7 : 0]             flags;
    logic                     ppp;
    logic                     rqi;
    logic [5 : 0]             qfi;
    logic [15 : 0]            padding;
    logic [7 : 0]             nxt_hdr_type;
  } PDUHeader;

  typedef struct packed{
    logic [7:0]               incoming_interface;
    logic [7:0]               dscp;
    logic [15:0]              transport_src_port;
    logic [15:0]              transport_dst_port;
    logic [7:0]               transport_protocol;
    logic [31:0]              ipv4_src_addr;
    logic [31:0]              ipv4_dst_addr;
  }PHS_Struct;

  typedef struct packed {
    logic [47 : 0]              destMac;
    logic [47 : 0]              srcMac;
    logic [15 : 0]              etherType;
    // logic [7:0]               sfd;
    // logic [55:0]              preamble;
  } EthernetHeader;

  // IPv4 Header
  typedef struct packed {
    logic [3:0]               version;
    logic [3:0]               headerLength; 
    logic [7:0]               typeOfService;
    logic [15:0]              totalLength;
    logic [15:0]              identification;
    logic [12:0]              fragmentOffset;
    logic [2:0]               flags;
    logic [7:0]               timeToLive;
    logic [7:0]               protocol;
    logic [15:0]              headerChecksum;
    logic [31:0]              sourceIP;
    logic [31:0]              destIP;
  } IPv4Header;

  // TCP Header
  typedef struct packed {
    logic [15:0]              sourcePort;
    logic [15:0]              destPort;
    logic [31:0]              sequenceNumber;
    logic [31:0]              ackNumber;
    logic [3:0]               dataOffset;
    logic [3:0]               rsvrd;
    logic [7:0]               flags;
    logic [15:0]              windowSize;
    logic [15:0]              checksum;
    logic [15:0]              urgentPointer;
    // logic [(40 * 8) - 1 : 0]  options;
  } TCPHeader;

  // UDP Header
  typedef struct packed {
    logic [15:0]              sourcePort;
    logic [15:0]              destPort;
    logic [15:0]              length;
    logic [15:0]              checksum;
  } UDPHeader;

  // State machine states
  
  
  typedef enum logic[3:0]{
    N6_IDLE,
    N6_ETH,
    N6_IPV4,
    N6_IPV4_OPTS,
    N6_UDP,
    N6_TCP,
    N6_TCP_OPTS,
    N6_PAYLOAD
  }N6_STATES;
endpackage