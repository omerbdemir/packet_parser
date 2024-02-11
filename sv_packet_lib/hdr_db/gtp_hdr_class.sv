

class gtp_hdr_class extends hdr_class;

rand bit [7:0] flags;
rand bit [7:0] msg_type;
rand bit [15:0] length;
rand bit [31:0] teid;
rand bit [15:0] seq_num;
rand bit [7:0] n_pdu;
rand bit [7:0] nxt_hdr_type;


constraint legal_total_hdr_len
  {
    `LEGAL_TOTAL_HDR_LEN_CONSTRAINTS;
  }
  
constraint legal_hdr_len 
  {
    hdr_len == 12;
    trl_len == 0;
  }

function new (pktlib_main_class plib,
              int               inst_no);
  super.new (plib);
  hid     = GTP_HID;
  this.inst_no = inst_no;
  $sformat(hdr_name, "gtp[%0d]", inst_no);
  super.update_hdr_db(hid, inst_no);
endfunction : new

  task pack_hdr (ref bit [7:0] pkt[],
                ref int       index,
                input bit     last_pack = 1'b0);
    int gtp_idx;
    gtp_idx = index;
    // pack_vec = {flags, msg_type, length, teid, seq_num, n_pdu, nxt_hdr_type};

    `ifdef SVFNYI_0
      pack_vec = {flags, msg_type, length, teid, seq_num, n_pdu, nxt_hdr_type};
      harray.pack_bit (pkt, pack_vec, index, hdr_len*8);
      `else
      hdr = {>>{flags, msg_type, length, teid, seq_num, n_pdu, nxt_hdr_type}};  
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
    {flags, msg_type, length, teid, seq_num, n_pdu, nxt_hdr_type} = pack_vec;
    `else
    harray.copy_array (pkt, hdr, index, hdr_len);
    {>>{flags, msg_type, length, teid, seq_num, n_pdu, nxt_hdr_type}} = hdr;
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
    gtp_hdr_class lcl;
    super.cpy_hdr(cpy_cls);
    $cast(lcl, cpy_cls);

    this.flags        = lcl.flags;
    this.msg_type     = lcl.msg_type;
    this.length       = lcl.length;
    this.teid         = lcl.teid;
    this.seq_num      = lcl.seq_num;
    this.n_pdu        = lcl.n_pdu;
    this.nxt_hdr_type = lcl.nxt_hdr_type;

    if(~last_cpy)
        this.nxt_hdr.cpy_hdr(cpy_cls.nxt_hdr, last_cpy);
  endtask : cpy_hdr

  task display_hdr(pktlib_display_class hdis,
                   hdr_class            cmp_cls,
                   int                  mode          = DISPLAY,
                   bit                  last_display  = 1'b0);
    gtp_hdr_class lcl;
    $cast (lcl, cmp_cls);
    if ((mode == DISPLAY_FULL) | (mode == COMPARE_FULL))
    // hdis.display_fld (mode, hdr_name, STRING,     DEF, 000, "", 0, 0, null_a, null_a, "~~~~~~~~~~ Class members ~~~~~~~~~~");
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "flags", flags, lcl.flags);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "msg_type", msg_type, lcl.msg_type,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 016, "length", length, lcl.length);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 032, "TEID", teid, lcl.teid,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 016, "seq_num", seq_num, lcl.seq_num,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "n_pdu", n_pdu, lcl.n_pdu,null_a,null_a);
    hdis.display_fld (mode, hdr_name, BIT_VEC,    HEX, 008, "nxt_hdr_type", nxt_hdr_type, lcl.nxt_hdr_type,null_a,null_a);
    if ((mode == DISPLAY_FULL) | (mode == COMPARE_FULL))
    begin // {
    display_common_hdr_flds (hdis, lcl, mode); 
    end // }
    if (~last_display & (cmp_cls.nxt_hdr.hid == nxt_hdr.hid))
        this.nxt_hdr.display_hdr (hdis, cmp_cls.nxt_hdr, mode);

  endtask : display_hdr

endclass : gtp_hdr_class