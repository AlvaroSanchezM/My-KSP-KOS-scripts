//stops sas
sas off.

//compass direction of orbit: Usual = 90; North=0, South=180, Clockwise=270
set compass to 90.

//staging initial variable
set actual to 0.
set fairingDeployed to 0.

//steering initial variable
set pitch to 90.

//thrust control
lock throttle to 1.

//output variable
set message to "Launching".

//flow control
set mode to 0.

//for machspeed: check for thermometers and get its value
//thermvalue(ship).

//steering control
UNTIL periapsis > 71000{
    //staging control
    set mt to maxThrust.
    if mt < actual or mt = 0{
        PRINT "Staging".
        lock steering to srfPrograde.
        wait 1.
        STAGE.
        wait 1.
    }
    set actual to mt.
    //local machsp to 0.

    //pitch steering control
    if apoapsis < 70000{
        set pitch to 90*(1-round(ship:apoapsis)/60000).
        lock steering to heading(compass, max(0,pitch)).
        set message to "Ascending".
    }
    if apoapsis > 70000 and apoapsis < 80000{
        set pitch to 90*(1-round(ship:apoapsis)/70000).
        lock steering to heading(compass, max(pitch,0)).
        set message to "Ascending_High_Atmosphere".
        set mode to 1.
    }
    if apoapsis > 80000 and altitude < 70000 and mode = 1{
        rcs on.
        lock steering to srfPrograde.
        lock throttle to 0.
        set message to "Coasting to exit atmosphere".
    }
    if altitude > 70000{
        rcs off.
        set message to "Planning circularization".
        run plan_circularize.
        set message to "Burning to circularize".
        run execute_node.
        if periapsis < 70000{lock steering to prograde. lock throttle to .1.}
        set message to "We are at LKO".
    }
    //fairing deployment
    if altitude > 60000 and fairingDeployed = 0{
        run deploy_fairing.
        set fairingDeployed to 1.
    }
    //OUTPUT
    //PRINT "MachSp:"+ROUND(machsp,0) at (0,12). //Needs a thermometer onboard
    PRINT "P  :"+ROUND(pitch,0) AT (0,14).
    PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0) AT (0,15).
    PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0) AT (0,16).
    PRINT "Maxthrust:"+ROUND(mt,0) AT (0,17).
    //PRINT "DeltaV:"+ROUND(SHIP:DELTAV,0) AT (0,18).
    print "---"+message+"---" at (0,19).
    wait .01.
    clearScreen.

}

print "Program lto.ks finished".
PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0).
PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0).

unlock steering.
unlock throttle.
//leave sas on
sas on.

//deploy solar pannels and antennas.
//run deploy_solar.
//antenna on.
