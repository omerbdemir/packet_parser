module PacketParser (
  input logic [31:0] bus,
  input logic CLK,
  input logic reset
);

  typedef logic [7:0]   EthernetAddress [5:0];

  // Ethernet Header
  typedef struct packed {
    EthernetAddress destMac;
    EthernetAddress srcMac;
    logic [15:0]      etherType;
  } EthernetHeader;

  // IPv4 Header
  typedef struct packed {
    logic [3:0]   version;
    logic [3:0]   headerLength;
    logic [7:0]   typeOfService;
    logic [15:0]  totalLength;
    logic [15:0]  identification;
    logic [2:0]   flags;
    logic [12:0]  fragmentOffset;
    logic [7:0]   timeToLive;
    logic [7:0]   protocol;
    logic [15:0]  headerChecksum;
    logic [31:0]  sourceIP;
    logic [31:0]  destIP;
  } IPv4Header;

  // TCP Header
  typedef struct packed {
    logic [15:0]  sourcePort;
    logic [15:0]  destPort;
    logic [31:0]  sequenceNumber;
    logic [31:0]  ackNumber;
    logic [3:0]   dataOffset;
    logic [11:0]  flags;
    logic [15:0]  windowSize;
    logic [15:0]  checksum;
    logic [15:0]  urgentPointer;
  } TCPHeader;

  // UDP Header
  typedef struct packed {
    logic [15:0]  sourcePort;
    logic [15:0]  destPort;
    logic [15:0]  length;
    logic [15:0]  checksum;
  } UDPHeader;

  // State machine states
  typedef enum logic [2:0] {
    IDLE,
    ETHERNET_HEADER,
    IP_HEADER,
    TCP_HEADER,
    UDP_HEADER
  } State;

  // State machine logic
  State currentState, nextState;

  // Header fields
  EthernetHeader ethernetHeader;
  IPv4Header ipv4Header;
  TCPHeader tcpHeader;
  UDPHeader udpHeader;

  // Counters for tracking bits received
  int bitsReceived;

  always_ff @(posedge CLK or posedge reset) begin
    if (reset) begin
      // Reset logic (if needed)
      currentState <= IDLE;
      bitsReceived <= 0;
    end else begin
      currentState <= nextState;
      bitsReceived <= bitsReceived + 1;
    end
  end

  // Combinational logic for state transitions and header parsing
  always_ff @(posedge CLK) begin
    // Default next state
    nextState = currentState;

    // Parsing logic
    case (currentState)
      IDLE: begin
        // Check for start of packet and transition to Ethernet header state
        if (bus[31:0] == 32'hdeadbeef) begin
          nextState = ETHERNET_HEADER;
          bitsReceived <= 0;
        end
      end

      ETHERNET_HEADER: begin
        // Parse Ethernet header
        ethernetHeader.destMac = bus[47:0];
        ethernetHeader.srcMac = bus[95:48];
        ethernetHeader.etherType = bus[111:96];

        // Check if the entire header has been received
        if (bitsReceived == 112) begin
          nextState = IP_HEADER;
          bitsReceived <= 0;
        end
      end

      IP_HEADER: begin
        // Parse IPv4 header
        ipv4Header = bus >> 160;

        // Check protocol to determine the next header state
        case (ipv4Header.protocol)
          8'h06: nextState = TCP_HEADER;
          8'h11: nextState = UDP_HEADER;
          // Handle other protocols if needed
        endcase
      end

      TCP_HEADER: begin
        // Parse TCP header
        tcpHeader = bus >> 320;

        // Check if the entire header has been received
        if (bitsReceived == 320) begin
          nextState = IDLE;
          bitsReceived <= 0;
        end
      end

      UDP_HEADER: begin
        // Parse UDP header
        udpHeader = bus >> 320;

        // Check if the entire header has been received
        if (bitsReceived == 320) begin
          nextState = IDLE;
          bitsReceived <= 0;
        end
      end
    endcase
  end

endmodule
