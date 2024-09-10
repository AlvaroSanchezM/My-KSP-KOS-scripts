set barometer to 0.
set accelmeter to 0.
set gravmeter to 0.
set thermometer to 0.

PRINT "Full Sensor Dump:".
LIST SENSORS IN SENSELIST.

// TURN EVERY SINGLE SENSOR ON
FOR S IN SENSELIST {
    PRINT "SENSOR: " + S:TYPE.
    PRINT "VALUE:  " + S:DISPLAY.
    IF S:ACTIVE {
    PRINT "     SENSOR IS ALREADY ON.".
    } ELSE {
    PRINT "     SENSOR WAS OFF.  TURNING IT ON.".
    S:TOGGLE().
    }
    if S:type = "pres"{
        set barometer to 1.
    }.
    if s:type = "temp"{
        set thermometer to 1.
    }.
    if s:type = "grav"{
        set gravmeter to 1.
    }.
    if s:type = "acc"{
        set accelmeter to 1.
    }.

}
wait 5.

clearscreen.
until false{
    //set dv to ship:deltav.
    PRINT "P  :"+ROUND(ship:heading,0) AT (0,14).
    PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0) AT (0,15).
    PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0) AT (0,16).
    PRINT "stage:LiqFuel:"+ROUND(Stage:Liquidfuel,0) AT (0,18).
    //PRINT "ship:deltaV:"+ROUND(dv,0) AT (0,19).
    PRINT "maxthrust:"+ROUND(maxThrust,0) AT (0,20).
    if barometer = 1{
        PRINT "airPress:"+ROUND(ship:sensors:pres,0) AT (0,22).
    }.
    if thermometer = 1{
        PRINT "temp:"+ROUND(Ship:sensors:temp,0) AT (0,23).
    }.
    if gravmeter = 1{
        PRINT "grav:"+ROUND(ship:sensors:grav:sqrmagnitude,0) AT (0,24).
    }.
    if accelmeter = 1{
        PRINT "accel:"+ROUND(ship:sensors:acc:sqrmagnitude,0) AT (0,25).
    }.
    if accelmeter = 1 and gravmeter = 1{
        PRINT "accel-grav:"+ROUND((ship:sensors:acc - ship:sensors:grav):sqrmagnitude,0) AT (0,26).
    }.
    wait .01.
    clearScreen.
}.