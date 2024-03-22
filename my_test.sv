/*
Copyright (c) 2011, Sachin Gandhi
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// ----------------------------------------------------------------------
// This test 
// 1. pack_hdr    - Configures (cfg_hdr) 10 different types of headers
//                  and pack into array of pkt.
// 2. unpack_hdr  - Smartly Unpacks the pkt array into headers
// 3. copy_hdr    - Copies pktlib of each pkt to diffent pktlib
// 4. compare_pkt - From two arrays of pkts, it unpacks them and compares them.
//                  (Compare functionality doesn't work when we have 
//                   pth, ptl2, ptip in cfg_hdr)
//
// ----------------------------------------------------------------------

`define NUM_PKTS 1

`include "../hdr_db/include/gcm-aes/sv-file/gcm_dpi.sv"
module my_test_mod (); // {

  // include files
  `include "pktlib_class.sv"
  `include "packet_parser/parser_includes.sv"

  // local defines
  pktlib_class p, p1;
  bit [7:0]    p_pkt [], u_pkt [], p1_pkt[]; 
  int          i, j, err;
  int remainder;
  bit CLK_test = 0;
  logic reset;
  logic [(`BUS_WIDTH_B * `BYTE_WIDTH):0] bus;
  logic [31:0] phs_tb;
  logic sop;
  logic [31:0] plb;
  PacketParserN6  dut(
    .bus(bus),
    .CLK(CLK_test),
    .reset(reset),
    .start_of_packet_i(sop),
    .phs_o(phs_tb),
    .pay_last_word(plb)
  );

  // PacketParserN3  dut(
  //   .bus(bus),
  //   .CLK(CLK_test),
  //   .reset(reset),
  //   .start_of_packet_i(sop),
  //   // .pay_last_word(plb),
  //   .phs_o(phs_tb)
  // );
  real period_ns = 100ns;
   always begin

    #5;
    // if(reset) begin
    //   CLK_test = 0;
    // end else begin
      CLK_test = ~CLK_test;
    
    // end
   end
  // always_ff @( posedge CLK_test or negedge reset) begin : blockName
  //   if(~reset) begin
  //     bus <= 32'h12345678;
  //   end else begin
  //     bus <= {bus[23:0], bus[31:24]};
  //   end
  // end

  initial
  begin // {
    // CLK_test = 0;
    // bus = 0;
    remainder = 0;
    reset = 1;
    sop = 0;  
    #20;
    reset = 0;
    p = new();
    p1 = new();
    p.cfg_hdr('{p.eth[0], p.ipv4[0], p.udp[0], p.data[0] });
    p1.cfg_hdr('{p1.eth[0], p1.ipv4[0], p1.tcp[0], p1.data[0]});

    // p.cfg_hdr('{p.eth[0], p.ipv4[0], p.udp[0], p.gtp[0], p.pdu[0], p.ipv4[1], p.udp[1], p.data[0] });
    // p1.cfg_hdr('{p1.eth[0], p1.ipv4[0], p1.udp[0], p1.gtp[0], p1.pdu[0], p1.ipv4[1], p1.tcp[0], p1.data[0]});

    p1.toh.max_plen = 500;
    p1.toh.min_plen = 20;

    p.toh.max_plen = 600;
    p.toh.min_plen = 4;

    p.randomize with
    {
      data[0].data_len > 10;
      data[0].data_len < 20;
      ipv4[0].ihl < 6;
      // tcp[0].offset > 6;
    };

    p1.randomize with
    {
      data[0].data_len > 10;
      data[0].data_len < 20;
      ipv4[0].ihl > 6;
      tcp[0].offset > 6;
    };
    p.pack_hdr(p_pkt);
    $display("%0t : INFO : TEST : Pack pkt %0d", $time, i + 1);

    p.display_hdr_pkt(p_pkt);
    $display("plen of packet 0 = %0d", p.toh.plen);
    // $display("mokoko");
    // $display("%0d", p_pkt[0]);
    // p1 = new();
    // p.unpack_hdr(p_pkt, SMART_UNPACK,, FC);
    // $display("%0t : INFO    : TEST    : Unpack Pkt %0d", $time, i + 1);
    // p.display_hdr_pkt(p_pkt); 
    for(i = 0; i < p.toh.plen / `BUS_WIDTH_B; i++)
    begin
      for (int j = 0; j < `BUS_WIDTH_B; j++) begin
        bus = {bus, p_pkt[i * `BUS_WIDTH_B + j]};
      end

      // bus = {p_pkt[i * 4], p_pkt[i * 4 + 1], p_pkt[i * 4 + 2], p_pkt[i * 4 + 3]};
      // bus = {p_pkt[i * 4 + 3], p_pkt[i * 4 + 2], p_pkt[i * 4 + 1], p_pkt[i * 4]};
      if(i == 0) begin
        sop = 1;
      end else begin
        sop = 0;
      end
      #10;
    end
    remainder = p.toh.plen % `BUS_WIDTH_B;
    case (remainder)
    0: begin
           // Handle case where remainder is 0
       end
    default: begin
                 bus = '0; // Initialize bus with all zeroes
                 for (int j = 0; j < remainder; j++) begin
                     bus = {p_pkt[p.toh.plen - (j+1)], bus};
                 end
             end
    endcase

    #10;

    p1.pack_hdr(p1_pkt);
    $display("%0t : INFO : TEST : Pack pkt %0d", $time, i + 1);


    p1.display_hdr_pkt(p1_pkt);
    
    for(i = 0; i < p1.toh.plen / `BUS_WIDTH_B; i++)
    begin 
      for (int j = 0; j < `BUS_WIDTH_B; j++) begin
        bus = {bus, p1_pkt[i * `BUS_WIDTH_B + j]};
      end
      if(i == 0) begin 

        sop = 1;
      end else begin 
        sop = 0;
      end 
      #10;
    end 

    remainder = p1.toh.plen % `BUS_WIDTH_B;
    case (remainder)
    0: begin
           // Handle case where remainder is 0
       end
    default: begin
                 bus = '0; // Initialize bus with all zeroes
                 for (int j = 0; j < remainder; j++) begin
                     bus = {p1_pkt[p.toh.plen - (j+1)], bus};
                 end
             end
    endcase
    #20;
    // for (i = 0; i < `NUM_PKTS; i++)
    // begin // {
    //     // new pktlib
    //     p = new();
        
    //     // configure different hdrs for this packet
    //     case (i%`NUM_PKTS) // {
    //         0  : p.cfg_hdr ('{p.eth[0], p.ipv4[0], p.udp[0], p.gtp[0],  p.pdu[0], p.ipv4[1], p.udp[1], p.data[0]});
    //     endcase // }
        
    //     // set max/min packet length
    //     p.toh.max_plen = 600;
    //     p.toh.min_plen = 4;

    //     // randomize pktlib
    //     p.randomize with  
    //     {
    //       data[0].data_len > 5;
    //     };
        
    //     // pack all the hdrs to pkt
    //     p.pack_hdr (p_pkt);
        
    //     // display hdr and pkt content
    //     $display("%0t : INFO    : TEST      : Pack Pkt %0d", $time, i+1);
    //     //p.display_hdr_pkt (p_pkt, , , , DISPLAY_FULL);
    //     p.display_hdr_pkt (p_pkt);

	// // new pktlib for unpack
  //       p = new();
        
  //       // unpack 
  //      if (i == 17)
  //           p.unpack_hdr (p_pkt, SMART_UNPACK,, FC);
  //      else if (i > 17)
  //           p.unpack_hdr (p_pkt, SMART_UNPACK,, MIPI_CSI2_DPHY);
  //      else
  //           p.unpack_hdr (p_pkt, SMART_UNPACK);

  //       // display hdr and pkt content
  //       $display("%0t : INFO    : TEST      : Unpack Pkt %0d", $time, i+1);
  //       p.display_hdr_pkt (p_pkt);

  //       // new pktlib for copy
  //       p1 = new ();

  //       // copy p to p1
  //       p1.cpy_hdr (p);

  //       // display hdr and pkt content
  //       $display("%0t : INFO    : TEST      : Copy Pkt %0d", $time, i+1);
  //       p1.display_hdr_pkt (p1.pkt);

	// // new pktlib for compare
  //       p = new();
  //       u_pkt = new [p_pkt.size] (p_pkt);

  //       // corrupt few pkt to make sure Compare ctaches it
  //       if (i == 3)
  //       begin // {
  //           u_pkt[13] = $random;
  //       end // } 
  //       if (i == 5)
  //       begin // {
  //           u_pkt[22] = $random;
  //       end // } 

  //       $display("%0t : INFO    : TEST      : Compare Pkt %0d", $time, i+1);
  //       if (i == 17)
  //           p.compare_pkt (p_pkt, u_pkt, err,, FC);
  //       else if (i > 17)
  //           p.compare_pkt (p_pkt, u_pkt, err,, MIPI_CSI2_DPHY);
  //       else
  //           p.compare_pkt (p_pkt, u_pkt, err);
    // end // }
    // end simulation
    // #1000ns
    $stop();
  end // }

endmodule : my_test_mod // }

