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
// `include "C:/Users/omer_/vivado_projects/blk_mem_gen_0_ex/blk_mem_gen_0_ex.gen/sources_1/ip/blk_mem_gen_0/sim/blk_mem_gen_0.v"
// `include "../hdr_db/include/gcm-aes/sv-file/gcm_dpi.sv"
// import new_lib::*;
module my_test_mod (); // {

  // include files
  // `include "pktlib_class.sv"
  // `include "packet_parser_n3.sv"
  // `include "test/packet_parser_n6.sv"

  // local defines
  // pktlib_class p, p1;
  // bit [7:0]    p_pkt [], u_pkt [], p1_pkt[]; 
  // int          i, err;
  // logic [31:0] bus_tmp;
  // int remainder;
  bit CLK_test = 0;
  // logic reset;
  // logic [31:0] bus;
  // logic [31:0] phs_tb;
  // logic sop;
  // logic [31:0] plb;
  logic [31:0] addra;
  // logic clka;
  
  logic ena;
  logic enb;
  logic [3:0] wea;
  logic [31:0] dina;
  
  logic [31:0] addrb;
  logic rstb;
  logic [31:0] doutb;


  design_1_blk_mem_gen_0_0  dut(
    .addra(addra),
    .clka(CLK_test),
    .dina(dina),
    // .douta(douta),
    .ena(ena),
    // .rsta(plb),
    .wea(wea),
    .addrb(addrb),
    .clkb(CLK_test),
    .doutb(doutb),
    .enb(ena),
    .rstb(rstb)
  );


  real period_ns = 100ns;
   always begin

    #5;
      CLK_test = ~CLK_test;
   end


  initial
  begin // {
    ena = 1;
    enb = 1;
    #10;
    rstb = 1;
    #20;
    rstb = 0;
    addra = 32'h00000020;
    dina = 32'hdeadface;
    wea = 4'hf;
    #20;
    addrb = 32'h00000020;
    #20;






    #200;

    $stop();
  end // }

endmodule : my_test_mod // }

