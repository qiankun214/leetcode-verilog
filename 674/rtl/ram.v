module ram #(
	parameter DATA_WIDTH = 16,
	parameter ADDR_WIDTH = 16
)(
	input clk,    // Clock

	input [ADDR_WIDTH - 1:0] addr,
	input [DATA_WIDTH - 1:0] din,
	input write_req,

	output reg [DATA_WIDTH - 1:0] dout
);

reg [DATA_WIDTH - 1:0]memory[2 ** ADDR_WIDTH - 1:0];
always @ (posedge clk) begin
	if (write_req) begin
		memory[addr] <= din;
	end
end

always @ (posedge clk) begin
	dout <= memory[addr];
end

endmodule