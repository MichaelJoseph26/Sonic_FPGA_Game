module sonic_the_hedgehog_rom (
	input logic clock,
	input logic [18:0] address,
	output logic [3:0] q
);

logic [3:0] memory [0:307199] /* synthesis ram_init_file = "./sonic_the_hedgehog/sonic_the_hedgehog.COE" */;

always_ff @ (posedge clock) begin
	q <= memory[address];
end

endmodule
