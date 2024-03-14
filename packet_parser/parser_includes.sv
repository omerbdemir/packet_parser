`define BUS_WIDTH_B           (1)
`define BUFFER_WIDTH          (1518) //Number of bytes
`define COUNTER_WIDTH         32  //Number of bits



`define ETH_HDR_SIZE_B        14
`define IPV4_HDR_SIZE_B       20
`define UDP_HDR_SIZE_B        8
`define TCP_HDR_SIZE_MIN_B    20

`define BUFFER_WIDTH_BITS     (`BUFFER_WIDTH*8)
`define BYTE_WIDTH            8
`define BUS_WIDTH             (`BUS_WIDTH_B * `BYTE_WIDTH)


`define IPV4_HIGH_INDEX       (`IPV4_HDR_SIZE_B + 2)
`define IPV4_LOW_INDEX        2
`define UDP_HIGH_INDEX        (`UDP_HDR_SIZE_B + 2)
`define UDP_LOW_INDEX         2


`define TCP_OPTS_MAX_LEN      60  //bytes
`define TCP_OPTS_MIN_LEN      20  //bytes

`define IPV4_OPTS_MAX_LEN     15  //words
`define IPV4_HDR_MIN_LEN_W    5   //words

`define ETH_HDR_OVERSIZE      18  //bytes
`define MAX_PAYLOAD_LEN       (1518) // bytes

`define LEN_TILL_PROTOCOL_B   (9)
`define PROTOCOL_TCP          (8'h6)
`define PROTOCOL_UDP          (8'h11)


`define GTP_HDR_SIZE_B        (12)
`define PDU_HDR_SIZE_B        (6)
`define GTP_HIGH_INDEX        (`GTP_HDR_SIZE_B + 2)
`define GTP_LOW_INDEX         2
`define PDU_HIGH_INDEX        (`PDU_HDR_SIZE_B)
`define PDU_LOW_INDEX         0
`define GTP_OVERHEAD_SIZE     (`ETH_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `UDP_HDR_SIZE_B + `GTP_HDR_SIZE_B + `PDU_HDR_SIZE_B)

`define IPV4_VER_LEN_BITS     (4)
`define IPV4_IHL_LEN_BITS     (4)                 

`define ETH_HDR_SIZE_BITS     (`ETH_HDR_SIZE_B * `BYTE_WIDTH)

`define TCP_OFFSET_LEN_BITS   (4)
`define LEN_TILL_OFFSET_B     (12)

`define ETH_RIGHT_INDEX       ((`ETH_HDR_SIZE_BITS %  `BUS_WIDTH) ? (`BUS_WIDTH - (`ETH_HDR_SIZE_BITS % `BUS_WIDTH)): 0)
`define ETH_LEFT_INDEX        (`ETH_RIGHT_INDEX + `ETH_HDR_SIZE_BITS - 1)

`define IPV4_HDR_SIZE_BITS    (`IPV4_HDR_SIZE_B * `BYTE_WIDTH)
`define TILL_IPV4_HDR_BITS    (`ETH_HDR_SIZE_BITS + `IPV4_HDR_SIZE_BITS)


`define IPV4_RIGHT_INDEX      ((`TILL_IPV4_HDR_BITS % `BUS_WIDTH) ? (`BUS_WIDTH - (`TILL_IPV4_HDR_BITS % `BUS_WIDTH)): 0)
`define IPV4_LEFT_INDEX       (`IPV4_RIGHT_INDEX + `IPV4_HDR_SIZE_BITS - 1)

`define UDP_HDR_SIZE_BITS     (`UDP_HDR_SIZE_B * `BYTE_WIDTH)
`define TILL_UDP_HDR_BITS     (`TILL_IPV4_HDR_BITS + `UDP_HDR_SIZE_BITS)
`define UDP_RIGHT_INDEX       ((`TILL_UDP_HDR_BITS % `BUS_WIDTH) ? (`BUS_WIDTH - (`TILL_UDP_HDR_BITS % `BUS_WIDTH)): 0)
`define UDP_LEFT_INDEX        (`UDP_RIGHT_INDEX + `UDP_HDR_SIZE_BITS - 1)

`define TCP_HDR_SIZE_BITS     (`TCP_HDR_SIZE_MIN_B * `BYTE_WIDTH)
`define TILL_TCP_HDR_BITS     (`TILL_IPV4_HDR_BITS + `TCP_HDR_SIZE_BITS)
`define TCP_RIGHT_INDEX       ((`TILL_TCP_HDR_BITS % `BUS_WIDTH) ? (`BUS_WIDTH - (`TILL_TCP_HDR_BITS % `BUS_WIDTH)): 0)
`define TCP_LEFT_INDEX        (`TCP_RIGHT_INDEX + `TCP_HDR_SIZE_BITS - 1)




// `define 