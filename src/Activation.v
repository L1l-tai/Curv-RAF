//num of segments is ORDER + 1
module Activation #(
	parameter 
	ORDER = 15, 
	SCALE = 8
)
(
	clk,
	reset_n,
	act_en,
	act_in_valid,
	act_out_valid,
    act_th,
    act_k,
    act_b,
    act_in,
	act_out
);

`include "./act_parameter.v"

input 									clk;
input 									reset_n;
input 									act_en;
input                       			act_in_valid;
output	                    			act_out_valid;
input 	[ORDER*PARAM_WIDTH-1:0] 	    act_th ; 	           //fixed-point(8 scale)
input 	[(ORDER+1)*PARAM_WIDTH-1:0] 	act_k;
input 	[(ORDER+1)*PARAM_WIDTH-1:0] 	act_b;
input 	[ACT_IN_WIDTH-1:0]		 		act_in;                //fixed-point number(8 scale)
output 	[ACT_WIDTH-1:0] 				act_out;


wire 	[PARAM_WIDTH-1:0] 				threshold 	[ORDER-1:0];
wire 	[PARAM_WIDTH-1:0] 				k 			[ORDER:0];
wire 	[PARAM_WIDTH-1:0] 				b 			[ORDER:0];
wire 	[ORDER-1:0] 					cmp         		 ;
wire    [INDEX_WIDTH-1:0]               index_c     		 ;
reg 	[INDEX_WIDTH-1:0] 				index       		 ;
wire 	[ORDER+INDEX_WIDTH-1:0]  	    lut 		[ORDER:0];
wire 	[INDEX_WIDTH-1:0]				lutdata 	[ORDER:0];
reg 	[(ORDER+INDEX_WIDTH)*(ORDER+1)-1:0] 		lutmerge;

//reg		[ACT_IN_WIDTH-1:0]  act_in_r;
//reg                         act_valid_reg0;
reg							act_valid_reg;
//reg 	[ACT_WIDTH16-1:0] 	act_out_r;

//calculate
wire signed [ACT_WIDTH_DUO-1:0] bfull;	
wire signed [ACT_WIDTH_DUO-1:0] outfull;
reg  signed [ACT_WIDTH-1:0] data;    
wire signed [ACT_WIDTH-1:0] signedk;
wire [ACT_IN_WIDTH-1:0] out16;

//always @(posedge clk) act_in_r <= act_in;

//Parameter assignment
//using external register
genvar i;
generate
	for(i = 0; i < ORDER; i = i + 1) begin: ASSIGN_th
		assign threshold[i] =act_th[((i+1)*PARAM_WIDTH-1):(i*PARAM_WIDTH)];
	end
	
	for(i = 0; i < ORDER + 1; i = i + 1) begin: ASSIGN_k
		assign k[i] = act_k[((i+1)*PARAM_WIDTH-1):(i*PARAM_WIDTH)];
	end

	for(i = 0; i < ORDER + 1; i = i + 1) begin: ASSIGN_b
		assign b[i] = act_b[((i+1)*PARAM_WIDTH-1):(i*PARAM_WIDTH)];
	end
endgenerate

//comparators
genvar j;
generate
	for(j = 0; j < ORDER; j = j + 1) begin: CMP
		comparator comp(
			.clk				(clk),
			.rst				(!reset_n),
			.en					(act_en),
			.threshold			(threshold[j]),
			.din				(act_in),
			.cmp				(cmp[j])
		);
	end
endgenerate
//end of comparators

//set lut
assign lut[0] = {{(ORDER){1'b0}}, {INDEX_WIDTH{1'd0}}};
genvar m;
generate		
	for(m = 1; m <= ORDER-1; m = m + 1) begin:LUT1
		assign lutdata[m] = m;
		assign lut[m] = {{{(ORDER-m){1'b0}},{m{1'b1}}}, lutdata[m]};
	end
endgenerate
assign lutdata[ORDER] = ORDER;
assign lut[ORDER] = {{(ORDER){1'b1}}, lutdata[ORDER]};
	
genvar n;
generate
   for(n = 0; n<=ORDER; n = n + 1) begin:LUTMERGE
       always@(*) begin
           lutmerge[(n+1)*(ORDER+INDEX_WIDTH)-1 : n*(ORDER+INDEX_WIDTH)] = lut[n];
       end
   end
endgenerate

// get indexes	
MuxKeyWithDefault #(ORDER+1,ORDER,INDEX_WIDTH) paramsel0(
		.out					(index_c),
		.key					(cmp),
		.default_out	        ({INDEX_WIDTH{1'd0}}),
		.lut					(lutmerge)
);

always @(posedge clk) index <= index_c;

assign signedk = k[index];
assign bfull = {{ACT_IN_WIDTH{b[index][PARAM_WIDTH]}},b[index]};
always@(posedge clk) data <= act_in;
assign outfull = signedk * data + bfull;
assign out16 = act_en ? outfull[SCALE+ACT_IN_WIDTH-1:SCALE] : act_in;
//assign act_result_0 = out16_0[ACT_IN_WIDTH - 1 : ACT_IN_WIDTH - ACT_WIDTH]; 	

always @(posedge clk) act_valid_reg <= act_in_valid;
//always @(posedge clk) act_valid_reg <= act_valid_reg0;
//delay 1 cycles

//always @(posedge clk) act_out_r <= out16;
assign act_out_valid = act_en ? act_valid_reg : act_in_valid;
assign act_out = act_en ? out16 : act_in;

endmodule


