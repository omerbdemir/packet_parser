#/bin/bash

test_name=$1;shift;
trl=$*;

# VCS command line
#vcs -sverilog -full64 +warn=all -f pktlib.vf -R test/$test_name.sv -l log/$test_name$trl.log $trl

#vcs -full64 -sverilog +warn=all -CFLAGS -g -CC -Ihdr_db/include/gcm-aes/c-file -cpp g++ hdr_db/include/gcm-aes/c-file/aescrypt.c hdr_db/include/gcm-aes/c-file/aeskey.c hdr_db/include/gcm-aes/c-file/aestab.c hdr_db/include/gcm-aes/c-file/gcm.cpp hdr_db/include/gcm-aes/c-file/gfvec.cpp hdr_db/include/gcm-aes/c-file/gcm_dpi.cpp -f pktlib.vf +define+DEBUG_PKTLIB -R test/$test_name.sv -l log/$test_name$trl.log $trl


# questa 1-step process
# qverilog -64 -sv -permissive -timescale "1ns/1ps" +define+NO_PROCESS_AE $trl -f pktlib.vf test/$test_name.sv -l log/$test_name.questa.log -R -do "run -a; quit -f" -printsimstats

# questa 3-step process
vlib pktlib_lib
vlog -sv -vopt test/parser_typedefs_pkg.sv
vlog -sv +acc -vopt -permissive -timescale "1ns/1ps" +define+NO_PROCESS_AE $trl -f pktlib.vf test/$test_name.sv
vsim -gui -sv_seed 1223 -do "wave.do" my_test_mod 
# vsim my_test -vopt -c -do "run  -a; quit -f" -printsimstats


# xrun command line
# xrun -64bit -v93 -relax -access +rwc -namemap_mixgen -SV -REDUCE_MESSAGES -NOCOPYRIGHT -xceligen on=1809 -LOGFILE  log/$test_name$trl.log -FILE pktlib_xrun.vf test/$test_name.sv $trl 
