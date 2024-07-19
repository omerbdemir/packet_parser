#!/bin/bash 
rm -r new_lib
rm -r work
OPTIONS="+acc -permissive -timescale "1ns/1ps" +define+NO_PROCESS_AE"
trl=$*;
vlib work

# vlog -work work $OPTIONS block_mem/blk_mem_gen_v8_4.v
# vlog -work work $OPTIONS block_mem/design_1_blk_mem_gen_0_0.v
# vlog -work work -sv $OPTIONS block_mem/mem_controller.sv
# vlog -work work -sv $OPTIONS block_mem/mem_controller_test.sv  
# vsim -gui -sv_seed 1223 my_test_mod &

vlog -work work -sv $OPTIONS  packet_parser/parser_typedefs_pkg.sv
vlog -work work -sv $OPTIONS  packet_parser/packet_parser_n3.sv
vlog -work work -sv $OPTIONS -f pktlib.vf my_test.sv

vlog -work work -sv $OPTIONS  header_creator/header_creator_typedefs_pkg.sv
vlog -work work -sv $OPTIONS  header_creator/header_creator_n3_to_n6.sv
vlog -work work -sv $OPTIONS  header_creator/checksum_gen.sv
vlog -work work -sv $OPTIONS -f pktlib.vf header_creator_test.sv
vlog -work work -sv $OPTIONS -f pktlib.vf header_creator/checksum_test.sv

if [ "$1" == "sim" ]; then 
  if [ "$2" == "1" ]; then 
    vsim -gui -sv_seed 1223 -do "hc_wave.do" headerCreatorTest &
  fi
  if [ "$2" == "2" ]; then 
    vsim -gui -sv_seed 1223 -do "header_creator/cs_wave.do" checksum_test &
  fi
  if [ "$2" == "3" ]; then 
    vsim -gui -sv_seed 1223 -do "wave.do" my_test_mod &
  fi
fi



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

