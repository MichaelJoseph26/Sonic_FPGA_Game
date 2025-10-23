module spaced_misc_sprite_sheet_palette (
	input logic [2:0] index,
	output logic [3:0] red, green, blue
);

localparam [0:7][11:0] palette = {
	{4'hA, 4'h0, 4'hA},
	{4'hF, 4'hF, 4'hF},
	{4'h0, 4'h0, 4'h0},
	{4'hF, 4'hA, 4'h5},
	{4'h0, 4'h0, 4'hA},
	{4'h5, 4'h5, 4'hF},
	{4'hA, 4'h5, 4'h5},
	{4'hF, 4'hF, 4'h0}
};

assign {red, green, blue} = palette[index];

endmodule
