#!/bin/sh

# spec06_rv64gcb_o2_20m
for file in `ls $1/600`; do python top_down.py $file; done
