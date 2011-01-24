-------------------------------------------------------------------------------
--
-- An implementation of the classic Simon game for eLua
-- by Ives Negreiros, Led Lab, PUC-Rio
--
-- Runs on Luminary Micro/Texas Instruments with the onboard OLED display.
-- Please check http://wiki.eluaproject.net/Simon for more information
--
-------------------------------------------------------------------------------
local bzrpwm, tmrid = 1
local high_score = 0
local seed = 0
local code = {}
local user = {}
local pwmfreq = 50
local platform = require( pd.board() )
lm3s.disp.init( 1000000 )
pwm.setclock( bzrpwm, 25000000 )

local turn_on = {
  [ 1 ] = function( intensity, pwmfreq )      -- Turn on button 1
    pwm.setup( 4, 100000, intensity )         -- Set the PWM
    pwm.start( 4 )                            -- Set the PWM
    pio.pin.sethigh( pio.PC_4 )
    pwm.setup( bzrpwm, 392, pwmfreq )              -- Set the PWM frequency as the frequency of the note G4
  end, 
  
  [ 2 ] = function( intensity, pwmfreq )      -- Turn on button 2
    pwm.setup( 5, 100000, intensity )         -- Set the PWM
    pwm.start( 5 )                            -- Set the PWM
    pio.pin.sethigh( pio.PC_5 )
    pwm.setup( bzrpwm, 330, pwmfreq )              -- Set the PWM frequency as the frequency of the note E4
  end,

  [ 3 ] = function( intensity, pwmfreq )      -- Turn on button 3
    pwm.setup( 4, 100000, intensity )         -- Set the PWM
    pwm.setup( 5, 100000, intensity )         -- Set the PWM
    pwm.start( 4 )
    pwm.start( 5 )
    pio.pin.sethigh( pio.PC_6 )
    pwm.setup( bzrpwm, 262 , pwmfreq )             -- Set the PWM frequency as the frequency of the note C4
  end,

  [ 4 ] = function( intensity, pwmfreq )      -- Turn on button 4
    pwm.setup( 0, 100000, intensity )         -- Set the PWM
    pwm.start( 0 )
    pio.pin.sethigh( pio.PC_7 )
    pwm.setup( bzrpwm, 196, pwmfreq )              -- Set the PWM frequency as the frequency of the note G3
  end,
}

function turn_off()                          --Turn off all leds
  pwm.stop( 0 )
  pwm.stop( 4 )
  pwm.stop( 5 )
  pwm.stop( bzrpwm )
  pio.port.setlow( pio.PC )
end 

function button_pressed()                    -- Returns the number of the button pressed. If none of buttons are pressed returns 0
  local b1, b2, b3, b4 = pio.pin.getval( pio.PB_0, pio.PB_1, pio.PB_2, pio.PB_3 )  -- get state off buttons
  if b1 == 0 then                            -- tests if first button is pressed
    return 1                                 -- if first button is pressed returns 1
  elseif b2 == 0 then                        -- tests if second button is pressed
    return 2                                 -- if second button is pressed returns 2
  elseif b3 == 0 then                        -- tests if third button is pressed
    return 3                                 -- if third button is pressed returns 3
  elseif b4 == 0 then                        -- tests if fourth button is pressed
    return 4                                 -- if fourth button is pressed returns 4
  end
  return 0
end

