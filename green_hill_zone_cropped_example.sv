module green_hill_zone_cropped_example (
    input logic Reset,
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input integer position, 
	input integer jump_pos_y,
	input logic cur_jumping_flag,
	input logic vsync,
	input logic [3:0] s_red, s_green, s_blue,
	input logic [3:0] score_red, score_green, score_blue,
	input logic [3:0] misc_red, misc_green, misc_blue,
	input  logic [15:0]  keycode,
	output logic pos_stop,
	output logic [3:0] red, green, blue,
	output logic [5:0] cur_state,
	output logic on_ground,
	output logic previous_jumping_flag,
	output integer position_y_ghz,
	output logic   collected_ring1,
	output logic   sonic_hit,
	output logic   got_enemy_1,
	output logic   end_game,
	output logic   spike_flag,
	//output logic   not_restored,
	output integer   rings // Holds our current ring number
);

logic [17:0] rom_address;
logic [3:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

logic negedge_vga_clk;

integer position_y;

integer image_flag;

integer delay;

logic prev_jumping_flag; 

logic on_ground_delay ; 

logic [7:0]  keycode_prev; 

logic [3:0] sonic_offset;

integer enemies_defeated;

//logic not_restored;

//logic cur_jumping_flag;

assign position_y_ghz = position_y;



//always_comb //Check current state
//    begin
//    if((cur_state == 6'b010010) || (cur_state == 6'b010011) || (cur_state == 6'b010100) || (cur_state == 6'b010101) || (cur_state == 6'b010110))
//        begin
//        cur_jumping_flag = 1;
//        end
//    else
//        begin
//        cur_jumping_flag = 0;
//        end
//    end


// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen
//assign rom_address = ((DrawX * 1680) / 640) + (((DrawY * 128) / 480) * 1680); 
assign rom_address = ((DrawX + position)/7) + ((((DrawY + position_y)/9) * 1680) + (54 * 1680));

assign previous_jumping_flag = prev_jumping_flag;


always_ff @ (posedge vga_clk)
    begin
    prev_jumping_flag <= cur_jumping_flag;
    keycode_prev <= keycode;
    //keycode_prev <= keycode_prev;
    end
    
    
//Right wall check   
always_ff @ (posedge vga_clk)
    begin
    if((DrawX - 275  == 64) && (DrawY - 360  + jump_pos_y /*+ position_Y*/ == 60))
        begin
        if(palette_red == 4'h8 && palette_green == 4'h3 && palette_blue == 4'h1)
            begin
               pos_stop <= 1'b1 ; 
            end
        else
            begin
            pos_stop <= 1'b0 ; 
            end
            end
    end 
//always_ff @ (posedge vga_clk)
//    begin
//        if(/*(DrawX - 275  >= 32) &&*/ (DrawX - 275  == 46) && (DrawY - 360  + jump_pos_y /*+ position_Y*/ == 32))    //Check if bottom right is brown
//	       begin
//	           if(palette_red == 4'h8 && palette_green == 4'h3 && palette_blue == 4'h1)
//	               begin 
////	               if(/*keycode == keycode_prev*/ keycode == 8'h07)
////	                   begin
//	                   pos_stop <= 1'b1;
////	                   end
////                   else //keycode != keycode_prev
////                       begin
////                     //  pos_stop <= 1'b0;
////                       end
//	               end 
////	           else //keycode != keycode_prev
////	               begin
////	              // pos_stop <= 1'b0;
////	               end
//	       end
////	   else
////	       begin
////	      // pos_stop <= 1'b0;
////	       end
//    end

always_ff @ (posedge vga_clk)
    begin 
    if(Reset)
        begin
        position_y <= 0;
        pos_stop <= 0;
        delay <= 0;
        collected_ring1 <= 1'b0;
        rings <= 0 ;
        spike_flag <= 1'b0 ; 
        end
    if(spike_flag)
        begin
        rings <= 0 ;
        end
    else 
        if((DrawX - 275  == 32) && (DrawY - 360  + jump_pos_y /*+ position_Y*/ == 64))
	       begin
	           if(palette_red == 4'h4 && palette_green == 4'h5 && palette_blue == 4'h1)
	               begin 
	               if(cur_jumping_flag == 1)
	                   begin
	                   position_y <= position_y;
	                   on_ground <= 1'b1 ;
	                   end
	               else
	                   begin
	                   position_y <= position_y - 9;
	                   on_ground <= 1'b1 ;
	                   end
	 
	               end 
	           else
	               begin
	               position_y <= position_y;
	               //on_ground <= 1'b0 ; 
	               end
	       end
	    else if((DrawX - 275  == 26) && (DrawY - 360 + jump_pos_y /*+ position_Y*/ == 64))
	       begin
	           if(palette_red == 4'h4 && palette_green == 4'h5 && palette_blue == 4'h1)
	               begin 
	               if(cur_jumping_flag == 1'b1)
	                   begin
	                   position_y <= position_y;
	                   on_ground <= 1'b1 ;
	                   end
	               else
	                   begin
	                   position_y <= position_y - 9;
	                   on_ground <= 1'b1 ;
	                   end
	               end 
	           else
	               begin
	               //position_y <= position_y;
	               //on_ground <= 1'b0 ; 
	               end
	       end
//        else if((DrawX - 275  == 32) && (DrawY - 360  + jump_pos_y /*+ position_Y*/ == 32))    //Check if bottom right is brown
//	       begin
//	           if(palette_red == 4'h8 && palette_green == 4'h3 && palette_blue == 4'h1)
//	               begin 
//	               if(keycode == keycode_prev)
//	                   begin
//	                   pos_stop <= 1;
//	                   end
//                   else //keycode != keycode_prev
//                       begin
//                       pos_stop <= 0;
//                       end
//	               end 
//	           else //keycode != keycode_prev
//	               begin
//	               pos_stop <= 0;
//	               end
//	       end
//	    else if((DrawX - 275  >= 0) && (DrawX - 275  <= 32) && (DrawY - 360 + jump_pos_y /*+ position_Y*/ == 40))  //Check if Sonic got an enemy
//	           begin
//	           if(s_red == 4'hF && s_green == 4'h0 && s_blue == 4'h0)
//	               begin
//	               if(position >= 50 && position < 690)
//	                   begin
//	                   if(cur_jumping_flag == 1'b1)
//	                       begin
//	                       got_enemy_1 <= 1'b1;
//	                       enemies_defeated <= enemies_defeated + 1;
//	                       end
//	                   else 
//	                       begin
//	                       sonic_hit <= 1'b1;
//	                       end
//	                   end
//	               end
//	      end
	    else if((position >= 4932 && position <= 5317) && ((DrawX - 275  >= 0) && (DrawX - 275  <= 34)) && ((DrawY - 360 + jump_pos_y + position_y == 42)))
	       begin
	       if(palette_red ==4'h5 && palette_green == 4'h8 && palette_blue == 4'h9)
	           begin
	           spike_flag <= 1'b1 ; 
	           end
	       else
	           begin
	           spike_flag = 1'b0 ; 
	           end
	       end
	    
	    else if((DrawX - 275  >= 0) && (DrawX - 275  <= 34) && (DrawY - 360 + jump_pos_y + position_y == 42))  //Check if Sonic got a ring
	           begin
	           if(misc_red == 4'hF && misc_green == 4'hF && misc_blue == 4'h0)
	               begin
	               if(position >= 240 && position < 780)
	                   begin
	                   if(collected_ring1 == 1'b0)
	                       begin
	                       rings <= rings + 1 ; //ring counter increment
	                       collected_ring1 <= 1'b1;
	                       end
	                   end
	               end
	      end
	    else if((DrawX - 275  == 27) && (DrawY - 360 + jump_pos_y /*+ position_Y*/ == 64)) 
	           begin 
	           if(palette_red == 4'h4 && palette_green == 4'h5 && palette_blue == 4'h1)
	               begin 
	               if (prev_jumping_flag == 1 && cur_jumping_flag == 0)
	                   begin
	                   position_y <= position_y - 9;
	                   end
	               else
	                   begin
	                   position_y <= position_y;
	                   end
                   on_ground <= 1'b1 ;
	               end 
	           else
	               begin
	                   if(cur_jumping_flag == 1'b1)
	                       begin
	                       position_y <= position_y;
	                       on_ground <= 1'b0 ;
	                       //not_restored <= 1'b1;
	                       delay <= 3;
	                       end
	                   else
	                       begin
	                           if(prev_jumping_flag == 1 && cur_jumping_flag == 0)
	                               begin
	                               position_y <= position_y;
                                   on_ground <= 1'b1 ;
	                               end
/*                               else if(not_restored == 1'b1 && on_ground == 1'b1)
                                   begin
                                   not_restored <= 1'b0;
                                   end*/
                               else
	                               begin
                                   position_y <= position_y + 9;
                                   on_ground <= 1'b0 ;
	                               end
	                       end
	               end
	           end
	    else
           begin
           position_y <= position_y;
           //pos_stop <= 0;
           //on_ground <= 1'b0 ;
           end
    end

always_ff @ (posedge vga_clk) begin  
	red <= 4'h0;
	green <= 4'h0;
	blue <= 4'h0;

	if (blank) begin
	   if(position >= 10953) // Addition to get the score card to display
            begin
             pos_stop = 1'b1 ;  
             end_game = 1'b1 ; 
             red <= score_red ; 
             green <= score_green ; 
             blue <= score_blue ;
             
             if((DrawX >= 325 && DrawX < 373) && (DrawY >= 366 && DrawY < 398)) // Displays the ring amount next to the ring word
                begin
                    if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 325 && DrawX < 373) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 374 && DrawX < 422) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place Colon
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 423 && DrawX < 471) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place Colon
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 472 && DrawX < 520) && (DrawY >= 297 && DrawY < 329)) //Display the time score next to the time place Colon
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 325 && DrawX < 373) && (DrawY >= 228 && DrawY < 260)) //Display the time score next to the time place // -325 - 297
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 374 && DrawX < 422) && (DrawY >= 228 && DrawY < 260)) //Display the time score next to the time place // -325 - 297
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            else if((DrawX >= 423 && DrawX < 471) && (DrawY >= 228 && DrawY < 260)) //Display the time score next to the time place // -325 - 297
                begin
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                        begin
                        red <= score_red ; 
                        green <= score_green ; 
                        blue <= score_blue ;
                        end
                    else
                        begin
                        red <= misc_red ; 
                        green <= misc_green ; 
                        blue <= misc_blue ;
                        end
                end
            end
        else
            begin
            if((DrawX - 275  >= 0 && DrawX - 275 < 36) && (DrawY - 360 + jump_pos_y /*+ position_Y*/ >= 0 && DrawY - 360 + jump_pos_y /*+ position_Y*/ < 64))
               begin 
                   if(s_red == 4'hF && s_green == 4'h0 && s_blue == 4'hC)
                       begin
                       red <= palette_red;
                       green <= palette_green;
                       blue <= palette_blue; 
                       end
                    else 
                       begin
                       red <= s_red ; 
                       green <= s_green ;
                       blue <= s_blue ; 
                       end
               end
            else if((DrawX >= 13 && DrawX < 61) && (DrawY >= 69 && DrawY < 101)) // Minute Number
                begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + (((DrawY - y_cord) + (sprite_offset_y*2))/2) * y_cord))
                if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
                else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 62 && DrawX < 110) && (DrawY >= 69 && DrawY < 101)) // Colon 
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (y_cord))) 
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
                else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 111 && DrawX < 159) && (DrawY >= 69 && DrawY < 101)) // Tens-Digit of Seconds ; game_time % 60 / 10
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (y_cord))) 
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
                else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 160 && DrawX < 208) && (DrawY >= 69 && DrawY < 101)) // Ones Digit of seconds ; game_time % 10
            begin
            //((((DrawX - x_cord) + (sprite_offset_x*2))/2) + ((((DrawY - y_cord) + (sprite_offset_y*2))/2) * (y_cord))) 
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
         else if((DrawX >= 13 && DrawX < 61) && (DrawY >= 12 && DrawY < 44)) //Ring Counter
            begin
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 0 && DrawX < 48) && (DrawY >= 448 && DrawY < 480)) // Live Counter
            begin
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 52 && DrawX < 100) && (DrawY >= 448 && DrawY < 480)) // Number 1 for Live Counter
            begin
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if( (position >= 50 && position < 690) && (DrawX >= 640 + 50 - position && DrawX < 640 + 50 + 48 - position ) && (DrawY >= 200 - position_y && DrawY < 232 - position_y)) // Ring 1
            begin
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 111 && DrawX < 159) && (DrawY >= 12 && DrawY < 44)) //Tens Digit of Rings------------------------
            begin
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
        else if((DrawX >= 160 && DrawX < 208) && (DrawY >= 12 && DrawY < 44)) //Ones digit of rings --------------------
            begin
            if(misc_red == 4'hA && misc_green == 4'h0 && misc_blue == 4'hA)
                    begin
                    red <= palette_red ; 
                    green <= palette_green ; 
                    blue <= palette_blue ; 
                    end
            else
                    begin
                    red <= misc_red ; 
                    green <= misc_green ; 
                    blue <= misc_blue ; 
                    end
            end
//        else if((position >= 240 && position < 780) && (DrawX >= 640 + 240 - position && DrawX < 640 + 240 + 36 - position ) && (DrawY >= 300 - position_y && DrawY < 364 - position_y)) //Enemy
//            begin
//            if(s_red == 4'hF && s_green == 4'h0 && s_blue == 4'hC)
//                    begin
//                    red <= palette_red ; 
//                    green <= palette_green ; 
//                    blue <= palette_blue ; 
//                    end
//            else
//                    begin
//                    red <= s_red ; 
//                    green <= s_green ; 
//                    blue <= s_blue ; 
//                    end
//            end  
        else
           begin
           red <= palette_red;
           green <= palette_green;
           blue <= palette_blue;
           end
           end_game = 1'b0 ; // Sets the end_game flag to be 0 
         end
      end 
   end


green_hill_zone_cropped_rom green_hill_zone_cropped_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

green_hill_zone_cropped_palette green_hill_zone_cropped_palette (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
