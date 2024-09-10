//stops sas
sas off.

set actual to 0.

//thrust control
lock throttle to 1.

//steering control
UNTIL SHIP:APOAPSIS > 80000 AND ship:periapsis > 71000 {
    //staging control
    set mt to maxThrust.
    if mt < actual or mt = 0{
        PRINT "Staging".
        STAGE.
    }.
    set actual to mt.

    //steering control
    if apoapsis < 60000{
        set pitch to 90*(1-apoapsis/60000).
    }.
    if apoapsis < 100000{
        set pitch to 90*(1-apoapsis/80000).
    }.
    if apoapsis > 100000{
        set pitch to 90*(1-apoapsis/90000).
    }.
    
    lock steering to heading(90, pitch).
    PRINT "P  :"+ROUND(pitch,0) AT (0,14).
    PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0) AT (0,15).
    PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0) AT (0,16).
    //PRINT "DeltaV:"+ROUND(SHIP:DELTAV,0) AT (0,18).
    wait .01.
    clearScreen.
}.

print "Program finished".
PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0).
PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0).

//leave sas on
sas on.
unlock steering.