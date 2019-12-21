module link_table_mamager#(
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 16,
	parameter TABLE_WIDTH = 8
) (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	input order_valid,
	output reg order_busy,
	input [1:0]order_type,
	input [TABLE_WIDTH - 1:0] order_table, 
	input [ADDR_WIDTH - 1:0] order_node,
	input [DATA_WIDTH - 1:0] order_data,

	output reg dout_valid,
	input dout_busy,
	output reg [DATA_WIDTH - 1:0] dout_data,

	output reg [ADDR_WIDTH - 1:0]ram_addr,
	input [DATA_WIDTH - 1:0]ram_read_data,
	output reg ram_write_req,
	output reg [DATA_WIDTH - 1:0]ram_write_data
);
// base addr
localparam BASE_ADDR = 2 ** TABLE_WIDTH;

// order type
localparam APPE = 2'b00;
localparam DELE = 2'b01;
localparam CHAG = 2'b10;
localparam READ = 2'b11;

// statue
reg [1:0]mode,next_mode;
localparam REST = 2'b00;
localparam LINK = 2'b01;
localparam REWR = 2'b10;
localparam BACK = 2'b11;

// is_*
wire is_order = order_valid && !order_busy;
wire is_dout = dout_valid && !dout_busy;

reg [1:0]lock_type;
reg [TABLE_WIDTH - 1:0] lock_table;
reg [ADDR_WIDTH - 1:0]  lock_node;
reg [DATA_WIDTH - 1:0]  lock_data;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		lock_type <= 'b0;
		lock_table <= 'b0;
		lock_node <= 'b0;
		lock_data <= 'b0;
	end else if (is_order) begin
		lock_type <= order_type ;
		lock_table <=order_table;
		lock_node <= order_node ;
		lock_data <= order_data ;
	end
end

