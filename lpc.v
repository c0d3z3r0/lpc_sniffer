/* a lpc decoder
 * lpc signals:
	* lpc_ad: 4 data lines
	* lpc_frame: frame to start a new transaction. active low
	* lpc_reset: reset line. active low
 * output signals:
	* out_cyctype_dir: type and direction. same as in LPC Spec 1.1
	* out_addr: 16-bit address
	* out_data: data read or written (1byte)
	* out_clock_enable: on rising edge all data must read.
 */

module lpc(
	input wire [3:0] lpc_ad,
	input lpc_clock,
	input lpc_frame,
	input lpc_reset,
	input reset,
	output [3:0] out_cyctype_dir,
	output [31:0] out_addr,
	output [7:0] out_data,
	output out_sync_timeout,
	output reg out_clock_enable);

	/* type and direction. same as in LPC Spec 1.1 */

	/* addr + data written or read */

	/* state machine */
	reg [7:0] state = 0;
	localparam idle = 0, start = 1, cycle_dir = 2, address = 3, tar = 4, sync = 5, read_data = 6, abort = 7, tar_finish = 8;

	/* counter used by some states */
	reg [3:0] counter;

	/* mode + direction. same as in LPC Spec 1.1 */
	reg [3:0] cyctype_dir;

	reg [31:0] addr;
	reg [7:0] data;

	always @(posedge lpc_clock or negedge lpc_reset) begin
		if (~lpc_reset) begin
			state <= idle;
			counter <= 1;
		end
		else begin
			if (~lpc_frame) begin
				counter <= 1;
				if (lpc_ad == 4'b0000) /* start condition */
					state <= cycle_dir;
				else
					state <= idle; /* abort */
			end
			else begin
				counter <= counter - 1;
				case (state)

				address: begin
					addr[31:4] <= addr[27:0];
					addr[3:0] <= lpc_ad;
				end

				read_data: begin
					if (addr[11:4] != 8'ha4 && addr[7:0] != 8'h80)
						state <= idle;
					else
						addr[15:12] <= addr[11:8];
					data[7:4] <= lpc_ad;
					data[3:0] <= data[7:4];
				end

				default: begin end
				endcase
				if (counter == 1) begin
					case (state)
					idle: begin end

					cycle_dir: begin
						cyctype_dir <= lpc_ad;
						out_clock_enable <= 0;
						out_sync_timeout <= 0;

						if (lpc_ad[3:2] == 2'b00) begin
							/* i/o */
							state <= address;
							counter <= 4;
							addr <= 0;
						end else begin
							/* dma or reserved not yet supported */
							state <= idle;
						end
					end

					address: begin
						if (cyctype_dir[1] == 1) /* write memory or i/o */
							state <= read_data;
						else /* read memory or i/o */
							state <= tar;
						counter <= 2;
					end

					tar: begin
						state <= sync;
						counter <= 1;
					end

					sync: begin
						if (lpc_ad == 4'b1111) begin
							out_sync_timeout <= 1;
							out_clock_enable <= 1;
							state <= idle;
						end 
						else if (lpc_ad == 4'b0000) begin
							if (cyctype_dir[3] == 0) begin /* i/o or memory */
								if (cyctype_dir[1] == 0) begin
									/* read */
									state <= read_data;
									data <= 0;
								end
								else begin
									/* write */
									state <= tar_finish;
								end
								counter <= 2;
							end
						end
						else if (lpc_ad == 4'b0101 || lpc_ad == 4'b0110) begin
							/* short or long wait */
							counter <= 1;
						end
						else begin
						/* unsupported dma or reserved */
							state <= idle;
						end
					end

					read_data: begin
						state <= tar_finish;
						counter <= 2;
					end

					tar_finish: begin
						out_clock_enable <= 1;
						state <= idle;
					end

					abort: begin
						counter <= 2;
					end
					endcase
				end
			end
		end
	end

	assign out_addr = addr;
	assign out_cyctype_dir = cyctype_dir;
	assign out_data = data;

endmodule
