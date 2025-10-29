module comparator(
	clk,
	rst,
	en,
	threshold,
	din,
	cmp
);

	`include "./act_parameter.v"
	input clk;
	input rst;
	input en;
	input signed [PARAM_WIDTH-1:0]  threshold;
	input signed [ACT_IN_WIDTH-1:0] din;
	output reg 						cmp;

	wire							compare;

    assign compare = din > threshold;

	always@(posedge clk) begin
		if(rst) begin
			cmp <= 1'b0;
		end
		else if(en) begin
			cmp <= compare;
		end
		else begin
			cmp <= 1'b0;
		end
	end

endmodule
