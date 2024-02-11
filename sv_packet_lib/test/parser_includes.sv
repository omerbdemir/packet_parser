`define BUFFER_WIDTH          1500 //Number of bytes
`define BUFFER_WIDTH_BITS     (`BUFFER_WIDTH*8)
`define COUNTER_WIDTH         32  //Number of bits
`define ETH_HDR_SIZE_B        14
`define IPV4_HDR_SIZE_B       20
`define UDP_HDR_SIZE_B        8
`define TCP_HDR_SIZE_MAX_B    60
`define TCP_HDR_SIZE_MIN_B    20

`define ETH_HIGH_INDEX        (`ETH_HDR_SIZE_B + 2)
`define ETH_LOW_INDEX         2
`define IPV4_HIGH_INDEX       (`IPV4_HDR_SIZE_B + 2)
`define IPV4_LOW_INDEX        2
`define UDP_HIGH_INDEX        (`UDP_HDR_SIZE_B + 2)
`define UDP_LOW_INDEX         2
`define TCP_HIGH_INDEX        (`TCP_HDR_SIZE_MIN_B + 2)
`define TCP_LOW_INDEX         2


`define TCP_OPTS_MAX_LEN      60  //bytes
`define TCP_OPTS_MIN_LEN      20  //bytes

`define IPV4_OPTS_MAX_LEN     15  //words
`define IPV4_HDR_MIN_LEN_W    5   //words
`define WORD_LEN_BITS         32

`define ETH_HDR_OVERSIZE      18  //bytes
`define MAX_PAYLOAD_LEN       (1518) // bytes

`define GTP_HDR_SIZE_B          12
`define PDU_HDR_SIZE_B          6
`define GTP_HIGH_INDEX        (`GTP_HDR_SIZE_B + 2)
`define GTP_LOW_INDEX         2
`define PDU_HIGH_INDEX        (`PDU_HDR_SIZE_B)
`define PDU_LOW_INDEX         0
`define GTP_OVERHEAD_SIZE     (`ETH_HDR_SIZE_B + `IPV4_HDR_SIZE_B + `UDP_HDR_SIZE_B + `GTP_HDR_SIZE_B + `PDU_HDR_SIZE_B)
