
module uart_tx #(parameter CLOCK_FREQ = 12_000_000, BAUD_RATE = 115_200)
	(
	input clock,
	input [7:0] read_data,
	input read_clock_enable,
	input reset, /* active low */
	output reg ready, /* ready to read new data */
	output reg tx,
	output reg uart_clock);

	reg [7:0] data;

	localparam CLOCKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
	reg [6:0] divider;

	reg new_data;
	reg [2:0] state;
	reg [2:0] bit_pos; /* which is the next bit we transmit */
	reg parity;

	localparam IDLE = 3'h0, START_BIT = 3'h1, DATA = 3'h2, PARITY = 3'h3, STOP_BIT = 3'h4;

	always @(negedge reset or posedge clock) begin
		if (~reset) begin
			uart_clock <= 0;
			divider <= 0;
		end
		else if (divider >= CLOCKS_PER_BIT) begin
			divider <= 0;
			uart_clock <= ~uart_clock;
		end
		else
			divider <= divider + 1;
	end

	always @(negedge clock or negedge reset) begin
		if (~reset) begin
			new_data <= 0;
			ready <= 0;
		end
		else begin
			if (state == IDLE) begin
				if (read_clock_enable) begin
					data <= read_data;
					new_data <= 1;
					ready <= 0;
				end
				else
					if (~new_data)
						ready <= 1;
			end
			else begin
				if (state == START_BIT)
					new_data <= 0;
				ready <= 0;
			end
		end
	end

	always @(posedge uart_clock or negedge reset) begin
		if (~reset) begin
			state <= IDLE;
		end
		else begin
			case (state)
				IDLE: begin
					tx <= 1;
					if (new_data) begin
						parity <= 1;
						state <= START_BIT;
					end
				end
				START_BIT: begin
					tx <= 0;
					state <= DATA;
					bit_pos <= 0;
				end
				DATA: begin
					tx <= data[bit_pos];

					if (data[bit_pos])
						parity <= ~parity;

					if (bit_pos == 7)
						state <= STOP_BIT;
					else
						bit_pos <= bit_pos + 1;
				end

				PARITY: begin
					tx <= parity;
					state <= STOP_BIT;
				end

				STOP_BIT: begin
					tx <= 1;
					state <= IDLE;
				end
				default: begin end
			endcase
		end
	end
endmodule

