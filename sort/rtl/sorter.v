module sorter#(
	parameter DATA_WIDTH = 16,
	parameter ADDR_WIDTH = 16
) (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	input order_valid,
	output order_busy,
	input [ADDR_WIDTH - 1:0]order_start,
	input [DATA_WIDTH - 1:0]order_len,

	output reg [ADDR_WIDTH - 1:0]ram_addr,
	output reg ram_write_req,
	output [DATA_WIDTH - 1:0]ram_write_data,
	input [DATA_WIDTH - 1:0]ram_read_data
);

reg [2:0] mode,next_mode;
localparam REST = 3'b000;
localparam INIT = 3'b101;
localparam READ = 3'b110;
localparam BACK = 3'b111;
localparam REWR = 3'b100;

wire is_order = order_valid && !order_busy;

reg [ADDR_WIDTH - 1:0] lock_start;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		lock_start <= 'b0;
	end else if (is_order) begin
		lock_start <= order_start;
	end
end

reg [ADDR_WIDTH - 1:0]cycle_count;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cycle_count <= 'b0;
	end else if (is_order) begin
		cycle_count <= order_len;
	end else if (next_mode == INIT) begin
		cycle_count <= cycle_count - 1'b1;
	end
end

reg [ADDR_WIDTH - 1:0]read_count;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		read_count <= 'b0;
	end else if (mode == READ) begin
		read_count <= read_count + 1'b1;
	end else begin
		read_count <= 'b0;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mode <= REST;
	end else begin
		mode <= next_mode;
	end
end

reg signed[DATA_WIDTH - 1:0] max_data;
reg signed[DATA_WIDTH - 1:0] rewrite_data;
always @ (*) begin
	case (mode)
		REST:begin
			if (is_order) begin
				next_mode = INIT;
			end else begin
				next_mode = REST;
			end
		end
		INIT:next_mode = READ;
		READ:begin
			if (read_count == cycle_count) begin
				next_mode = BACK;
			end else begin
				next_mode = READ;
			end
		end
		BACK:begin
			if (rewrite_data == max_data) begin
				if (cycle_count == (ADDR_WIDTH)'(2)) begin
					next_mode = REST;
				end else begin
					next_mode = INIT;
				end
			end else begin
				next_mode = REWR;
			end
		end
		REWR:begin
			if (cycle_count == (ADDR_WIDTH)'(2)) begin
				next_mode = REST;
			end else begin
				next_mode = INIT;
			end
		end
		default : next_mode = REST;
	endcase
end
assign order_busy = mode[2];

reg [ADDR_WIDTH - 1:0] max_index;
wire signed [DATA_WIDTH - 1:0] this_input = ram_read_data;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		max_index <= 'b0;
	end else if ((mode == INIT) || (mode == REST)) begin
		max_index <= 'b0;
	end else if ((mode == READ) && (max_data < this_input)) begin
		max_index <= ram_addr - 1'b1;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		rewrite_data <= 'b0;
	end else if ((mode == READ) && (next_mode == BACK)) begin
		rewrite_data <= this_input;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		max_data <= 'b0;
	end else if ((mode == INIT) || (mode == REST)) begin
		max_data <= 'b0;
	end else if ((mode == READ) && (max_data < this_input)) begin
		max_data <= this_input;
	end else if (next_mode == REWR) begin
		max_data <= rewrite_data;
	end
end
assign ram_write_data = max_data;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_addr <= 'b0;
	end else if (next_mode == INIT) begin
		ram_addr <= lock_start;
	end else if (is_order) begin
		ram_addr <= order_start;
	end else if (next_mode == READ && mode == INIT) begin
		ram_addr <= ram_addr + 1'b1;
	end else if (next_mode == READ && (read_count < cycle_count - 2'd2)) begin
		ram_addr <= ram_addr + 1'b1;
	end else if (next_mode == REWR) begin
		ram_addr <= max_index;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_write_req <= 'b0;
	end else if ((next_mode == REWR) || (next_mode == BACK)) begin
		ram_write_req <= 1'b1;
	end else begin
		ram_write_req <= 'b0;
	end
end

endmodule