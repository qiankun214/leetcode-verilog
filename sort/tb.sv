module tb (
);

parameter DATA_WIDTH = 16;
parameter ADDR_WIDTH = 16;

logic clk;    // Clock
logic rst_n;  // Asynchronous reset active low

logic order_valid;
logic order_busy;
logic [ADDR_WIDTH - 1:0]order_start;
logic [DATA_WIDTH - 1:0]order_len;

sort_system #(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
) ut (
	.clk(clk),    // Clock
	.rst_n(rst_n),  // Asynchronous reset active low

	.order_valid(order_valid),
	.order_busy(order_busy),
	.order_start(order_start),
	.order_len(order_len)
);

initial begin
	clk = 1'b0;
	forever begin
		#5 clk = ~clk;
	end
end

logic [DATA_WIDTH - 1:0]din[$];
initial begin
	din = {1,2,5,1,3,7,5};
	rst_n = 1'b1;
	order_valid = 1'b0;
	order_start = 'b0;
	order_len = 'b0;
	for (int i = 0; i < din.size(); i++) begin
		ut.u_ram.memory[i] = din[i];
	end

	#1 rst_n = 1'b0;
	#1 rst_n = 1'b1;

	repeat(2) @(posedge clk);
	order_start = 'b0;
	order_len = din.size();
	order_valid = 1'b1;
	@(posedge clk);
	order_valid = 1'b0;

	do begin
		@(posedge clk);
	end while(order_busy == 1'b1);

	for (int i = 0; i < din.size(); i++) begin
		$display("%0d",ut.u_ram.memory[i]);
	end
	$stop;
end

endmodule