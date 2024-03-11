#!/bin/bash 
OPTIONS="+acc -permissive -timescale "1ns/1ps" +define+NO_PROCESS_AE"
trl=$*;
vlib work


vlog -work work -sv $OPTIONS  packet_parser/parser_typedefs_pkg.sv
vlog -work work -sv $OPTIONS packet_parser/packet_parser_n6.sv
vlog -work work -sv $OPTIONS -f pktlib.vf my_test.sv


vsim -gui -sv_seed 1223 -do "wave.do" my_test_mod &

# vmap work new_lib
# vlib new_lib
# vcom -work work -permissive +define+NO_PROCESS_AE block_mem/xpm_VCOMP.vhd
# vlog -work work  $OPTIONS block_mem/blk_mem_gen_v8_4.v
# vlog -work work $OPTIONS block_mem/design_1_blk_mem_gen_0_0.v

# vlog  -work -sv $OPTIONS block_mem/xpm_memory.sv

# vlog -L new_lib -sv $OPTIONS -work new_lib my_test.sv
# vlog -sv -vopt -work my_library -f System-Verilog-Packet-Library/pktlib.vf System-Verilog-Packet-Library/pktlib_class.sv
# vlog -sv $OPTIONS -work 

read -p "Press key to exit"

