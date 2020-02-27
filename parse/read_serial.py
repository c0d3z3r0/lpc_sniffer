#!/usr/bin/env python3

from binascii import hexlify
from datetime import datetime
import sys
import serial
import parse

if len(sys.argv) != 2:
    print("read_serial /dev/ttyUSB4")
    sys.exit(1)

# ser = serial.Serial(sys.argv[1], 115200)
# ser = serial.Serial(sys.argv[1], 2_000_000)
ser = serial.Serial(sys.argv[1], 921600)

while True:
    line = ser.readline()
    line = line.strip(b'\r\n')
    print(hexlify(line))
    lpc = parse.parse_line(line)
    dateTimeObj = datetime.now()
    if not lpc:
        continue
    timestampStr = dateTimeObj.strftime("[%H:%M:%S.%f]")
    lpctype, direction, address, data = lpc
    print('%s %3s: %5s %8s: %4s' % (timestampStr, lpctype, direction, address, data))
