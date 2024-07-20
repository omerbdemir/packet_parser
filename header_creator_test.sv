/*
Copyright (c) 2011, Sachin Gandhi
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

`define NUM_PKTS 1
`include "../hdr_db/include/gcm-aes/sv-file/gcm_dpi.sv"
module headerCreatorTest (); // {
  timeunit 1ns;
  // include files
  `include "pktlib_class.sv"
  `include "header_creator/header_creator_includes.svh"
  import header_creator_pkg::*; 
  // local defines
  int remainder;
  bit CLK_test = 0;
  
  logic reset;
  logic [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0 ] bus;
  logic sop;
  header_creator_pkg::ADS_N3 ads;
  logic [15 : 0] packet_id;
  logic packet_read_req;
  logic [15 : 0] test_var, test_var1, test_var2, test_var3, upper, lower, upper1, upper2, lower2, lower1, my_var, my_checksum, checksum, test_checksum;
  logic [31 : 0] sum, sum1, orig_sum, reversed_sum, my_sum;

  mailbox my_mbx;

  

  interface hc_n3_to_n6_intf(input logic clk);
    logic                                         reset;
    logic [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0 ] bus_tmp;
    logic [(`BUS_WIDTH_B * `BYTE_WIDTH) - 1 : 0 ] bus;
    logic                                         sop;
    header_creator_pkg::ADS_N3                    ads;
    logic [15 : 0]                                packet_id;
    logic                                         packet_read_req;

    clocking cb_hc @(posedge clk);
      default input #1 output #2;
      output            reset;
      input             packet_id, packet_read_req;
      output            sop, bus, ads;
    endclocking

    task set_sop(int num_repeat, mailbox my_mbx);
      cb_hc.sop   <= 0;
      repeat (num_repeat) @(cb_hc);
      cb_hc.sop   <= 1;
      my_mbx.put(1);
    endtask

    task read_packet(mailbox my_mbx);
      pktlib_class p, p1;
      bit [7:0]    p_pkt [], u_pkt [], p1_pkt[]; 

      p = new();
      p.cfg_hdr('{p.ipv4[0], p.udp[0],  p.data[0] });
      
      p.toh.max_plen = 600;
      p.toh.min_plen = 4;

      p.randomize with
      {
        data[0].data_len  > 10;
        data[0].data_len  < 20;
        ipv4[0].ihl       < 6;
      };
      test_var = p.ipv4[0].tos;
      p.ipv4[0].tos[7 -: 6] = 6'h32;
      p.pack_hdr(p_pkt);
      test_var1 = p.ipv4[0].checksum;
      p.display_hdr_pkt(p_pkt);

      p.ipv4[0].tos = test_var;
      p.pack_hdr(p_pkt);

      $display("Modified checksum val %h", test_var1);
      $display("%0t : INFO : TEST : Pack pkt", $time);
      p.display_hdr_pkt(p_pkt);
      for(int i = 0; i < p.toh.plen / `BUS_WIDTH_B; i++) 
      begin 
        for (int j = 0; j < `BUS_WIDTH_B; j++) 
        begin 
          bus_tmp = {bus_tmp, p_pkt[i * `BUS_WIDTH_B + j]};
        end 
        cb_hc.bus <= bus_tmp;
        if(i == 0) begin 
          cb_hc.sop <= 1;
          my_mbx.put(1);
        end else begin 
          cb_hc.sop <= 0;
        end 
        @(cb_hc);
      end   

    endtask 

    task wait_sop(mailbox my_mbx);
    int temp_val;
      cb_hc.reset <= 0;
      // @(posedge cb_hc.sop);
      for (int i = 0 ; i < 20 ; i++) begin
        my_mbx.try_get(temp_val);
         $display("Value of SOP %d Time: %0t mailbox message : %d wait sop",cb_hc.sop,  $time, temp_val);
        if(temp_val == 1) begin 
          break;
        end 
        cb_hc.reset <= ~reset;
        @(cb_hc); 

      end
    $display("Wait sop completion time %0t", $time);
    endtask

    task set_ads(mailbox my_mbx);
    int i;
      my_mbx.get(i);
      cb_hc.ads.DSCP      <=  8'h32;
      cb_hc.ads.Q_ID      <=  16'h1324;
      cb_hc.ads.int_gate  <=  8'hab;
    endtask

    task reset_all();

      reset = 0;
      sop = 0;
      ads = 0;
      bus = 0;

    endtask
  endinterface
  
  hc_n3_to_n6_intf my_intface(CLK_test);

  HeaderCreatorN3ToN6 dut(
    .CLK                (my_intface.clk),
    .reset              (my_intface.reset),
    .packet_bus_i       (my_intface.bus),
    .start_of_packet_i  (my_intface.sop),
    .ads_input_i        (my_intface.ads),
    .packet_id_o        (my_intface.packet_id),
    .packet_read_req_o  (my_intface.packet_read_req)
  );

  real period_ns = 100ns;

  always begin
    CLK_test = ~CLK_test;
    #5;
  end

  initial begin 
    my_intface.reset_all;
    @(my_intface.cb_hc) my_intface.cb_hc.reset   <=  1;
    @(my_intface.cb_hc) my_intface.cb_hc.reset   <=  0;
    my_mbx = new();
    fork 
      begin 
        my_intface.read_packet(my_mbx);
      end
      begin
        my_intface.set_ads(my_mbx);
        @(my_intface.cb_hc);
      end 
    join_any
    #100;
    $stop();
  end 

  // always begin 

  // end    

/*
  default clocking cb_counter @(posedge CLK_test);
      default input #1step output #3;
      output posedge reset;
      output bus, ads, sop;
      input packet_read_req;
  endclocking
  initial
  begin 
    // p1.cfg_hdr('{p1.ipv4[0], p1.udp[0], p1.gtp[0], p1.pdu[0], p1.ipv4[1], p1.tcp[0], p1.data[0]});

    cb_counter.bus             <=  0;
    cb_counter.sop             <=  0;
    cb_counter.ads             <=  0;
    test_var        <=  0;
    sum             <=  0;
    ## 2;
    ## 1 cb_counter.reset <= 1;
    cb_counter.reset <= 0;
    #10;
    p = new();
    p.cfg_hdr('{p.ipv4[0], p.udp[0],  p.data[0] });

    p.toh.max_plen = 600;
    p.toh.min_plen = 4;

    p.randomize with
    {
      data[0].data_len > 10;
      data[0].data_len < 20;
      ipv4[0].ihl < 6;
      // tcp[0].offset > 6;
    };

    p.pack_hdr(p_pkt);
  
    p.display_hdr_pkt(p_pkt);
    $display("plen of packet 0 = %0d", p.toh.plen);
    for(int i = 0; i < p.toh.plen / `BUS_WIDTH_B; i++)
    begin
      for (int j = 0; j < `BUS_WIDTH_B; j++) begin
        cb_counter.bus <= {bus, p_pkt[i * `BUS_WIDTH_B + j]};
      end
      if(i == 0) begin
        sop = 1;
      end else begin
        sop = 0;
      end
      #10;
    end
    remainder = p.toh.plen % `BUS_WIDTH_B;
    cb_counter.bus <= '0; // Initialize bus with all zeroes
    for (int j = 0; j < remainder; j++) begin
        cb_counter.bus <= {p_pkt[p.toh.plen - (j+1)], bus};
    end

    $stop();
    for (int i = 0; i < 100; i += 1 ) begin
      test_var        <=  $urandom;
      test_var1       <=  $urandom;
      test_var2       <=  $urandom;
      test_var3       <=  $urandom;
      #10;
      // $display("Test var = %h Test var1 = %h Test var2 = %h Test var3 = %h \n", test_var, test_var1, test_var2, test_var3);
      reset <= 1;
      #20;
      // test_var        =  ~test_var;
      // test_var1       =  ~test_var1;
      // test_var2       =  ~test_var2;
      // test_var3       =  ~test_var3;
    
      reset <= 0;
      #10;
      sum             = test_var + test_var1 + test_var2 + test_var3;
      my_sum          = test_var + test_var1 + test_var2 + my_var;
      upper           = sum[31 : 16];
      lower           = sum[15 : 0];
      checksum        = ~(upper + lower);
      upper1          = my_sum[31 : 16];
      lower1          = my_sum[15 : 0];
      my_checksum     = upper1 + lower1;
      // $display("Modified test var %h test var1 %h test var2 %h test var3 %h \n", test_var, test_var1, test_var2, test_var3);
      reversed_sum    = ~(checksum) + ~test_var3;
      reversed_sum    = reversed_sum + my_var;
      upper2          =  reversed_sum[31 : 16];
      lower2          = reversed_sum[15 : 0];
      test_checksum   = upper2 + lower2;

      if(reversed_sum[16] == 1) begin 
        reversed_sum[31 : 16] = 0;
      end else begin 
        reversed_sum  += 1;
      end 
      // $display("Sum of test vars %h  checksum %h  my checksum - %h test checksum - %h  my sum %h upper 1 %h lower 1 %h\n", sum, checksum, my_checksum, test_checksum, my_sum, upper1, lower1);
      // $display("Sum of test vars %h  checksum %h  my checksum - %h test checksum - %h", sum, checksum, my_checksum, test_checksum);
      #10;
      if(test_checksum + 2 == my_checksum) begin 
        $display("PASSED");
      end else begin 
        $display("FAILED");
      end
    end
    #30;
    $stop();
  end

*/  
endmodule : headerCreatorTest
