module link_top #(
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 16,
	parameter TABLE_WIDTH = 8
)(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	input order_valid,
	output order_busy,
	input [1:0]order_type,
	input [TABLE_WIDTH - 1:0] order_table, 
	input [ADDR_WIDTH - 1:0] order_node,
	input [DATA_WIDTH - 1:0] order_data,

	output dout_valid,
	input dout_busy,
	output [DATA_WIDTH - 1:0] dout_data
);

wire [ADDR_WIDTH - 1:0]ram_addr;
wire [DATA_WIDTH - 1:0]ram_read_data;
wire ram_write_req;
wire [DATA_WIDTH - 1:0]ram_write_data;
link_table_mamager#(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH),
	.TABLE_WIDTH(TABLE_WIDTH)
) u_link (
	.clk(clk),    // Clock
	.rst_n(rst_n),  // Asynchronous reset active low

	.order_valid(order_valid),
	.order_busy(order_busy),
	.order_type(order_type),
	.order_table(order_table), 
	.order_node(order_node),
	.order_data(order_data),

	.dout_valid(dout_valid),
	.dout_busy(dout_busy),
	.dout_data(dout_data),

	.ram_addr(ram_addr),
	.ram_read_data(ram_read_data),
	.ram_write_req(ram_write_req),
	.ram_write_data(ram_write_data)
);

ram #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
) u_ram (
	.clk(clk),    // Clock

	.addr(ram_addr),
	.din(ram_write_data),
	.write_req(ram_write_req),

	.dout(ram_read_data)
);

endmodule