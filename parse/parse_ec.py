#!/usr/bin/env python3

import sys

if len(sys.argv) != 2:
    print("parce_ec <log_file>")
    sys.exit(1)

file1 = open(sys.argv[1], 'r') 
Lines = file1.readlines()

is_ec_line=0
operation = ""
registers = ["H2EC mbox", "EC2H mbox", "EC addr low", "EC addr high",
	     "EC data0", "EC data1", "EC data2", "EC data3",
	     "EC INT src low", "EC INT src high",
	     "EC INT mask low", "EC INT mask high", "EC APP ID"]

for line in Lines: 
	items = line.split()
	if len(items) < 2:
		continue
	items[2] = items[2].strip(":")
	if items[2][-2] == '8':
		continue
	if items[2][-3] != 'a' and items[2][-4] != 'a':
		continue
	print("{} {} 0x{}".format(registers[int(items[2][-1], 16)], items[1], items[3]))
