#!/bin/bash

# This program will only work with bash(1)

spec_name=spec06_rv64gcb_o2_20m
spec_dir=/nfs/home/share/checkpoints_profiles/${spec_name}/take_cpt
thread_num=16
emu=emu_20220314

mkdir -p `pwd`/${spec_name}/${emu}.dir

file_list=`cat file.f`

fifo_file="/tmp/$$.fifo"
mkfifo "${fifo_file}"
exec 6<>"${fifo_file}"

for ((i=0;i<${thread_num};i++)); do
  echo
done >&6

i=0
for file in ${file_list}; do
  array=(${file//,/ })
  name=${array[0]}_${array[1]}_${array[2]}
  j=`expr $i % 128 + 128`
  read -u6
  {
    numactl -C $j-`expr $j + 7` `pwd`/emus/${emu} --no-diff -W 20000000 -I 40000000 -i ${spec_dir}/${name}/0/_${array[1]}_.gz -s 7541 2>`pwd`/${spec_name}/${emu}.dir/${name}.log
    echo >&6
  } &
  i=`expr $i + 8`
done

wait

exec 6>&-
rm -f ${fifo_file}
