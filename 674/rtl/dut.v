module dut #(
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 16
)(
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low
	
	input order_valid,
	input [ADDR_WIDTH - 1:0]order_start,
	input [ADDR_WIDTH - 1:0]order_len,
	input [ADDR_WIDTH - 1:0]order_back,
	output order_busy
);

wire [ADDR_WIDTH - 1:0]ram_addr;
wire ram_write_req;
wire [DATA_WIDTH - 1:0]ram_write_data;
wire [DATA_WIDTH - 1:0]ram_read_data;

computer #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH)
) u_compute (
	.clk(clk),    // Clock
	.rst_n(rst_n),  // Asynchronous reset active low

	.order_valid(order_valid),
	.order_start(order_start),
	.order_len(order_len),
	.order_back(order_back),
	.order_busy(order_busy),

	.ram_addr(ram_addr),
	.ram_write_req(ram_write_req),
	.ram_write_data(ram_write_data),
	.ram_read_data(ram_read_data)

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