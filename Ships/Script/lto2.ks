

function main {
    //Making it available for any BODY/planet/moon
    //local body is BODY.
    run "util/body_utils".
    //local hasAtmo is BODY:bodyAtmosphere = true.
    local lowestSafeOrbit is LSO()+1000.//Kerbin: 71000

    //stops sas
    sas off.

    //staging initial variable
    set actual to 0.
    set fairingDeployed to 0.

    //steering initial variable
    set pitch to 90.
    set inclin to 0.// inclination of final orbit in degrees

    if ship:latitude < 0.1 or ship:latitude > -0.1{
        set longofascnode to ship:longitude.
    }
    set longofascnode to ship:longitude.//Pending calculation for variation delending on ship longitude
    if inclin < ship:latitude and (ship:latitude > 0.1 or ship:latitude < -0.1){
        print("ERROR: Unable to reach that inclination ("+inclin+" degrees) from current launch position").
        // Error para cerrar el programa
    }

    //thrust control
    lock throttle to 1.

    //output variable
    set message to "Launching".
    //Clearscreen control
    set screen to 0.

    //flow control
    set mode to 0.

    //Launch
    if maxThrust = 0{
        STAGE.
    }


    //steering control
    UNTIL periapsis > lowestSafeOrbit{//71000
        //staging control1
        // set mt to maxThrust.
        // if mt < actual or mt = 0{
        //     PRINT "Staging".
        //     lock steering to srfPrograde.
        //     wait 1.
        //     STAGE.
        //     wait 1.
        // }
        // set actual to mt.
        //StagingControl2
        set twr to SHIP:availablethrust / ((SHIP:BODY:MU / (ship:body:radius ^ 2)) * SHIP:MASS).//iterative calculation of twr
        doAutoStageByFuel().
        
        //Throttle control in atmo
        // if body:atm:exists{
        //     controlThrustInAtmo(twr).
        // }

        //steering control
        local hdg4inclin is 90-(inclin*COS(ship:longitude-longofascnode)).
        local compassHdg is hdg4inclin.
        if apoapsis < (lowestSafeOrbit-1000){//70000
            set pitch to 90*(1-round(ship:apoapsis)/(lowestSafeOrbit*0.85)).//60000
            lock steering to heading(compassHdg, max(0,pitch)).
            set message to "Ascending".
        }
        if apoapsis > (lowestSafeOrbit-1000) and apoapsis < (lowestSafeOrbit*1.126){//80000{
            set pitch to 90*(1-round(ship:apoapsis)/(lowestSafeOrbit-1000)).
            lock steering to heading(compassHdg, max(pitch,0)).
            set message to "Ascending_High_Atmosphere".
            set mode to 1.
        }
        if apoapsis > (lowestSafeOrbit*1.126) and altitude < (lowestSafeOrbit-1000) and mode = 1{
            rcs on.
            lock steering to prograde.
            lock throttle to 0.
            set message to "Coasting to exit atmosphere".
        }
        if altitude > (lowestSafeOrbit-1000){
            rcs off.
            set message to "Planning circularization".
            wait 1.
            run plan_circularize.
            wait 1.
            set message to "Burning to circularize".
            wait 1.
            run execute_node.
            wait 1.
            if periapsis < (lowestSafeOrbit-1000){lock steering to prograde. lock throttle to .1.}
            set message to "We are at LKO".
        }
        //fairing deployment
        if altitude > (lowestSafeOrbit*0.85) and fairingDeployed = 0{
            run deploy_fairing.
            wait .1.
            set fairingDeployed to 1.
        }
        //OUTPUT
        set auxscr to screen.
        set screen to auxscr + 1.
        if screen = 0{
            clearScreen.
            print "Desired apo= "+lowestSafeOrbit+"m, inclin="+inclin+"º" at (0,2).

            print "Latitude   : "+round(ship:latitude,2) at (0,4).
            print "longitude  : "+round(ship:longitude,2) at (0,5).
            print "compassHdg : "+compassHdg at (0,6).

            //print "Target throttle : "+ targetThrottle at (0,8).
            
            print "MODE: "+mode at (0,10).

            print "Init Targ Alt: "+lowestSafeOrbit at (0,12).
            //print "LwstSfOrb: "+lowSfOb+"     Apo Target: "+(lowSfOb*1.126) at (0,13).
            PRINT "P  :"+ROUND(pitch,0) AT (0,14).
            PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0) AT (0,15).
            PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0) AT (0,16).
            PRINT "TWR:"+round(twr,3) AT (0,17).
            //PRINT "DeltaV:"+ROUND(SHIP:DELTAV,0) AT (0,18).
            print "---"+message+"---" at (0,19).
        }else if screen = 9{
            set screen to -1.
        }
        wait .01.
        

    }

    print "Program lto2.ks finished".
    PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0).
    PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0).

    unlock steering.
    unlock throttle.
    //leave sas on
    sas on.

    //deploy solar pannels and antennas.
    //run deploy_solar.
    //antenna on.
}

function doAutoStageByFuel {
    local tanks is ship:partsTagged("FuelTank").
    for tank in tanks{
        if tank:resources[0]:amount() = 0{//Si algún tanque llega a 0 fuel, STAGE!
            PRINT "Staging".
            STAGE.
            wait 0.4.
        }
    }
}


main().
