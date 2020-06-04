#!/usr/bin/env python3

import sys
import binascii
import struct

def swap32(x):
    return int.from_bytes(x, byteorder='little', signed=False)

if len(sys.argv) != 2:
	print("parce_ec <fw_file>")
	sys.exit(1)

file1 = open(sys.argv[1], 'rb')
dwords=0

with open(sys.argv[1], 'rb') as f:
	while True:
		data = f.read(4)
		if not data:
			break

		sys.stdout.write("0x{:08x}, ".format(swap32(data)))
		data = f.read(4)
		if not data:
			break

		sys.stdout.write("0x{:08x}, ".format(swap32(data)))
		data = f.read(4)
		if not data:
			break

		sys.stdout.write("0x{:08x}, ".format(swap32(data)))
		data = f.read(4)
		if not data:
			break

		sys.stdout.write("0x{:08x},".format(swap32(data)))
		sys.stdout.write("\n")

