/* a lpc decoder
 * lpc signals:
	* lpc_ad: 4 data lines
	* lpc_frame: frame to start a new transaction. active low
	* lpc_reset: reset line. active low
 * output signals:
	* out_cyctype_dir: type and direction. same as in LPC Spec 1.1
	* out_addr: 32-bit address (16 would be enough)
	* out_data: data read or written (1byte)
	* out_clock_enable: on rising edge all data must read.
 */

module lpc(
	input wire [3:0] lpc_ad,
	input wire lpc_clock,
	input wire lpc_frame,
	input wire lpc_reset,
	input wire reset,
	output wire [3:0] out_cyctype_dir,
	output wire [31:0] out_addr,
	output wire [7:0] out_data,
	output reg out_sync_timeout,
	output reg out_clock_enable);

	/* state machine */
	localparam[3:0] STATE_IDLE		= 4'd0;
	localparam[3:0] STATE_START		= 4'd1;
	localparam[3:0] STATE_CYCLE_DIR		= 4'd2;
	localparam[3:0] STATE_ADDRESS_CLK	= 4'd3;
	localparam[3:0] STATE_TAR_CLK		= 4'd4;
	localparam[3:0] STATE_SYNC		= 4'd5;
	localparam[3:0] STATE_DATA_CLK		= 4'd6;
	localparam[3:0] STATE_TAREND_CLK	= 4'd7;
	reg [3:0] state = STATE_IDLE;

	// registers
	reg [3:0] cyctype_dir;				// mode & direction, same as in LPC Spec 1.1
	reg [31:0] addr = 32'd0;			// 32 bit address
	reg [7:0] data;				// 8 bit data
	reg [3:0] counter;

	// combinatorial logic
	assign out_cyctype_dir = cyctype_dir;
	assign out_data = data;
	assign out_addr = addr;

	// synchronous logic
	// Clock goes high, or RESET goes low (active low reset)
	always @(posedge lpc_clock or negedge lpc_reset)
	begin
		if (~lpc_reset)
		begin
			state <= STATE_IDLE;
		end else
		begin
			if (~lpc_frame)
			begin
				if ((state == STATE_CYCLE_DIR || // START on extended LFRAME#
				     state == STATE_IDLE) && lpc_ad == 4'b0000) // START
				begin
					out_clock_enable <= 1'b0;
					out_sync_timeout <= 1'b0;
					state <= STATE_CYCLE_DIR;
					counter <= 0;
				end else

				// invalid or ABORT
				begin
					//state <= STATE_IDLE; // TODO: also wipes out valid cycles; needs investigation
				end
			end else

			// If LPC_FRAME is high, then we have data
			if (lpc_frame)
			begin
				// State machine for frame
				case (state)
					STATE_CYCLE_DIR:
					begin
						cyctype_dir <= lpc_ad;

						case (cyctype_dir[3:2])
							2'b00: // io
							begin
								state <= STATE_ADDRESS_CLK;
								addr <= 0;
								counter <= 3; // 4 nibbles / 2 bytes
							end

							2'b01: // mem
							begin
								state <= STATE_ADDRESS_CLK;
								counter <= 7; // 8 nibbles / 4 bytes
							end

							default: // unsupported DMA, FWH or reserved
							begin
								state <= STATE_IDLE;
							end
						endcase
					end

					STATE_ADDRESS_CLK:
					begin
						addr[counter * 4 + 3 : counter * 4] <= lpc_ad;

						if (counter == 0)
						begin
							case (cyctype_dir[1])
								1'b0: // read
								begin
									state <= STATE_TAR_CLK;
								end

								1'b1: // write
								begin
									state <= STATE_DATA_CLK;
								end
							endcase
						end else

						begin
							counter <= counter - 1;
						end
					end

					STATE_TAR_CLK:
					begin
						if (counter == 0)
						begin
							// On first clock LAD are 1111, on second clock it goes Z
							if (lpc_ad == 4'b1111)
							begin
								state <= STATE_TAR_CLK;
								counter <= 1;
							end else // invalid

							begin
								state <= STATE_IDLE;
							end
						end else

						if (counter == 1)
						begin
								state <= STATE_SYNC;
						end
					end

					STATE_SYNC:
					begin
						if (lpc_ad == 4'b0000) // Ready when LAD is 0000
						begin
							case (cyctype_dir[1])
								1'b0: // read
								begin
									state <= STATE_DATA_CLK;
									counter <= 0;
								end

								1'b1: // write
								begin
									state <= STATE_TAREND_CLK;
									counter <= 0;
								end
							endcase
						end
					end

					STATE_DATA_CLK:
					begin
						data[counter * 4 + 3 : counter * 4] <= lpc_ad;

						if (counter == 0)
						begin
								counter <= 1;
						end else

						if (counter == 1)
						begin
							case (cyctype_dir[1])
								1'b0: // read
								begin
									state <= STATE_TAREND_CLK;
									counter <= 0;
								end

								1'b1: // write
								begin
									state <= STATE_TAR_CLK;
									counter <= 0;
								end
							endcase
						end
					end

					STATE_TAREND_CLK:
					begin
						if (counter == 0)
						begin
							counter <= 1;
						end else

						if (counter == 1)
						begin
							// No need to check for addr, it was already filtered on first TAR
							out_clock_enable <= 1;
							state <= STATE_IDLE;
						end
					end

				endcase
			end
		end
	end
endmodule

