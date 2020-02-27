#!/usr/bin/env python3

file1 = open('ec_log2.log', 'r') 
Lines = file1.readlines()

is_ec_line=0
operation = ""
registers = ["H2EC mbox", "EC2H mbox", "EC addr low", "EC addr high",
	     "EC data0", "EC data1", "EC data2", "EC data3",
	     "EC INT src low", "EC INT src high",
	     "EC INT mask low", "EC INT mask high", "EC APP ID"]

for line in Lines: 
	line = line.strip()
	if is_ec_line == 1:
		stripped_line = line[2:-1]
		if stripped_line[5] == "2":
			operation = "write"
		elif stripped_line[5] == "0":
			operation = "read"
		print("{} {} 0x{}{}".format(registers[int(stripped_line[1], 16)], operation, stripped_line[2], stripped_line[3]))
	if str(line) == "b\'0000\'":
		is_ec_line=1
	else:
		is_ec_line=0

	#print("IO {} 0xa{}{}: 0x{}{}".format(operation, line[0], line[1], line[2], line[3]))
	