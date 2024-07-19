package header_creator_pkg;
typedef struct packed {
    logic [7 : 0]             int_gate;
    logic [7 : 0]             DSCP;
    logic [15 : 0]            Q_ID;
  } ADS_N3;

typedef struct packed {
  logic [7:0] int_gate;
  logic [31 : 0] GTPU_TEID;
  logic [7:0] QFI;
  logic [15 : 0] Q_ID ;
} ADS_N6;

typedef enum logic [3:0] {
  N3_IDLE,
  N3_PKT_RCV,
  N3_PKT_MODIFY,
  N3_PKT_FWD
} HC_N3_STATES;
endpackage