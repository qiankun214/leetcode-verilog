module tb (
);

parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 16;
parameter TABLE_WIDTH = 8;

logic clk;
logic rst_n;

logic order_valid;
logic  order_busy;
logic [1:0]order_type;
logic [TABLE_WIDTH - 1:0] order_table;
logic [ADDR_WIDTH - 1:0] order_node;
logic [DATA_WIDTH - 1:0] order_data;

logic  dout_valid;
logic dout_busy;
logic  [DATA_WIDTH - 1:0] dout_data;

link_top #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH),
	.TABLE_WIDTH(TABLE_WIDTH)
) ut (
	.clk(clk),
	.rst_n(rst_n),

	.order_valid(order_valid),
	.order_busy(order_busy),
	.order_type(order_type),
	.order_table(order_table),
	.order_node(order_node),
	.order_data(order_data),

	.dout_valid(dout_valid),
	.dout_busy(dout_busy),
	.dout_data(dout_data)
);

localparam APPE = 2'b00;
localparam DELE = 2'b01;
localparam CHAG = 2'b10;
localparam READ = 2'b11;

initial begin
	clk = 1'b0;
	forever begin
		#5 clk = ~clk;
	end
end

initial begin
	
	order_valid = 'b0;
	order_type = 'b0;
	order_table = 'b0;
	order_node = 'b0;
	order_data = 'b0;

	rst_n = 1'b1;
	for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
		ut.u_ram.memory[i] = 'b0;
	end
	#1 rst_n = 1'b0;
	#1 rst_n = 1'b1;

	@(posedge clk);
	order_type = APPE;
	order_table = 3;
	order_node = 1;
	order_data = (DATA_WIDTH)'(111);
	order_valid = 1'b1;

	@(posedge clk);
	order_valid = 1'b0;

	#200;
	$stop;
end

endmodule
