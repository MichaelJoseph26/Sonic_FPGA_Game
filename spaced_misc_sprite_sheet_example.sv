module spaced_misc_sprite_sheet_example (
	input logic vga_clk,
	input logic frame_clk,
	input logic Reset,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input integer position,
	input logic collected_ring1,
	input integer rings,
	input logic end_game,
	input integer position_y_ghz,
	input logic spike_flag,
	output logic [3:0] red, green, blue,
	output logic time_over
);

logic [13:0] rom_address;
logic [2:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

logic negedge_vga_clk;

integer game_time ; 

integer game_score_idx ; 

integer game_score ; 

assign game_score = game_score_idx + rings ; 
// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;


always_ff @ (posedge frame_clk)
    begin
    if(Reset) //reset if the reset button hit or we get a keycode
        begin
        game_time <= 0;
        time_over <= 0 ; 
        end 
    else if(game_time >= 14400/*36000 actual 10 minute time*/)
        begin
        time_over <= 1'b1 ; 
        game_time <= game_time ; 
        end   
    else if(end_game)
        begin
        game_time <= game_time ; 
        if(game_time <= 1800)
            begin
            game_score_idx <= 5 ; 
            end
    else if(rings == 0 && spike_flag)
        begin
        time_over <= 1'b1 ; 
        end
        else
            begin
            game_score_idx <= 3 ; 
            end
        end
    else
        begin
        game_time <= game_time + 1;
        end 
end

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen
always_comb
    begin
    if(end_game)
        begin
            if((DrawX >= 325 && DrawX < 373) && (DrawY >= 366 && DrawY < 398)) // Displays the ring amount next to the ring word
                begin
                rom_address = ((((DrawX - 325) + (((rings % 10) * 25 ) * 2)) / 2) + ((((DrawY - 366) +  (0)) /2) * (272))) ;
                end
            else if((DrawX >= 325 && DrawX < 373) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place // -325 - 297
                begin
                rom_address = ((((DrawX - 325) + (((game_time / 3600) * 25 ) * 2)) / 2) + ((((DrawY - 297) +  (0)) /2) * (272))) ;
                end
            else if((DrawX >= 374 && DrawX < 422) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place Colon
                begin
                rom_address = (((DrawX - 374) + (241 * 2))/2) + ((((DrawY - 297) + (0 * 2)) / 2) * 272);
                end
            else if((DrawX >= 423 && DrawX < 471) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place Colon
                begin
                rom_address = ((((DrawX - 423) + ((((game_time % 3600) / 600) * 25 ) * 2)) / 2) + ((((DrawY - 297) +  (0)) /2) * (272))) ;
                end
            else if((DrawX >= 472 && DrawX < 520) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place Colon
                begin
                rom_address = ((((DrawX - 472) + ((((game_time / 60) % 10) * 25 ) * 2)) / 2) + ((((DrawY - 297) +  (0)) /2) * (272))) ;
                end
            else if((DrawX >= 325 && DrawX < 373) && (DrawY >= 228 && DrawY < 260)) //Display the time score next to the time place // -325 - 297
                begin
                rom_address = ((((DrawX - 325) + ((game_score * 25 ) * 2)) / 2) + ((((DrawY - 228) +  (0)) /2) * (272))) ;
                end
            else if((DrawX >= 374 && DrawX < 422) && (DrawY >= 228 && DrawY < 260)) //Display the time score next to the time place // -325 - 297
                begin
                rom_address = ((((DrawX - 374) + ((0 * 25 ) * 2)) / 2) + ((((DrawY - 228) +  (0)) /2) * (272))) ;
                end
            else if((DrawX >= 423 && DrawX < 471) && (DrawY >= 228 && DrawY < 260)) //Display the time score next to the time place // -325 - 297
                begin
                rom_address = ((((DrawX - 423) + ((0 * 25 ) * 2)) / 2) + ((((DrawY - 228) +  (0)) /2) * (272))) ;
                end
    
        end
    else
        begin
        if((DrawX >= 13 && DrawX < 61) && (DrawY >= 69 && DrawY < 101)) // Minute Number
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (xDim)))
            rom_address = ((((DrawX - 13) + (((game_time / 3600) * 25 ) * 2)) / 2) + ((((DrawY - 69) +  (0)) /2) * (272))) ;
            //rom_address = 554 ; 
            end
        else if((DrawX >= 62 && DrawX < 110) && (DrawY >= 69 && DrawY < 101)) // Colon 
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (xDim)))
            //rom_address = ((((DrawX - 62) + (241 * 2)) / 2) + ((((DrawY - 69) + (0)) / 2) * (54))) ;
            rom_address = (((DrawX - 62) + (241 * 2))/2) + ((((DrawY - 69) + (0 * 2)) / 2) * 272);
            end
        else if((DrawX >= 111 && DrawX < 159) && (DrawY >= 69 && DrawY < 101)) // Tens-Digit of Seconds ; game_time % 60 / 10
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (xDim)))
            //rom_address = (((DrawX - 111) + ((((game_time % 3600) / 600) * 25 ) * 2)) / 2) + ((DrawY - 69) * 272) ;
            rom_address = ((((DrawX - 111) + ((((game_time % 3600) / 600) * 25 ) * 2)) / 2) + ((((DrawY - 69) +  (0)) /2) * (272))) ;
            end
        else if((DrawX >= 160 && DrawX < 208) && (DrawY >= 69 && DrawY < 101)) // Ones Digit of seconds ; game_time % 10
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (xDim))) 
            //rom_address = (((DrawX - 160) + (((game_time % 600) * 25 ) * 2)) / 2) + ((DrawY - 69) * 272) ;
            rom_address = ((((DrawX - 160) + ((((game_time / 60) % 10) * 25 ) * 2)) / 2) + ((((DrawY - 69) +  (0)) /2) * (272))) ;
            end
        else if((DrawX >= 13 && DrawX < 61) && (DrawY >= 12 && DrawY < 44)) //Ring Counter
            begin
            rom_address = ((((DrawX - 13) + ((49) * 2)) / 2) + ((((DrawY - 12) +  (28 * 2)) /2) * (272))) ;
            end
        else if((DrawX >= 111 && DrawX < 159) && (DrawY >= 12 && DrawY < 44)) //Tens Digit of Rings------------------------
            begin
            rom_address = ((((DrawX - 111) + (((rings / 10) * 25 ) * 2)) / 2) + ((((DrawY - 12) +  (0)) /2) * (272))) ; //Do rings/2 to counteract double counting glitch
            end
        else if((DrawX >= 160 && DrawX < 208) && (DrawY >= 12 && DrawY < 44)) //Ones digit of rings --------------------
            begin
            rom_address = ((((DrawX - 160) + (((rings % 10) * 25 ) * 2)) / 2) + ((((DrawY - 12) +  (0)) /2) * (272))) ; //Do rings/2 to counteract double counting glitch
            end
        else if((DrawX >= 0 && DrawX < 48) && (DrawY >= 448 && DrawY < 480)) // Live Counter
            begin
            rom_address = ((((DrawX) + ((25) * 2)) / 2) + ((((DrawY - 448) +  (29 * 2)) /2) * (272))) ;
            end
        else if((DrawX >= 52 && DrawX < 100) && (DrawY >= 448 && DrawY < 480)) // Number for Live Counter
            begin
            if(time_over == 1'b1)
                begin
                rom_address = ((((DrawX - 52) + ((0) * 2)) / 2) + ((((DrawY - 448) +  (0)) /2) * (272))) ;
                end
            else
                begin
                rom_address = ((((DrawX - 52) + ((25) * 2)) / 2) + ((((DrawY - 448) +  (0)) /2) * (272))) ;
                end
            end
        else if( (position >= 50 && position < 690) && (DrawX >= 640 + 50 - position && DrawX < 640 + 50 + 48 - position ) && (DrawY - position_y_ghz >= 200 && DrawY < 232 - position_y_ghz )) // Ring 1
            begin
            if(!collected_ring1)
                begin
                rom_address = ((((DrawX - (640 + 50 - position)) + ((0) * 2)) / 2) + ((((DrawY - 200 + position_y_ghz) +  (28 * 2)) /2) * (272))) ;
                end
            else
                begin
                rom_address = 0;
                end
            end
        else
            begin
            rom_address = 0 ; 
            end
        end
      end
//assign rom_address = ((DrawX * 272) / 640) + (((DrawY * 54) / 480) * 272);
// (DrawX + offset*2)/2

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

spaced_misc_sprite_sheet_rom spaced_misc_sprite_sheet_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

spaced_misc_sprite_sheet_palette spaced_misc_sprite_sheet_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
