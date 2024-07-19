module checksum_gen(
  input wire           clk,
  input wire           reset,


  input wire [15 : 0]  old_checksum,
  input wire [15 : 0]  removed_val,
  input wire [15 : 0]  new_val,
  input wire           req,

  output wire          gnt,
  output wire [15 : 0] new_checksum
);

  typedef enum logic [1:0] {
        IDLE  = 2'b00,
        RM = 2'b01,
        UPDT = 2'b10
    } state_t;
  logic [15 : 0]  old_checksum_i;
  logic [15 : 0]  removed_val_i;
  logic [15 : 0]  new_val_i;
  logic           gnt_o;
  logic [15 : 0]  new_checksum_o;
  logic [15 : 0]  temp_checksum;
  state_t   currentState, nextState;
  always_ff @( posedge clk ) begin : calc_checksum;
    if(reset) begin 
      gnt_o <= 0;
      new_checksum_o  <=  0;
      temp_checksum   <=  0;
      old_checksum_i  <=  0;
      removed_val_i   <=  0;
      new_val_i       <=  0;
    end else begin
      gnt_o           <=  gnt_o;
      case (currentState)
        IDLE : begin 
          gnt_o           <= 0;
          new_checksum_o  <= new_checksum_o;
          old_checksum_i  <=  old_checksum;
          removed_val_i   <=  removed_val;
          new_val_i       <=  new_val;  
        end 
        RM : begin  
          temp_checksum   <= ~(old_checksum_i) + ~(removed_val_i);
          gnt_o           <= 1'b0;
        end
        UPDT: begin 
          new_checksum_o  <= ~(temp_checksum + new_val_i + 1);
          gnt_o            <= 1'b1;
        end   
      endcase
    end

  end

  always_comb begin : StateTransition
    case (currentState)
      IDLE : begin 
        if(req) begin 
          nextState <= RM;
        end 
      end 
      RM : nextState <= UPDT;
      UPDT : nextState <= IDLE;
      default: nextState <= IDLE;
    endcase
  end

  always_ff @( posedge clk ) begin : blockName
    if(reset) begin 
      currentState <= IDLE;
    end else begin 
      currentState <= nextState;
    end 
  end

  assign new_checksum = new_checksum_o;
  assign gnt          = gnt_o;

endmodule