#!/usr/bin/env python3

from binascii import hexlify
import sys
import pyftdi.serialext as ftdi
import parse

ser = ftdi.serial_for_url('ftdi:///2', baudrate=12000000)

while True:
    line = ser.readline().rstrip()
    lpc = parse.parse_line(line)
    if not lpc:
        continue
    lpctype, direction, address, data = lpc
    print('%3s: %5s %8s: %4s' % (lpctype, direction, address, data))
