`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2024 11:35:45 PM
// Design Name: 
// Module Name: sonic_character
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sonic_character(
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic        clk_25MHz,
    input  logic [15:0]  keycode,
    input logic         on_ground,
    input logic         pos_stop,
    input logic         sonic_hit,
    input logic         end_game,
    input logic         time_over,
    input logic         spike_flag,
    //input logic         not_restored, 

    output logic [9:0]  SonicX, 
    output logic [9:0]  SonicY, 
    output logic [9:0]  SonicS,
    output logic [5:0]  cur_state, 
    output integer        sprite_offset_x,
    output integer        sprite_offset_y,
    output integer        position, 
    output integer        position_y,
    output logic          cur_jumping_flag_del_2  
);
    

	 
    parameter [9:0] Sonic_X_Center=320;  // Center position on the X axis
    parameter [9:0] Sonic_Y_Center=240;  // Center position on the Y axis
    parameter [9:0] Sonic_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Sonic_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Sonic_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Sonic_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Sonic_X_Step=1;      // Step size on the X axis
    parameter [9:0] Sonic_Y_Step=1;      // Step size on the Y axis

    logic [9:0] Sonic_X_Motion;
    logic [9:0] Sonic_X_Motion_next;
    logic [9:0] Sonic_Y_Motion;
    logic [9:0] Sonic_Y_Motion_next;

    logic [9:0] Sonic_X_next;
    logic [9:0] Sonic_Y_next;
    
    logic jumpFlag;
    
    integer idle_counter;
    
    integer run_counter;
    
    integer velocity ; 
    
    integer vel_y ; // y velocity
    
    integer vel_max ; 
    
    integer die_vel_count ; 
    
    integer accel;
    
    integer deccel;  
    
    integer key_press_time;
    
    logic idle_counter_reset;
    
    logic run_counter_reset;
    
    logic [7:0]  prev_keycode;
    
    integer run_spr_time ;
    
    integer v_spr ; 
    
    integer pos ; 
    
    integer pos_y ;
    
    logic   cur_jumping_flag;
    
    logic   cur_jumping_flag_del_1;
    
    logic not_restored;
    
    
    //assign velocity_out = velocity ; 
    

    enum logic [5:0] {
       stand,
       idle_1_1,
       idle_1_2,
       idle_2,
       idle_3,
       look_up,
       stand_L,
       idle_1_1_L,
       idle_1_2_L,
       idle_2_L,
       idle_3_L,
       look_up_L,
       abrupt_1,
       abrupt_2,
       hurt, 
       hurt_L,
       abrupt_1_L,
       abrupt_2_L,
       crouch,
       crouch_L,
       death, 
       death_L,
       jump_1, 
       jump_2, 
       jump_3, 
       jump_4,
       jump_5,
       jump_1_L, 
       jump_2_L, 
       jump_3_L, 
       jump_4_L,
       jump_5_L,
        run_1,
        run_2,
        run_3,
        run_4,
        run_5,
        run_6,
        run_7,
        run_8,
        run_9, 
        run_10,
        run_1_L,
        run_2_L,
        run_3_L,
        run_4_L,
        run_5_L,
        run_6_L,
        run_7_L,
        run_8_L,
        run_9_L, 
        run_10_L
    } state, state_next ; 
    
assign cur_state = state;  //This will be used to pass out the current state

//Delay cur_jumping_flag workaround
//always_ff @ (posedge frame_clk)
//    begin
//    cur_jumping_flag_del_1 <= cur_jumping_flag;
//    cur_jumping_flag_del_2 <= cur_jumping_flag_del_1;
//    end


assign cur_jumping_flag_del_2 = cur_jumping_flag; 


//Next state logic inrementer
always_ff @ (posedge frame_clk)
    begin
    if(Reset)
        begin
        state <= stand ;  
        end
     else
        begin
        state <= state_next ; 
        end
    end
    
//Foot tap counter
always_ff @ (posedge frame_clk)
    begin
    if(Reset | idle_counter_reset) //reset if the reset button hit or we get a keycode
        begin
        idle_counter = 0;
        end 
    else
        begin
        idle_counter = idle_counter + 1;
        end 
end

//Running Counter
always_ff @ (posedge frame_clk)
    begin
    if(Reset | run_counter_reset) //reset if the reset button hit or we get a keycode
        begin
        run_counter = 0;
        end 
    else
        begin
        run_counter = run_counter + 1;
        end 
end


    
//Key Press Counter
always_ff @ (posedge frame_clk)
    begin
    if(Reset | keycode != prev_keycode) //reset if the reset button hit or we get a keycode
        begin
        key_press_time <= 0;
        prev_keycode <= keycode;
        end 
    else
        begin
        key_press_time = key_press_time + 1;
        prev_keycode <= keycode;
        end 
end

//horizontal velocity
always_ff @ (posedge frame_clk) 
    begin
    if(Reset || pos_stop || time_over || end_game)
        begin
        velocity = 0 ; 
        end
    else
        if(keycode == 8'h07 || keycode == 16'h072C || keycode == 16'h2C07) // If The right button is pressed
            begin
            if(pos_stop == 1'b1)
                begin
                velocity <= 0 ;
                end 
            else if(velocity >= 300) // Checks if our velocity is at or above our max speed
                begin
                velocity <= 300 ; // Ensures that our velocity stays at the velocity cap
                end
            else if(velocity < 0) //Need to abruptly go in the other direction
                begin
                velocity <= velocity + 18;
                end
            else
                begin
                velocity <= velocity + 5; // Continue increasing our speed based on the key press
                end 
            end
        else if(keycode == 8'h04 || keycode == 16'h042C || keycode == 16'h2C04) // If The left button is pressed
            begin
            if(velocity <= -300) // Checks if our velocity is at or above our max speed
                begin
                velocity <= -300 ; // Ensures that our velocity stays at the velocity cap
                end
            else if(velocity > 0) //Need to abruptly go in the other direction
                begin
                velocity <= velocity - 18;
                end
            else
                begin
                velocity <= velocity - 5; // Continue increasing our speed based on the key press
                end 
            end
        else // If we are not holding right or left
            begin
            if(velocity > 0)
                begin   
                if((velocity - 5) <= 0) // Our velocity is less than 0 ; we want our lower bound on our velocity to be 0
                    begin
                    velocity <= 0 ; // Ensures our velocity is 0
                    end
                else
                    begin 
                    velocity <= velocity - 5 ; // reduces our velocity until it is 0
                    end
            end
            else //if (velocity < 0)
                begin   
                if((velocity + 5) >= 0) // Our velocity is greater than 0 ; we want our upper bound on our velocity to be 0
                    begin
                    velocity <= 0 ; // Ensures our velocity is 0
                    end
                else
                    begin 
                    velocity <= velocity + 5 ; // increases our velocity until it is 0
                    end
                end
                
        end
 end
 
 //vertical velocity
 always_ff @ (posedge frame_clk)
    begin
        if(Reset)
            begin
            vel_y <= 0 ; 
            die_vel_count <= 0 ;
            end
        else
            begin
            if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04 || keycode == 16'h2C07 || keycode == 16'h072C)  && cur_jumping_flag == 1'b0) // I think this condition will change to state_next != the jump statees
                begin 
                vel_y <= -70 ; 
                end
            else if(time_over == 1'b1 && die_vel_count == 0)
                begin
                vel_y <= -110 ; 
                die_vel_count <= 1 ; 
                end
            else if(time_over == 1'b1 && die_vel_count == 1)
                begin
                vel_y <= vel_y + 2 ; 
                end
            else
                begin
                if(cur_jumping_flag == 1 && on_ground == 0)
                    begin
                    vel_y <= vel_y + 2 ; 
                    end
                else
                    begin
                    vel_y <= 0 ; 
                    end
                end
            end
    
    end
    
always_ff @ (posedge frame_clk) // Horizontal position
    begin
    if(Reset)
        begin
        pos <= 0 ; 
        position <= pos ; 
        end
    else
        begin
        pos += velocity / 28; 
        position <= pos ; 
        end
    end 

always_comb
    begin
    position_y = pos_y ;
    end


always_ff @ (posedge frame_clk)  // To fix the current issue I think i need to remove the some of the offsets from somewhere in the green hill example file
    begin
    if(Reset)
        begin
        pos_y <= 0 ;
        not_restored <= 1'b0; 
        end
    else
        begin
         pos_y <= pos_y + vel_y / -6 ;
  
        if(cur_jumping_flag) 
            begin
            not_restored <= 1'b1;  
            end
        else if(not_restored == 1'b1 && on_ground == 1'b1)
           begin
           not_restored <= 1'b0;
           pos_y <= pos_y + 18;
           end
        end
    end   

//Logic for current state
always_comb
    begin    
    case(state)
        stand: 
            begin
            sprite_offset_x = 0;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ; // addedd
            end
        look_up :
            begin
            sprite_offset_x = 24;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        idle_1_1 :
            begin
            sprite_offset_x = 72;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        idle_1_2 :
            begin
            sprite_offset_x = 72;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        idle_2 :
            begin
            sprite_offset_x = 48;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        idle_3 :
            begin
            sprite_offset_x = 96;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        death :
            begin
            sprite_offset_x = 0;
            sprite_offset_y = 133;
            cur_jumping_flag = 0 ;
            end
        hurt : 
            begin
            sprite_offset_x = 48;
            sprite_offset_y = 133;
            cur_jumping_flag = 0 ;
            end
        run_1 : 
            begin 
            sprite_offset_x = 120;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_2 : 
            begin
            sprite_offset_x = 144;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_3 : 
            begin
            sprite_offset_x = 168;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_4 : 
            begin
            sprite_offset_x = 192;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_5 : 
            begin
            sprite_offset_x = 216;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_6 : 
            begin 
            sprite_offset_x = 240;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_7 : 
            begin
            sprite_offset_x = 264;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_8 : 
            begin
            sprite_offset_x = 288;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_9 : 
            begin
            sprite_offset_x = 312;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        run_10 : 
            begin
            sprite_offset_x = 336;
            sprite_offset_y = 0;
            cur_jumping_flag = 0 ;
            end
        stand_L: 
            begin
            sprite_offset_x = 0;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        look_up_L :
            begin
            sprite_offset_x = 24;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        idle_1_1_L :
            begin
            sprite_offset_x = 72;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        idle_1_2_L :
            begin
            sprite_offset_x = 72;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        idle_2_L :
            begin
            sprite_offset_x = 48;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        idle_3_L :
            begin
            sprite_offset_x = 96;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        death_L :
            begin
            sprite_offset_x = 0;
            sprite_offset_y = 165;
            cur_jumping_flag = 0 ;
            end
        hurt_L : 
            begin
            sprite_offset_x = 48;
            sprite_offset_y = 165;
            cur_jumping_flag = 0 ;
            end
        run_1_L : 
            begin 
            sprite_offset_x = 120;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_2_L : 
            begin
            sprite_offset_x = 144;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_3_L : 
            begin
            sprite_offset_x = 168;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_4_L : 
            begin
            sprite_offset_x = 192;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_5_L : 
            begin
            sprite_offset_x = 216;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_6_L : 
            begin 
            sprite_offset_x = 240;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_7_L : 
            begin
            sprite_offset_x = 264;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_8_L : 
            begin
            sprite_offset_x = 288;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_9_L : 
            begin
            sprite_offset_x = 312;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        run_10_L : 
            begin
            sprite_offset_x = 336;
            sprite_offset_y = 32;
            cur_jumping_flag = 0 ;
            end
        abrupt_1 : 
            begin
            sprite_offset_x = 120;
            sprite_offset_y = 132;
            cur_jumping_flag = 0 ;
            end
        abrupt_2 : 
            begin
            sprite_offset_x = 144;
            sprite_offset_y = 132;
            cur_jumping_flag = 0 ;
            end
        abrupt_1_L : 
            begin
            sprite_offset_x = 120;
            sprite_offset_y = 164;
            cur_jumping_flag = 0 ;
            end
        abrupt_2_L : 
            begin
            sprite_offset_x = 144;
            sprite_offset_y = 164;
            cur_jumping_flag = 0 ;
            end  
        crouch :
            begin
            sprite_offset_x = 0;
            sprite_offset_y = 65;
            cur_jumping_flag = 0 ;
            end
       crouch_L : 
            begin
            sprite_offset_x = 0;
            sprite_offset_y = 97;
            cur_jumping_flag = 0 ;
            end  
       jump_1 : 
            begin
            sprite_offset_x = 120;
            sprite_offset_y = 65;
            cur_jumping_flag = 1 ;
            end
       jump_2 : 
            begin
            sprite_offset_x = 24;
            sprite_offset_y = 65;
            cur_jumping_flag = 1 ;
            end
       jump_3 : 
            begin
            sprite_offset_x = 48;
            sprite_offset_y = 65;
            cur_jumping_flag = 1 ;
            end
       jump_4 : 
            begin
            sprite_offset_x = 72;
            sprite_offset_y = 65;
            cur_jumping_flag = 1 ;
            end
       jump_5 : 
            begin
            sprite_offset_x = 96;
            sprite_offset_y = 65;
            cur_jumping_flag = 1 ;
            end
       jump_1_L : 
            begin
            sprite_offset_x = 120;
            sprite_offset_y = 97;
            cur_jumping_flag = 1 ;
            end
       jump_2_L : 
            begin
            sprite_offset_x = 24;
            sprite_offset_y = 97;
            cur_jumping_flag = 1 ;
            end
       jump_3_L : 
            begin
            sprite_offset_x = 48;
            sprite_offset_y = 97;
            cur_jumping_flag = 1 ;
            end
       jump_4_L : 
            begin
            sprite_offset_x = 72;
            sprite_offset_y = 97;
            cur_jumping_flag = 1 ;
            end
       jump_5_L : 
            begin
            sprite_offset_x = 96;
            sprite_offset_y = 97;
            cur_jumping_flag = 1 ;
            end             
         default :
            begin
            sprite_offset_x = 0 ;
            sprite_offset_y = 0 ; 
            cur_jumping_flag = 0 ; 
            end 
     endcase
end


// Next State Logic
always_comb 
    begin
//    velocity = 0 ; 
    state_next = state ; //next state is the current state by default
//    accel = 5; //Acceleration value
//    deccel = -5; //Decceleration value

    vel_max = 300;//Velocity Max
    
    if(velocity < 0)
        begin
        v_spr = -1 * velocity ; 
        end
    else
        begin
        v_spr = velocity ;
        end
    
    if(keycode == 8'h07 || keycode == 8'h04)
        begin
        if((930 / (18 + v_spr)) <= 5)
            begin
            run_spr_time = 930 / (18 + v_spr) ; // Time between sprite changes for run animation
            end
        else
            begin
            run_spr_time = 8;
            end
        end
    else
            begin
            run_spr_time = 8;
            end
    
    
    // NEXT STEP DETECTING MULTIPLE KEY PRESSES
    
    unique case (state)
        stand: 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)          //Look up
                begin
                state_next = look_up ; 
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1;
                accel = 5; 
                run_counter_reset = 0 ; 
//                if(vel_max > velocity + (accel * key_press_time) ) //Pick velocity value
//                    begin
//                    velocity = velocity + (accel * key_press_time); 
//                    end
//                else
//                    begin
//                    velocity = vel_max;
//                    end
                end
            else if(keycode == 8'h04)     //Go left
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1;
                accel = 5; 
                run_counter_reset = 0 ; 
//                if(vel_max > velocity + (accel * key_press_time) ) //Pick velocity value
//                    begin
//                    velocity = velocity + (accel * key_press_time); 
//                    end
//                else
//                    begin
//                    velocity = vel_max;
//                    end
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 360) //Standing for 6 seconds
                begin
                state_next = idle_1_1;
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin                   //Default to standing
                state_next = stand;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
//                velocity = 0;
                end
                
        idle_1_1 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up ;
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 10) 
                begin
                state_next = idle_2;
                idle_counter_reset = 1; 
                run_counter_reset = 1 ;
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = idle_1_1;
                idle_counter_reset = 0;
                run_counter_reset = 1 ;
                end
                
        idle_1_2 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 12) 
                begin
                state_next = idle_3;
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = idle_1_2;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
                
        idle_2 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 12) 
                begin
                state_next = idle_1_2;
                idle_counter_reset = 1;
                run_counter_reset = 1 ;  
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = idle_2;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
                
                
        idle_3 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ;
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 12) 
                begin
                state_next = idle_1_2;
                idle_counter_reset = 1;
                run_counter_reset = 1 ;  
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = idle_3;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
                       
      
        look_up :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up ; 
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                state_next = stand ; 
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
         
         death : 
            state_next = death ; 
            
         hurt :
            if(run_counter >= 3)
                begin
                state_next = stand ;  
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = hurt ; 
                idle_counter_reset = 1; 
                run_counter_reset = 0 ; 
                end
                
        run_1 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time)  //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;  
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_2;
                    end 
                else //Don't need a new sprite
                    begin
                    state_next = run_1;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else //if(keycode != 8'h07) //Deccelerate
               begin
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = velocity + deccel;
                    if(velocity > 0)
                        begin 
                        state_next = run_2;
                        end
                    else //if (velocity <= 0)
                        begin
                        state_next = stand; 
                        end
                     end
                else //Don't need a new sprite
                    begin
                    state_next = run_1;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                end
                
        run_2 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_3;
                    end
                else 
                    begin
                    state_next = run_2;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end 
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_3;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_2;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
               end
            
        run_3 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_4;
                    end
                else 
                    begin
                    state_next = run_3;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_4;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_3;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
               end
            
        run_4 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_5;
                    end
                else 
                    begin
                    state_next = run_4;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
             begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_5;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_4;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
              end
            
        run_5 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_6;
                    end
                else 
                    begin
                    state_next = run_5;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_6;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_5;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
               end
                 
        run_6 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = velocity + (accel * key_press_time);
                    if(velocity >= vel_max) //If at top speed
                        begin
//                        velocity = vel_max;
                        state_next = run_7;
                        end
                    else 
                        begin
                        state_next = run_1;
                        end
                    end 
                 else      //No new sprite needed
                    begin
                    state_next = run_6;
                    idle_counter_reset = 1;
                    run_counter_reset = 0; 
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_6;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                 end
        run_7 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end    
            else if(keycode == 8'h07)     //Go right
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_8;
                    end
                 else 
                    begin 
                    state_next = run_7;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 0 ; //Was run_counter_reset = 1 ;
                    state_next = run_1;
//                    velocity = velocity + deccel;
                    end 
                else 
                    begin
                    state_next = run_7;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end     
                 end
                           
                 
         run_8 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07 && run_counter)     //Go right
                if(run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_9;
                    end 
                else 
                    begin 
                    state_next = run_8;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = run_8;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                 end
                 
                 
         run_9 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07 && run_counter)     //Go right
                if(run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_10;
                    end 
                else 
                    begin 
                    state_next = run_9;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = run_9;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                 end
                 
        run_10 : 
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07 && run_counter)     //Go right
                if(run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_7;
                    end 
                else 
                    begin 
                    state_next = run_7;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h04)
                begin
                    if(velocity >= 50)
                        begin
                        state_next = abrupt_1;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end 
                    else
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = run_10;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                   end
        abrupt_1 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(velocity <= 0)
                begin
                idle_counter_reset = 1; 
                run_counter_reset = 1 ;
                state_next = run_1_L;
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07 || keycode == 8'h00) // resolves the funny perma-abrupt running
                begin
                state_next = run_1 ; 
                run_counter_reset = 1 ; 
                idle_counter_reset = 1 ; 
                end
            else
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = abrupt_2;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = abrupt_1;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                end
        abrupt_2 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(velocity <= 0)
                begin
                idle_counter_reset = 1; 
                run_counter_reset = 1 ;
                state_next = run_1_L;
                end
            else if(keycode == 8'h07 || keycode == 8'h00) // resolves the funny perma-abrupt running
                begin
                state_next = run_1 ; 
                run_counter_reset = 1 ; 
                idle_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h072C || keycode == 16'h2C07) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = abrupt_1;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = abrupt_2;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                end
        crouch : // ADDED -------------------------
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h16)
                begin
                state_next = crouch ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = stand ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
        jump_1 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_2 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                    if(on_ground)
                        begin
                        state_next = stand ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_1 ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end
                end
         jump_2 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_3 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground) // condition on velocity
                        begin
                        state_next = stand ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_2 ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end
                end
         jump_3 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end   
            else if(run_counter > 5)
                begin
                state_next = jump_4 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground)
                        begin
                        state_next = stand ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_3 ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end 
                end
         jump_4 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_5 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground)
                        begin
                        state_next = stand ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_4 ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end
                end   
         jump_5 :
            if(time_over)
                begin
                state_next = death ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(spike_flag == 1'b1)
                begin
                state_next = hurt ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground)
                        begin
                        state_next = stand ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_5 ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end 
                end           
//----------------------       Left States      -------------------------------------------------------
        stand_L: 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)          //Look up
                begin
                state_next = look_up_L ; 
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)     //Go right
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1;
                accel = 5; 
                run_counter_reset = 0 ; 
//                if(vel_max > velocity + (accel * key_press_time) ) //Pick velocity value
//                    begin
//                    velocity = velocity + (accel * key_press_time); 
//                    end
//                else
//                    begin
//                    velocity = vel_max;
//                    end
                end
            else if(keycode == 8'h04)     //Go left
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1;
                //accel = 5; 
                run_counter_reset = 0 ; 
//                if(vel_max > velocity + (accel * key_press_time) ) //Pick velocity value
//                    begin
//                    velocity = velocity + (accel * key_press_time); 
//                    end
//                else
//                    begin
//                    velocity = vel_max;
//                    end
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 360) //Standing for 6 seconds
                begin
                state_next = idle_1_1_L;
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin                   //Default to standing
                state_next = stand_L;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
//                velocity = 0;
                end
                
        idle_1_1_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up_L ;
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 10) 
                begin
                state_next = idle_2_L;
                idle_counter_reset = 1; 
                run_counter_reset = 1 ;
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = idle_1_1_L;
                idle_counter_reset = 0;
                run_counter_reset = 1 ;
                end
                
        idle_1_2_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up_L ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 12) 
                begin
                state_next = idle_3_L;
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = idle_1_2_L;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
                
        idle_2_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up_L ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 12) 
                begin
                state_next = idle_1_2_L;
                idle_counter_reset = 1;
                run_counter_reset = 1 ;  
                end
            else
                begin
                state_next = idle_2_L;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
                
                
        idle_3_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up_L ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ;
                end
            else if(keycode == 8'h16) // Crouch
                begin
                state_next = crouch_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(idle_counter >= 12) 
                begin
                state_next = idle_1_2_L;
                idle_counter_reset = 1;
                run_counter_reset = 1 ;  
                end
            else
                begin
                state_next = idle_3_L;
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
                
        hurt_L :
            if(run_counter >= 3)
                begin
                state_next = stand_L ;  
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = hurt ; 
                idle_counter_reset = 1; 
                run_counter_reset = 0 ; 
                end
                       
      
        look_up_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h1A)
                begin
                state_next = look_up_L ; 
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h07)
                begin
                state_next = run_1 ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)
                begin
                state_next = run_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                state_next = stand_L ; 
                idle_counter_reset = 0;
                run_counter_reset = 1 ; 
                end
        death_L : 
            state_next = death_L ; 
                
        run_1_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time)  //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;  
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_2_L;
                    end 
                else //Don't need a new sprite
                    begin
                    state_next = run_1_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
             else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else //if(keycode != 8'h04) //Deccelerate
               begin
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = velocity + deccel;
                    if(velocity < 0 )
                        begin 
                        state_next = run_2_L;
                        end
                    else //if (velocity <= 0)
                        begin
                        state_next = stand_L; 
                        end
                     end
                else //Don't need a new sprite
                    begin
                    state_next = run_1_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                end
                
        run_2_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_3_L;
                    end
                else 
                    begin
                    state_next = run_2_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
             else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_3_L;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_2_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
               end
            
        run_3_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_4_L;
                    end
                else 
                    begin
                    state_next = run_3_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
             else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_4_L;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_3_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
               end
            
        run_4_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_5_L;
                    end
                else 
                    begin
                    state_next = run_4_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
             else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
             begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_5_L;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_4_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
              end
            
        run_5_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ;
//                    velocity = velocity + (accel * key_press_time);
                    state_next = run_6_L;
                    end
                else 
                    begin
                    state_next = run_5_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
             else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_6_L;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_5_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end 
               end
                 
        run_6_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time) //Need a new sprite
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = velocity + (accel * key_press_time);
                    if(velocity <= (-1 * vel_max)) //If at top speed
                        begin
//                        velocity = vel_max;
                        state_next = run_7_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                    else 
                        begin
                        state_next = run_1_L;
                        idle_counter_reset = 1; 
                        run_counter_reset = 1 ;
                        end
                    end 
                 else      //No new sprite needed
                    begin
                    state_next = run_6_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0; 
//                    velocity = velocity + (accel * key_press_time);
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
             else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
             else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1_L;
//                    velocity = velocity + deccel;
                    end
                else 
                    begin
                    state_next = run_6_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                 end
        run_7_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04)     //Go left
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_8_L;
                    end
                 else 
                    begin 
                    state_next = run_7_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 0 ; //Was run_counter_reset = 1 ;
                    state_next = run_1_L;
//                    velocity = velocity + deccel;
                    end 
                else 
                    begin
                    state_next = run_7_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end     
                 end
                           
                 
         run_8_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04 && run_counter)     //Go left
                if(run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_9_L;
                    end 
                else 
                    begin 
                    state_next = run_8_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h07)
                begin
                     if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1_L;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = run_8_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                 end
                 
                 
         run_9_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04 && run_counter)     //Go left
                if(run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_10_L;
                    end 
                else 
                    begin 
                    state_next = run_9_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1_L;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = run_9_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                 end
                 
        run_10_L : 
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 8'h04 && run_counter)     //Go left
                if(run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
//                    velocity = vel_max;
                    state_next = run_7_L;
                    end 
                else 
                    begin 
                    state_next = run_7_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = vel_max;
                    end
             else if(keycode == 8'h07)
                begin
                    if(velocity <= -50)
                        begin
                        state_next = abrupt_1_L;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = run_1;
                        run_counter_reset = 1 ; 
                        idle_counter_reset = 1 ; 
                        end
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else 
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = run_1_L;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = run_10_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                   end 
        abrupt_1_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(velocity >= 0)
                begin
                idle_counter_reset = 1; 
                run_counter_reset = 1 ;
                state_next = run_1;
                end
            else if(keycode == 8'h04 || keycode == 8'h00) // resolves the funny perma-abrupt running
                begin
                state_next = run_1_L ; 
                run_counter_reset = 1 ; 
                idle_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = abrupt_2_L;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = abrupt_1_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                end   
                 
        abrupt_2_L :     
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(velocity >= 0)
                begin
                idle_counter_reset = 1; 
                run_counter_reset = 1 ;
                state_next = run_1;
                end
            else if(keycode == 8'h04 || keycode == 8'h00) // resolves the funny perma-abrupt running
                begin
                state_next = run_1_L ; 
                run_counter_reset = 1 ; 
                idle_counter_reset = 1 ; 
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                if(run_counter >= run_spr_time)
                    begin
                    idle_counter_reset = 1; 
                    run_counter_reset = 1 ; 
                    state_next = abrupt_1_L;
//                    velocity = velocity + deccel;
                    end      
                else 
                    begin 
                    state_next = abrupt_2_L;
                    idle_counter_reset = 1;
                    run_counter_reset = 0;
//                    velocity = velocity + deccel;
                    end
                end       
        crouch_L : //ADDED ------------------------------
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(keycode == 16'h16)
                begin
                state_next = crouch_L ; 
                idle_counter_reset = 1;
                run_counter_reset = 1 ;  
                end
            else if((keycode == 8'h2C || keycode == 16'h042C || keycode == 16'h2C04) && cur_jumping_flag == 1'b0) // Jump
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else
                begin
                state_next = stand_L ;
                idle_counter_reset = 1; 
                run_counter_reset = 1 ; 
                end   
        jump_1_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_2_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                    if(on_ground)
                        begin
                        state_next = stand_L ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_1_L ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end
                end
         jump_2_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_3_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground) // condition on velocity
                        begin
                        state_next = stand_L ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_2_L ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end
                end
         jump_3_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_4_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground)
                        begin
                        state_next = stand_L ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_3_L ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end 
                end
         jump_4_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_5_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground)
                        begin
                        state_next = stand_L ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_4_L ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end
                end   
         jump_5_L :
            if(time_over)
                begin
                state_next = death_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ; 
                end
            else if(run_counter > 5)
                begin
                state_next = jump_1_L ; 
                idle_counter_reset = 1 ; 
                run_counter_reset = 1 ;
                end
            else
                begin
                if(on_ground)
                        begin
                        state_next = stand_L ; 
                        idle_counter_reset = 1 ;
                        run_counter_reset = 1 ; 
                        end 
                    else
                        begin
                        state_next = jump_5_L ; 
                        idle_counter_reset = 1 ; 
                        run_counter_reset = 0 ; 
                        end 
                end                       
        default : 
            begin
           // state = stand ; 
            idle_counter_reset = 0;
            run_counter_reset = 0;
            end 
      
     endcase 
end



    always_comb 
        begin
        Sonic_Y_Motion_next = Sonic_Y_Motion; // set default motion to be same as prev clock cycle 
        Sonic_X_Motion_next = Sonic_X_Motion;

        //modify to control Sonic motion with the keycode
//        if (keycode == 8'h1A) //Look Up
//            begin
//            //Look Up Sprite
//            sprite_offset_x = 24;
//            sprite_offset_y = 0;
//            end
//        else if (keycode == 8'h16) //Crouch
//            begin
//            //Crouch Sprite
//            end
//        else if (keycode == 8'h04) //Left
//            begin
//            Sonic_X_Motion_next = -10'd1;
//            Sonic_Y_Motion_next = 10'd0;
//            end
//        else if (keycode == 8'h07) //Right
//            begin
//            Sonic_X_Motion_next = 10'd1;
//            Sonic_Y_Motion_next = 10'd0;
//            end
//        else if (keycode == 8'h2C) //Jump (Spacebar)
//            begin
//            //Need some sort of condition to denote if we are on the ground or not
////            Sonic_Y_Motion_next = -10'd1;
////            Sonic_X_Motion_next = 10'd0;
//            jumpFlag = 1'b1;
//            end
//        else //Sonic is in a neutral position
//            begin
//            // if statement that keeps track of the most recent left and right press
//            sprite_offset_x = 0;
//            sprite_offset_y = 0;
//            end

        if ( (SonicY + SonicS) >= Sonic_Y_Max )  // Sonic is at the bottom edge
        begin
            Sonic_Y_Motion_next = 10'd0;  // Sonic is on top the ground
        end
//        else if ( (SonicY - SonicS) <= Sonic_Y_Min )  // Sonic is at the top edge, BOUNCE!
//        begin
//            Sonic_Y_Motion_next = Sonic_Y_Step;
//        end  
       //fill in the rest of the motion equations here to bounce left and right
//        if ( (SonicX + SonicS) >= Sonic_X_Max )  // Sonic is at the right edge, BOUNCE!
//        begin
//            Sonic_X_Motion_next = (~ (Sonic_X_Step) + 1'b1);  // set to -1 via 2's complement.
//        end
//        else if ( (SonicX - SonicS) <= Sonic_X_Min )  // Sonic is at the left edge, BOUNCE!
//        begin
//            Sonic_X_Motion_next = Sonic_X_Step;
//        end  


    end

    assign SonicS = 16;  // default Sonic size
    assign Sonic_X_next = (SonicX + Sonic_X_Motion_next);
    assign Sonic_Y_next = (SonicY + Sonic_Y_Motion_next);
    
//    always_ff @(posedge frame_clk)
//    begin: Jump_Logic
//        if(jumpFlag)
//        begin
            
            
//        end
//    end
   
    always_ff @(posedge frame_clk) //make sure the frame clock is instantiated correctly
    begin: Move_Sonic
        if (Reset)
        begin 
            Sonic_Y_Motion <= 10'd0; //Sonic_Y_Step;
			Sonic_X_Motion <= 10'd0; //Sonic_X_Step;  //changed from 10'd1
            
			SonicY <= Sonic_Y_Center;
			SonicX <= Sonic_X_Center;
        end
        else 
        begin 

			Sonic_Y_Motion <= Sonic_Y_Motion_next; 
			Sonic_X_Motion <= Sonic_X_Motion_next; 

            SonicY <= Sonic_Y_next;  // Update Sonic position
            SonicX <= Sonic_X_next;
			
		end 
    end


    
      

endmodule
