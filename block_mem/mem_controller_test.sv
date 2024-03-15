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

module my_test_mod (); // {
  // local defines
  bit             CLK_test = 0;
  logic           reset;
  logic [31 : 0]  data_in;
  logic [3 : 0]   byte_valid;
  logic           wen;
  logic           w_last_pkt;
  logic [3 : 0]   id_out;
  logic           ren;
  logic [3 : 0]   r_id_in;
  logic [31 : 0]  data_out;
  logic           r_last_pkt;


  MemController  dut(
    .CLK(CLK_test),
    .reset(reset),
    .data_in(data_in),
    .byte_valid(byte_valid),
    .wen(wen),
    .w_last_pkt(w_last_pkt),
    .id_out(id_out),
    .ren(ren),
    .r_id_in(r_id_in),
    .data_out(data_out),
    .r_last_pkt(r_last_pkt)
  );



  real period_ns = 100ns;
   always begin

    #5;
    CLK_test = ~CLK_test;
    
   end

  initial
  begin // {
    reset = 1;
    wen = 0;
    ren = 0;
    data_in = 0;
    byte_valid = 0;
    w_last_pkt = 0;
    r_id_in = 0;
    #20;
    reset = 0;
    #100;
    data_in = 32'hdeadface;
    wen = 1;
    byte_valid = 4'hf;
    #10;
    r_id_in = 0;
    // wen = 0;
    ren = 1;



    #20;

    $stop();
  end // }

endmodule : my_test_mod // }

