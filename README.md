# Breakout-VHDL
Re-creating the popular arcade game Breakout using a VHDL implementation

This project is segmented into 2 stages A & B.

Stage A:

    Initialise arena, wall, paddle and ball on 32x16 display
        x-coordinates dictated by 32 bit memory value
        y-coordinates dictated by memory address
    Implement up/down ball movement
    Lose a life when ball misses paddle, respawn ball on arena
    Bounce when ball contacts paddle
    Score a point when ball contacts wall
    Remove wall segment after ball contact

Stage B:

    Implement NE, NW, SW, SE ball movement
    Display 'GAME OVER' on arena display when all lives lost
    Reflect new ball movement on paddle bounces
    Implement ball bounce upon arena boundary contact
