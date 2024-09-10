lock steering to up.	
lock throt to body:mu/(body:radius+altitude)^2.
until false{
    if altitude > desired hover:	
        prev_throttle = throttle.
        lock throttle to prev_throttle - 0.1.
    else:	
        prev_throttle = throttle.
        lock throttle to prev_throttle + 0.1.
    wait 0.01.
}