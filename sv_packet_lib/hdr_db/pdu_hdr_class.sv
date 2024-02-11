

class pdu_hdr_class extends hdr_class;

rand bit [7:0] length;
rand bit [7:0] flags;
rand bit ppp;
rand bit rqi;
rand bit [5:0] qfi;
rand bit [15:0] padding;
rand bit [7:0] nxt_hdr_type;


constraint legal_total_hdr_len
  {
    `LEGAL_TOTAL_HDR_LEN_CONSTRAINTS;
  }
  
constraint legal_hdr_len 
  {
    hdr_len == 6;
    trl_len == 0;
  }

function new (pktlib_main_class plib,
              int               inst_no);
  super.new (plib);
  hid     = PDU_HID;
  this.inst_no = inst_no;
  $sformat(hdr_name, "pdu[%0d]", inst_no);
  super.update_hdr_db(hid, inst_no);
endfunction : new

  task pack_hdr (ref bit [7:0] pkt[],
                ref int       index,
                input bit     last_pack = 1'b0);
    int pdu_idx;
    pdu_idx = index;
    pack_vec = {length, flags, ppp, rqi, qfi, padding, nxt_hdr_type};

    `ifdef SVFNYI_0
      pack_vec = {length, flags, ppp, rqi, qfi, padding, nxt_hdr_type};
      harray.pack_bit (pkt, pack_vec, index, hdr_len*8);
      `else
      hdr = {>>{length, flags, ppp, rqi, qfi, padding, nxt_hdr_type}};  
      harray.pack_array_8 (hdr, pkt, index);
    `endif

    if (~last_pack)
    begin
      `ifdef DEBUG_PKTLIB
      $display("    pkt_lib : Packing %s nxt_hdr %s index %0d", hdr_name, nxt_hdr.hdr_name, index);
      `endif 
      this.nxt_hdr.pack_hdr(pkt,index);
    end

  endtask : pack_hdr


  task unpack_hdr (ref  bit [7:0] pkt [],
                ref  int       index,
                ref  hdr_class hdr_q[$],
                input int      mode  = DUMB_UNPACK,
                input bit      last_unpack = 1'b0);
    hdr_class lcl_class;

    update_len (index, pkt.size, 8);

    `ifdef SCFNYI_0
    harray.unpack_array(pkt, pack_vec, index, hdr_len);
    {length, flags, ppp, rqi, qfi, padding, nxt_hdr_type} = pack_vec;
    `else
    harray.copy_array (pkt, hdr, index, hdr_len);
    {>>{length, flags, ppp, rqi, qfi, padding, nxt_hdr_type}} = hdr;
    `endif

    //TODO: Implement smart unpack if applicable

    if(~last_unpack)
    begin
      `ifdef DEBUG_PKTLIB
        $display("  pkt_lib : Unpacking %s nxt_hdr %s index %0d", hdr_name, nxt_hdr.hdr_name, index);
        this.nxt_hdr.unpack_hdr(pkt, index, hdr_q, mode);
      `endif
    end

  endtask : unpack_hdr

  task cpy_hdr  (hdr_class  cpy_cls,
                bit        last_cpy = 1'b0);
    pdu_hdr_class lcl;
    super.cpy_hdr(cpy_cls);
    $cast(lcl, cpy_cls);

    this.length       = lcl.length;
    this.flags        = lcl.flags;
    this.ppp          = lcl.ppp;
    this.rqi          = lcl.rqi;
    this.qfi          = lcl.qfi;
    this.padding      = lcl.padding;
    this.nxt_hdr_type = lcl.nxt_hdr_type;

    if(~last_cpy)
        this.nxt_hdr.cpy_hdr(cpy_cls.nxt_hdr, last_cpy);
  endtask : cpy_hdr

  task display_hdr(pktlib_display_class hdis,
                   hdr_class            cmp_cls,
                   int                  mode          = DISPLAY,
                   bit                  last_display  = 1'b0);
    pdu_hdr_class lcl;
    $cast (lcl, cmp_cls);
    if ((mode == DISPLAY_FULL) | (mode == COMPARE_FULL))
    // hdis.display_fld (mode, hdr_name, STRING,     DEF, 000, "", 0, 0, null_a, null_a, "~~~~~~~~~~ Class members ~~~~~~~~~~");
    $display("mokoko");
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "Length", length, lcl.length);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "Flags", flags, lcl.flags,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 001, "PPP", ppp, lcl.ppp);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 001, "RQI", rqi, lcl.rqi,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 006, "QFI", qfi, lcl.qfi,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 016, "Padding", padding, lcl.padding,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "Next hdr type", nxt_hdr_type, lcl.nxt_hdr_type,null_a,null_a);
    if ((mode == DISPLAY_FULL) | (mode == COMPARE_FULL))
    begin // {
    display_common_hdr_flds (hdis, lcl, mode); 
    end // }
    if (~last_display & (cmp_cls.nxt_hdr.hid == nxt_hdr.hid))
        this.nxt_hdr.display_hdr (hdis, cmp_cls.nxt_hdr, mode);

  endtask : display_hdr

endclass : pdu_hdr_class