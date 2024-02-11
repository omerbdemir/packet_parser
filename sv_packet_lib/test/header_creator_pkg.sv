  typedef struct packed {
    logic [7 : 0]             int_gs;
    logic [15 : 0]            gtpu_teid;
    logic [31 : 0]            qfi;
    logic [15 : 0]            q_id;
  } HC_N6_to_N3;

    typedef struct packed {
    logic [7 : 0]             int_gs;
    logic [15 : 0]            dscp;
    logic [31 : 0]            q_id;
  } HC_N3_to_N6;

