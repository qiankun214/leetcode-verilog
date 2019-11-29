module tb674 (
);

parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 16;
logic clk;    // Clock
logic rst_n;  // Asynchronous reset active low

logic order_valid;
logic [ADDR_WIDTH - 1:0]order_start;
logic [ADDR_WIDTH - 1:0]order_len;
logic [ADDR_WIDTH - 1:0]order_back;
logic order_busy;

dut #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH)
) ut (
	.clk(clk),    // Clock
	.rst_n(rst_n),  // Asynchronous reset active low
	
	.order_valid(order_valid),
	.order_start(order_start),
	.order_len(order_len),
	.order_back(order_back),
	.order_busy(order_busy)
);

initial begin //clock
	clk = 1'b0;
	forever begin
		#5 clk = ~clk;
	end
end

logic signed [DATA_WIDTH - 1:0] din [$];
initial begin
	// back write
	din = {1,3,5,4,7};
	for (int i = 0; i < din.size(); i++) begin
		ut.u_ram.memory[1+i] = din[i];
	end
	rst_n = 1'b1;
	#1 rst_n = 1'b0;
	#1 rst_n = 1'b1;

	repeat(6) @(posedge clk);

	order_start = (ADDR_WIDTH)'(1);
	order_len = (ADDR_WIDTH)'(din.size());
	order_back = 'b0;
	order_valid = 1'b1;
	repeat(2) @(posedge clk);
	while (order_busy) begin
		@(posedge clk);
	end

	repeat(2) @(posedge clk);

	$display("%p",ut.u_ram.memory[0]);
	$stop;
end

endmodule