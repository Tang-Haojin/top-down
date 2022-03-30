#!/bin/bash

# This program will only work with bash(1)

# configs
spec_name=spec06_rv64gcb_o2_20m
spec_dir=/nfs/home/share/checkpoints_profiles/${spec_name}/take_cpt
thread_num=16
emu=emu_20220329

# environment preparation
dir=$(dirname $(readlink -f "$0"))
mkdir -p ${dir}/${spec_name}/${emu}.dir/csv
mkdir -p ${dir}/${spec_name}/${emu}.dir/html

# check python
python=python
[ -z "`whereis python3 | grep /`" ] || python=python3

# setup fifo
fifo_file=/tmp/$$.fifo
mkfifo "${fifo_file}"
exec 6<>"${fifo_file}"
for i in $(seq 1 ${thread_num}); do echo; done >&6

# run emus
i=0
for file in $(cat file.f); do
  array=(${file//,/ })
  name=${array[0]}_${array[1]}_${array[2]}
  j=$(($i % 128))
  read -u6
  {
    numactl -C $j-$(($j + 7)) ${dir}/emus/${emu} -W 20000000 -I 40000000 -i ${spec_dir}/${name}/0/_${array[1]}_.gz -s 7541 --diff=${NEMU_HOME}/build/riscv64-nemu-interpreter-so 2>${dir}/${spec_name}/${emu}.dir/${name}.log
    if [ $? -eq 0 ]; then
      sed "1,$(($(cat ${dir}/${spec_name}/${emu}.dir/${name}.log | wc -l) / 2))d" ${dir}/${spec_name}/${emu}.dir/${name}.log >${dir}/${spec_name}/${emu}.dir/csv/${name}.log
      ${dir}/top-down.sh ${dir}/${spec_name}/${emu}.dir/csv/${name}.log
      rm ${dir}/${spec_name}/${emu}.dir/csv/${name}.log
      $python ${dir}/top_down.py ${name} ${dir}/${spec_name}/${emu}.dir ${emu} # python ./top_down.py title dir suffix
    fi
    echo >&6
  } &
  i=$(($i + 8))
done

wait
exec 6>&-
rm -f ${fifo_file}
