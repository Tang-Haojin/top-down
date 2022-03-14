#!/bin/bash

filename=$1
debug=1

tmp=$(grep "ctrlBlock.rob: clock_cycle," $filename)
total_cycles=${tmp##* }
tmp=$(grep "ctrlBlock.decode: fetch_bubbles," $filename)
fetch_bubbles=${tmp##* }
tmp=$(grep "ctrlBlock.decode: decode_bubbles," $filename)
decode_bubbles=${tmp##* }
tmp=$(grep "ctrlBlock.decode: slots_issued," $filename)
slots_issued=${tmp##* }
tmp=$(grep "ctrlBlock.rename: recovery_bubbles," $filename)
recovery_bubbles=${tmp##* }
tmp=$(grep "ctrlBlock.rob: slots_retired," $filename)
slots_retired=${tmp##* }
tmp=$(grep "frontend.ftq: br_mispred_retired," $filename)
br_mispred_retired=${tmp##* }
tmp=$(grep "frontend.icache.mainPipe: icache_bubble_s2_miss," $filename)
icache_miss_cycles=${tmp##* }
tmp=$(grep "frontend.icache.mainPipe: icache_bubble_s0_tlb_miss," $filename)
itlb_miss_cycles=${tmp##* }
tmp=$(grep "frontend.bpu: s2_redirect," $filename)
s2_redirect_cycles=${tmp##* }
tmp=$(grep "frontend.bpu: s3_redirect," $filename)
s3_redirect_cycles=${tmp##* }
tmp=$(grep "memBlock.lsq.storeQueue: full," $filename)
store_bound_cycles=${tmp##* }
tmp=$(grep "ctrlBlock.dispatch: stall_cycle_rob," $filename)
stall_cycle_rob=${tmp##* }
tmp=$(grep "ctrlBlock.dispatch: stall_cycle_int_dq," $filename)
stall_cycle_int_dq=${tmp##* }
tmp=$(grep "ctrlBlock.dispatch: stall_cycle_fp_dq," $filename)
stall_cycle_fp_dq=${tmp##* }
tmp=$(grep "ctrlBlock.dispatch: stall_cycle_ls_dq," $filename)
stall_cycle_ls_dq=${tmp##* }
tmp=$(grep "ctrlBlock.rename: stall_cycle_fp," $filename)
stall_cycle_fp=${tmp##* }
tmp=$(grep "ctrlBlock.rename: stall_cycle_int," $filename)
stall_cycle_int=${tmp##* }

echo "total_cycles,       $total_cycles"        >$filename.csv
echo "fetch_bubbles,      $fetch_bubbles"      >>$filename.csv
echo "decode_bubbles,     $decode_bubbles"     >>$filename.csv
echo "slots_issued,       $slots_issued"       >>$filename.csv
echo "recovery_bubbles,   $recovery_bubbles"   >>$filename.csv
echo "slots_retired,      $slots_retired"      >>$filename.csv
echo "br_mispred_retired, $br_mispred_retired" >>$filename.csv
echo "icache_miss_cycles, $icache_miss_cycles" >>$filename.csv
echo "itlb_miss_cycles,   $itlb_miss_cycles"   >>$filename.csv
echo "s2_redirect_cycles, $s2_redirect_cycles" >>$filename.csv
echo "s3_redirect_cycles, $s3_redirect_cycles" >>$filename.csv
echo "store_bound_cycles, $store_bound_cycles" >>$filename.csv
echo "stall_cycle_fp,     $stall_cycle_fp"     >>$filename.csv
echo "stall_cycle_int,    $stall_cycle_int"    >>$filename.csv
echo "stall_cycle_rob,    $stall_cycle_rob"    >>$filename.csv
echo "stall_cycle_int_dq, $stall_cycle_int_dq" >>$filename.csv
echo "stall_cycle_fp_dq,  $stall_cycle_fp_dq"  >>$filename.csv
echo "stall_cycle_ls_dq,  $stall_cycle_ls_dq"  >>$filename.csv

if [ -n "$debug" ]; then
  cat $filename.csv
fi