reg [ADDR_WIDTH - 1:0]link_count;
wire [ADDR_WIDTH - 1:0]this_node_num = {1'b0,link_count[ADDR_WIDTH - 1:1]};
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		link_count <= 'b0;
	end else if (mode == LINK) begin
		link_count <= link_count + 1'b1;
	end else begin
		link_count <= 'b0;
	end
end

reg [ADDR_WIDTH - 1:0] last_addr;
always @ (posedge clk or negedge rst_n) begin 
	if (~rst_n) begin
		last_addr <= 'b0;
	end else begin
		last_addr <= ram_addr;
	end
end

reg rewr_start_count;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		rewr_start_count <= 1'b0;
	end else if ((next_mode == REWR) && (lock_type != APPE)) begin
		rewr_start_count <= 1'b1;
	end else if ((next_mode == REWR) && (lock_type == APPE) && (ram_read_data == 'b0) && (last_addr >= BASE_ADDR) && (last_addr[1:0] == 'b0)) begin
		rewr_start_count <= 1'b1;
	end else if (mode == BACK) begin
		rewr_start_count <= 1'b0;
	end
end

reg [3:0]rewr_count;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		rewr_count <= 'b0;
	end else if (rewr_start_count && (mode == REWR)) begin
		rewr_count <= rewr_count + 1'b1;
	end else if (mode != REWR) begin
		rewr_count <= 'b0;
	end
end

// reg finish need to define
reg is_rewrite_finish;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		is_rewrite_finish <= 'b0;
	end else if ((lock_type == APPE) && (rewr_count == 3'd5)) begin
		is_rewrite_finish <= 1'b1;
	end else if ((lock_type == DELE) && (rewr_count == 3'd3)) begin
		is_rewrite_finish <= 1'b1;
	end else if ((lock_type == CHAG) && (rewr_count == 3'd2)) begin
		is_rewrite_finish <= 1'b1;
	end else if ((lock_type == READ) && (rewr_count == 3'd2)) begin
		is_rewrite_finish <= 1'b1;
	end else begin
		is_rewrite_finish <= 1'b0;
	end
end

reg is_fatal;
// fsm
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mode <= REST;
	end else begin
		mode <= next_mode;
	end
end

always @ (*) begin
	case (mode)
		REST:begin
			if (is_order) begin
				next_mode = LINK;
			end else begin
				next_mode = REST;
			end
		end
		LINK:begin
			if ((lock_type == READ || lock_type == CHAG) && (this_node_num == lock_node)) begin
				next_mode = REWR;
			end else if ((lock_type == APPE || lock_type == DELE) && (this_node_num == lock_node - 1'b1)) begin
				next_mode = REWR;
			end else if (is_fatal) begin
				next_mode = BACK;
			end else begin
				next_mode = LINK;
			end
		end
		REWR:begin
			if (is_rewrite_finish) begin
				next_mode = BACK;
			end else if (is_fatal) begin
				next_mode = BACK;
			end else begin
				next_mode = REWR;
			end
		end
		BACK:begin
			if (is_dout) begin
				next_mode = REST;
			end else begin
				next_mode = BACK;
			end
		end
		default : next_mode = REST;
	endcase
end

reg [ADDR_WIDTH - 1:0]last_point_addr,this_point_addr;
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		last_point_addr <= 'b0;
	end else if ((mode == LINK) && (next_mode == REWR)) begin
		if (ram_addr < BASE_ADDR) begin
			last_point_addr <= ram_addr;
		end else begin
			last_point_addr <= {ram_addr[ADDR_WIDTH - 1:2],2'b00};
		end
	end
end
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		this_point_addr <= 'b0;
	end else if (rewr_start_count == 1'b0) begin
		this_point_addr <= last_addr;
	end
end

wire is_appe_full_fatal1 = (last_point_addr < BASE_ADDR) && (ram_addr[ADDR_WIDTH - 1:2] == 'b0);
wire is_appe_full_fatal2 = (last_point_addr >= BASE_ADDR && (ram_addr[ADDR_WIDTH - 1:2] == last_point_addr[ADDR_WIDTH -1:2]));
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		is_fatal <= 'b0;
	end else if (next_mode == REST) begin
		is_fatal <= 1'b0;
	end else begin
		case (lock_type)
			APPE:begin
				if ((mode == REWR) && (!rewr_start_count) && (is_appe_full_fatal1 || is_appe_full_fatal2)) begin
					is_fatal <= 1'b1;
				end
			end
			default : is_fatal <= 1'b0;
		endcase
	end
end
// reg [ADDR_WIDTH - 1:0] tmp_point;
// always @ (posedge clk or negedge rst_n) begin
// 	if (~rst_n) begin
// 		tmp_point <= 'b0;
// 	end else if ((rewr_count == 1'b1) && (lock_type == APPE)) begin
// 		tmp_point <= ;
// 	end
// end
// output
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_addr <= 'b0;
	end else if ((next_mode == LINK) && (mode != LINK)) begin
		ram_addr <= order_table;
	end else if ((mode == REWR) || (next_mode == REWR)) begin
		case (lock_type)
			APPE:begin
				if (rewr_start_count == 1'b0) begin
					if (ram_addr < BASE_ADDR) begin
						ram_addr <= BASE_ADDR;
					end else begin
						ram_addr <= {ram_addr[ADDR_WIDTH - 1:2] + 1'b1,2'b00};
					end
				end else if (rewr_start_count == 1'b1 && rewr_count == 'b0) begin
					if (last_point_addr < BASE_ADDR) begin
						ram_addr <= last_point_addr;
					end else begin
						ram_addr <= last_point_addr + 1'b1;
					end
				end else if (rewr_count == 3'd1) begin
					ram_addr <= this_point_addr;
				end else if (rewr_count < 3'd5) begin
					ram_addr <= ram_addr + 1'b1;
				end else if (rewr_count == 3'd5) begin
					if (last_point_addr < BASE_ADDR) begin
						ram_addr <= last_point_addr;
					end else begin
						ram_addr <= last_point_addr + 1'b1;
					end
				end
			end
			DELE:begin
				if (rewr_count == 'b0) begin
					ram_addr <= ram_read_data;
				end else if (rewr_count == 3'd1) begin
					ram_addr <= last_point_addr;
				end
			end
			CHAG,READ:ram_addr <= ram_addr + 1'b1;
			default : ram_addr <= ram_addr;
		endcase
	end else if (mode == LINK) begin
		if (link_count[0] == 1'b1) begin
			ram_addr <= ram_read_data + 1'b1;
		end
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_write_req <= 1'b0;
	end else if (mode == REWR) begin
		case (lock_type)
			APPE:begin
				if (rewr_start_count && (rewr_count < 3'd6) && (rewr_count != 'b0)) begin
					ram_write_req <= 1'b1;
				end else begin
					ram_write_req <= 1'b0;
				end
			end
			DELE,CHAG:begin
				if (rewr_count < 3'd2) begin
					ram_write_req <= 1'b1;
				end else begin
					ram_write_req <= 1'b0;
				end
			end
			default : ram_write_req <= 1'b0;
		endcase
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		ram_write_data <= 'b0;
	end else if (mode == REWR) begin
		case (lock_type)
			APPE:begin
				if (rewr_count == 3'd0) begin
					ram_write_data <= lock_table;
				end else if (rewr_count == 3'd2) begin
					ram_write_data <= ram_read_data;
				end else if (rewr_count == 3'd3) begin
					ram_write_data <= 'b0;
				end else if (rewr_count == 3'd4) begin
					ram_write_data <= lock_data;
				end else if (rewr_count == 3'd5) begin
					ram_write_data <= this_point_addr;
				end
			end
			DELE:ram_write_data <= 'b0;
			CHAG:ram_write_data <= lock_data;
			default : ram_write_data <= 'b0;
		endcase
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		order_busy <= 'b0;
	end else if (is_order) begin
		order_busy <= 1'b1;
	end else if (next_mode == REST) begin
		order_busy <= 1'b0;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		dout_valid <= 'b0;
	end else if (mode == BACK) begin
		dout_valid <= 1'b1;
	end else if (is_dout) begin
		dout_valid <= 1'b0;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		dout_data <= 'b0;
	end else if (is_fatal) begin
		dout_data <= 'b0;
	end else if (lock_type != READ) begin
		dout_data <= 1'b1;
	end else if (lock_type == READ) begin
		dout_data <= ram_read_data;
	end
end

endmodule
