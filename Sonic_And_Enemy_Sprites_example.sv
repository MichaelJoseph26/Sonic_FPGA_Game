module Sonic_And_Enemy_Sprites_example (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input integer sprite_offset_x,
	input integer sprite_offset_y,
	input integer jump_pos_y,
	input integer position_y_ghz,
	input integer position,
	input logic   got_enemy_1,
	output logic [3:0] red, green, blue
	
);

logic [16:0] rom_address;
logic [3:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

logic negedge_vga_clk;

// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen
//assign rom_address = ((DrawX * 360) / 640) + (((DrawY * 264) / 480) * 360);
always_comb
begin
    if((DrawX - 275 >= 0 && DrawX - 275 < 36) && (DrawY - 360  + jump_pos_y  >= 0 && DrawY - 360 + jump_pos_y  < 64)) //cords = (275,360 + jump_pos), Sonic size (32,64)
        begin
            //sprite_offest_x and sprite_offset_y are offsets in the actual sprite sheet
            rom_address = ((((DrawX - 275) + (sprite_offset_x*2))/2) + ((((DrawY - 360 + jump_pos_y) + (sprite_offset_y * 2)) /2) * (360))) ;  //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (xDim)))
        end 
    else if((position >= 240 && position < 780) && (DrawX >= 640 + 240 - position && DrawX < 640 + 240 + 36 - position ) && (DrawY >= 280 - position_y_ghz && DrawY < 344 - position_y_ghz))
        begin
            if(got_enemy_1)
                begin
                    rom_address = ((((DrawX - (640 + 240 - position)) + ((267) * 2)) / 2) + ((((DrawY - 280 + position_y_ghz) +  (128 * 2)) /2) * (360))) ;
                end
            else
                begin
                    rom_address = 0; 
                end
        end
end

always_ff @ (posedge vga_clk) begin
	red <= 4'h0;
	green <= 4'h0;
	blue <= 4'h0;

	if (blank) begin
		red <= palette_red;
		green <= palette_green;
		blue <= palette_blue;
	end
end

Sonic_And_Enemy_Sprites_rom Sonic_And_Enemy_Sprites_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

Sonic_And_Enemy_Sprites_palette Sonic_And_Enemy_Sprites_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
