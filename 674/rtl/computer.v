module computer #(
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 16
)(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	input order_valid,
	input [ADDR_WIDTH - 1:0]order_start,
	input [ADDR_WIDTH - 1:0]order_len,
	input [ADDR_WIDTH - 1:0]order_back,
	output order_busy,

	output reg [ADDR_WIDTH - 1:0]ram_addr,
	output reg ram_write_req,
	output reg [DATA_WIDTH - 1:0]ram_write_data,
	input [DATA_WIDTH - 1:0]ram_read_data

);

localparam INIT = 2'b00;
localparam READ = 2'b10;
localparam BACK = 2'b11;

wire is_order_din = order_valid && !order_busy && (order_len != 'b0);

reg [ADDR_WIDTH - 1:0]lock_len,lock_back;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		lock_len <= 'b0;
		lock_back <= 'b0;
	end else if (is_order_din) begin
		lock_len <= order_len;
		lock_back <= order_back;
	end
end

reg [1:0] mode,next_mode;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mode <= INIT;
	end else begin
		mode <= next_mode;
	end
end
assign order_busy = mode[1];

reg [ADDR_WIDTH - 1:0] addr_count;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		addr_count <= 'b0;
	end else if (mode == READ) begin
		addr_count <= addr_count + 1'b1;
	end
end

always @ (*) begin
	case (mode)
		INIT:begin
			if (is_order_din) begin
				next_mode = READ;
			end else if (order_valid && !order_busy && (order_len == 'b0)) begin
				next_mode = BACK;
			end else begin
				next_mode = INIT;
			end
		end
		READ:begin
			if (addr_count == lock_len) begin
				next_mode = BACK;
			end else begin
				next_mode = READ;
			end
		end
		BACK:next_mode = INIT;
		default : next_mode = INIT;
	endcase
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_addr <= 'b0;
	end else if (is_order_din) begin
		ram_addr <= order_start;
	end else if (mode == BACK) begin
		ram_addr <= lock_back;
	end else if (next_mode == READ) begin
		ram_addr <= ram_addr + 1'b1;
	end else begin
		ram_addr <= 'b0;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_write_req <= 'b0;
	end else if (mode == BACK) begin
		ram_write_req <= 1'b1;
	end else begin
		ram_write_req <= 'b0;
	end
end

wire signed [DATA_WIDTH - 1:0] this_data = ram_read_data;
reg signed [DATA_WIDTH - 1:0] last_data;
reg [DATA_WIDTH - 1:0] this_len,result;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		last_data <= 'b0;
		this_len <= (DATA_WIDTH)'(0);
		result <= 'b0;
	end else if (mode == INIT) begin
		last_data <= 'b0;
		this_len <= (DATA_WIDTH)'(1);
		result <= 'b0;
	end else if ((mode == READ) && (addr_count != lock_len)) begin
		last_data <= this_data;
		if (this_data > last_data) begin
			this_len <= this_len + 1'b1;
		end else if (this_len > result) begin
			result <= this_len;
			this_len <= (DATA_WIDTH)'(1);
		end else begin
			this_len <= (DATA_WIDTH)'(1);
		end
	end else if ((mode == READ) && (addr_count == lock_len)) begin
		if (this_len > result) begin
			result <= this_len;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_write_data <= 'b0;
	end else if ((mode == BACK) && (lock_len == 'b0)) begin
		ram_write_data <= 'b0;
	end else if (mode == BACK) begin
		ram_write_data <= result;
	end
end

endmodule