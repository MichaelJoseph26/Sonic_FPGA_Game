# Sonic_FPGA_Game
FPGA_SONIC

A FPGA-based implementation of Green Hill Zone from Sonic the Hedgehog (8-bit), built on a MicroBlaze soft processor system. The design integrates GPIO keyboard input, multiple BRAM modules for sprite and background storage, and VGA rendering for dynamic gameplay.

The project recreates classic side-scrolling movement and sprite animation using finite state machines, BRAM-indexed COE files, and real-time collision logic.

Features Included:

* Keyboard Input via USB (MAX3421E): Controls Sonic’s movement (left, right, and jump).

* Dynamic Sprite Animation: FSM-controlled Sonic states (idle, walk, run, jump) with smooth transitions.

* Scrolling Background & Collision Detection: Side-scrolling Green Hill Zone with pixel-based collision to detect terrain, slopes, and rings.

* Collectibles & Scoring: Tracks ring collection, time elapsed, and calculates a final score.

* HUD & Game Timer: Displays lives, rings, and elapsed time; initiates “Game Over” after 10 minutes.

* Custom VGA Display (640x480): Layered rendering from multiple BRAM sources (background, Sonic sprites, HUD, score screen).

Live Demo: 

https://github.com/user-attachments/assets/5521bb2c-16a5-4f30-98ed-36d5edfad702



Built as a final project for ECE 385 at UIUC
This repo only contains code that I wrote. All Vivado / Univeristy sources inlcuding Micoblaze block are not included.
