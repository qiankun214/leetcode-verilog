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

task append(int table_num,int place,logic[DATA_WIDTH - 1:0]data);
	order_type = APPE;
	order_table = table_num;
	order_node = place;
	order_data = data;
	order_valid = 1'b1;
	do begin
		@(posedge clk);
	end while(order_busy == 1'b1);
	order_valid = 1'b0;
endtask : append

task delete(int table_num,int place);
	order_type = DELE;
	order_table = table_num;
	order_node = place;
	order_data = 'b0;
	order_valid = 1'b1;
	do begin
		@(posedge clk);
	end while(order_busy == 1'b1);
	order_valid = 1'b0;
endtask : delete

initial begin
	
	order_valid = 'b0;
	order_type = 'b0;
	order_table = 'b0;
	order_node = 'b0;
	order_data = 'b0;
	dout_busy = 1'b0;

	rst_n = 1'b1;
	for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
		ut.u_ram.memory[i] = 'b0;
	end
	#1 rst_n = 1'b0;
	#1 rst_n = 1'b1;

	@(posedge clk);
	append(3,1,111);
	append(3,2,112);
	append(3,3,113);
	delete(3,3);
	append(1,3,20);

	// @(posedge clk);
	// order_valid = 1'b0;

	#3000;
	// $stop;
end

initial begin
	// for (int i = 0; i < 2; i++) begin
		// while begin
			// @(posedge cl)
		// end
	// end

end

endmodule