function update_score()                      -- prints and updates the score and high score
  lm3s.disp.print( "Your score: " .. #code - 1, 20, 40, 11 )
  if high_score < #code - 1 then
    high_score = #code - 1
  end
  lm3s.disp.print( "High score: " .. high_score, 20, 48, 11 )
  lm3s.disp.print( "Press Select button", 7, 70, 11 )
  lm3s.disp.print( "to replay", 36, 78, 11 )
end

function show_sequence()                     -- blinks LEDs to show the sequence
  for _, v in ipairs( code ) do
    turn_on[ v ]( 99, pwmfreq )
    pwm.start( bzrpwm )
    tmr.delay( 1, 500000 )
    turn_off()
    tmr.delay( 1, 200000 )
  end
end

function increases_code( tempo )             -- Generates the next element of the sequence and puts it at the end of array
  table.insert( code, math.random( 4 ) )
  show_sequence()
end

function init()                              -- Turns on the buttons and sets the initial parameters for the game
  code = {}
  user = {}
  pio.port.setdir( pio.INPUT, pio.PB )
  pio.port.setdir( pio.OUTPUT, pio.PC )
  pio.pin.setpull(  pio.PULLUP, pio.PB_0, pio.PB_1, pio.PB_2, pio.PB_3  )
  pwm.setup( 0, 100000, 99 )
  pwm.setup( 4, 100000, 99 )
  pwm.setup( 5, 100000, 99 )
  while button_pressed() == 0 do
    pwm.start( 5 )
    pio.pin.sethigh( pio.PC_4 )
    tmr.delay( 1, 1000 )
    turn_off()
    pwm.start( 4 )
    pio.pin.sethigh( pio.PC_5 )
    tmr.delay( 1, 1000 )
    turn_off()
    pwm.start( 0 )
    pio.pin.sethigh( pio.PC_7 )
    tmr.delay( 1, 1000 )
    turn_off()
    pwm.start( 4 )
    pwm.start( 5 )
    pio.pin.sethigh( pio.PC_6 )
    tmr.delay( 1, 1000 )
    turn_off()
    seed = seed + 1
  end
  math.randomseed( seed )
  tmr.delay( 1, 200000 )
  lm3s.disp.clear()
  lm3s.disp.print( "eLua Simon", 35, 30, 11 )
  increases_code()
end

function game_over()                         -- Plays the game over sequence and shows the game over screen
  lm3s.disp.clear()
  update_score()
  lm3s.disp.print( "You lost :(", 27, 10, 11 )
  lm3s.disp.print( "  ", 5, 70, 11 )
  lm3s.disp.print( "  ", 110, 70, 11 )
  lm3s.disp.print( "Press any button", 15, 70, 11 )
  lm3s.disp.print( "to restart", 31, 78, 11 )
  for i = 1, 3 do
    turn_on[ 1 ]( 99, pwmfreq )
    tmr.delay( 1, 100000 )
    turn_off()
    turn_on[ 2 ]( 99, pwmfreq )
    tmr.delay( 1, 100000 )
    turn_off()
    turn_on[ 4 ]( 99, pwmfreq )
    tmr.delay( 1, 100000 )
    turn_off()
    turn_on[ 3 ]( 99, pwmfreq )
    tmr.delay( 1, 100000 )
    turn_off()
  end
  init()
end
  
--------------------------------------------------------------------------------
--                                                                            --
--                                 MAIN LOOP                                  --
--                                                                            --
--------------------------------------------------------------------------------

lm3s.disp.print( "eLua Simon", 35, 30, 11 )
lm3s.disp.print( "Press any button", 15, 50, 11 )
lm3s.disp.print( "to start", 41, 58, 11 )
init()
update_score()
lm3s.disp.print( "Press Select button", 7, 70, 11 )
lm3s.disp.print( "to replay", 36, 78, 11 )
while( true ) do

  if platform.btn_pressed( platform.BTN_SELECT ) and #user == 0 then
    show_sequence()
  end
  
  if platform.btn_pressed( platform.BTN_LEFT ) then
    if pwmfreq == 50 then
      pwmfreq = 0
    else
      pwmfreq = 50
    end 
    tmr.delay( 1, 200000 )
  end
  
  local button = button_pressed()
  if button ~= 0 then                        -- Tests if any button is pressed
    tmr.delay( 1, 35000 )                    -- Wait for debounce, if it is the case.
    if button_pressed() == button then       -- Confirm the first read
      turn_on[ button ]( 99, pwmfreq )       -- Turns on the button pressed
      pwm.start( bzrpwm )
      while button_pressed() == button do    -- Wait button be released
        tmr.delay( 1, 35000 )
      end
      turn_off()                             -- Turn off button
      table.insert( user, button )           -- Iincreases the user sequence
      if user[ #user ] ~= code[ #user ] then -- Tests if the button pressed was incorrect
        game_over()                          -- If true, incorrect game over
      end
     if #user == #code then                  -- Testes if it was the last element of sequence
        tmr.delay( 1, 500000 )               -- If true, increases sequence, updates score and clear user code table
       increases_code()
       update_score()
       user = {}      
      end
    end
  end
  turn_on[ 1 ]( 90, pwmfreq )
  tmr.delay( 1, 1000 )
  turn_off()
  turn_on[ 2 ]( 90, pwmfreq )
  tmr.delay( 1, 1000 )
  turn_off()
  turn_on[ 4 ]( 90, pwmfreq )
  tmr.delay( 1, 1000 )
  turn_off()
  turn_on[ 3 ]( 90, pwmfreq )
  tmr.delay( 1, 1000 )
  turn_off()
end
