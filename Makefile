
NAME=top
DEPS=buffer.v bufferdomain.v lpc.v mem2serial.v ringbuffer.v power_on_reset.v trigger_led.v pll.v ftdi.v

$(NAME).bin: $(NAME).pcf $(NAME).v $(DEPS)
	yosys -p "synth_ice40 -json $(NAME).json" $(NAME).v $(DEPS)
	nextpnr-ice40 --hx1k --pcf $(NAME).pcf --json $(NAME).json --asc $(NAME).asc
	icepack $(NAME).asc $(NAME).bin
	cp $(NAME).bin lpc_sniffer.bin

buffer.vvp: buffer_tb.v buffer.v
	iverilog -o buffer_tb.vvp buffer_tb.v buffer.v

mem2serial.vvp: mem2serial_tb.v mem2serial.v
	iverilog -o mem2serial_tb.vvp mem2serial_tb.v mem2serial.v

ringbuffer.vvp: ringbuffer_tb.v ringbuffer.v buffer.v
	iverilog -o ringbuffer_tb.vvp ringbuffer_tb.v ringbuffer.v buffer.v

uart_tx_tb.vvp: uart_tx_tb.v uart_tx.v
	iverilog -o uart_tx_tb.vvp uart_tx_tb.v uart_tx.v

top_tb.vpp: top_tb.v top.v buffer.v bufferdomain.v lpc.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v trigger_led.v pll.v ./test/sb_pll40_core_sim.v
	iverilog -o top_tb.vpp top_tb.v top.v buffer.v bufferdomain.v lpc.v mem2serial.v ringbuffer.v uart_tx.v power_on_reset.v trigger_led.v pll.v ./test/sb_pll40_core_sim.v

test/helloonechar_tb.vvp: uart_tx_tb.v uart_tx.v test/helloonechar_tb.v power_on_reset.v
	iverilog -o test/helloonechar_tb.vvp test/helloonechar_tb.v uart_tx.v power_on_reset.v

test/helloworld_tb.vvp: test/helloworld_tb.v test/helloworld.v mem2serial.v ringbuffer.v buffer.v uart_tx.v power_on_reset.v test/helloworldwriter.v
	iverilog -o test/helloworld_tb.vvp test/helloworld_tb.v test/helloworld.v mem2serial.v ringbuffer.v buffer.v uart_tx.v power_on_reset.v test/helloworldwriter.v

test/helloworld.bin: test/helloworld.v mem2serial.v ringbuffer.v buffer.v uart_tx.v power_on_reset.v test/helloworldwriter.v test/helloworld.pcf
	yosys -p "synth_ice40 -json test/helloworld.json" test/helloworld.v mem2serial.v ringbuffer.v buffer.v uart_tx.v power_on_reset.v test/helloworldwriter.v
	nextpnr-ice40 --hx1k --pcf test/helloworld.pcf --json test/helloworld.json --asc test/helloworld.asc
	icepack test/helloworld.asc test/helloworld.bin

test/helloonechar.bin: test/helloonechar.v uart_tx.v power_on_reset.v test/helloonechar.pcf
	yosys -p "synth_ice40 -json helloonechar.json" helloonechar.v uart_tx.v power_on_reset.v
	nextpnr-ice40 --hx1k --pcf test/helloonechar.pcf --json test/helloonechar.json --asc test/helloonechar.asc
	icepack test/helloonechar.asc test/helloonechar.bin

clean:
	rm -f top.json top.asc top.bin

test: buffer.vvp mem2serial.vvp ringbuffer.vvp uart_tx_tb.vvp top_tb.vpp test/helloonechar_tb.vvp test/helloworld_tb.vvp

install: top.bin
	iceprog top.bin

.PHONY: install
