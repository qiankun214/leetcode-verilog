module bst_manager #(
	parameter AWIDTH = 16,
	parameter DWIDTH = 16
	parameter TREE_BASE = 0
	parameter STACK_BASE = 2 ** (AWIDTH - 1),
) (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	input order_valid,
	output reg order_busy,
	input [1:0]order_type,
	input [AWIDTH - 1:0]order_root,
	input [DWIDTH - 1:0]order_data,

	output reg dout_valid,
	input dout_busy,
	output reg [DWIDTH - 1:0]dout_data,

	output reg [AWIDTH - 1:0]ram_addr,
	output reg ram_wreq,
	output reg [DWIDTH - 1:0]ram_wdata,
	input [DWIDTH - 1:0]ram_rdata
);

wire is_order = order_valid && !order_busy;
wire is_dout = dout_valid && !dout_busy;

localparam DOUT = 2'b00;
localparam NEWT = 2'b01;
localparam INSE = 2'b11;

// mode
localparam INIT = 4'd0;
localparam NEWT_FIND = 4'd1;
localparam NEWT_MAKE = 4'd2;
localparam NEWT_BACK = 4'd3;
localparam INSE_FIND = 4'd4;
localparam INSE_WRIT = 4'd5;
localparam INSE_BACK = 4'd6;
localparam DOUT_STIN = 4'd7;
localparam DOUT_SOUT = 4'd8;
reg [3:0]mode,next_mode;


always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mode <= INIT;
	end else begin
		mode <= next_mode;
	end
end
always @ (*) begin
	case (mode)
		INIT:begin
			if (is_order && order_type == NEWT) begin
				next_mode = NEWT_FIND;
			end else if (is_order && order_type == INSE) begin
				next_mode = INSE_FIND;
			end else if (is_order && order_type == DOUT) begin
				next_mode = DOUT_STIN;
			end else begin
				next_mode = INIT;
			end
		end
		default : ;
	endcase
end


endmodule