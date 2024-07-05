module HeaderCreatorN3ToN6(
  input logic             CLK,
  input logic             reset,
  input logic   [31 : 0]  packet_i,
  input logic             packet_valid_i,
  input ADS_N3            ADS_INPUT,

  output logic  [15 : 0]  packet_id_o,
  output logic            packet_read_req_o,
);

HC_N3_STATES currentState, nextState;

always @(currentState) begin : state_machine
  nextState <= currentState;
  case (currentState)
    IDLE: begin
      
    end
    PKT_RCV: begin 

    end
    PKT_MODIFY: begin 

    end 
    PKT_FWD: begin 

    end
    default: 
  endcase
end 

always @(posedge CLK) begin : state_transition
  if (reset) begin 
    currentState <= IDLE;
  end else begin 
    currentState <= nextState;
  end 
end

endmodule