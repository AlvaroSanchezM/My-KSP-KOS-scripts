function main {
    //Making it available for any BODY/planet/moon
    //local body is BODY.
    run "util/body_utils".
    //local hasAtmo is BODY:bodyAtmosphere = true.
    local lowestSafeOrbit is LSO()+1000.//Kerbin: 71000

    local lowSfOb is lowestSafeOrbit.
    if ship:body:atm:exists {
        set lowestSafeOrbit to lowSfOb + 20000. 
    }

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
    lock targetThrottle to 1.
    //set dthrottle to 0.

    //output variable
    set message to "Launching".
    //Clearscreen control
    set screen to 0.

    //flow control
    local mode to 0.

    //Launch
    if maxThrust = 0{
        STAGE.
    }

    //steering control
    UNTIL periapsis > lowSfOb{//71000
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

        //gear control
        if alt:radar - 4.7 > 20 and gear{
            gear off.
        }

        //StagingControl2
        set twr to SHIP:availablethrust / ((SHIP:BODY:MU / (ship:body:radius ^ 2)) * SHIP:MASS).//iterative calculation of twr
        doAutoStageByFuel().
        set message to "000OOOoooOOO000".

        //steering and throttle control
        local hdg4inclin is 90-(inclin*COS(ship:longitude-longofascnode)).
        local compassHdg is hdg4inclin.

        // MODE Directory
        if apoapsis < (lowestSafeOrbit-1000) and mode = 0{
            set mode to 1.
        }
        if apoapsis > (lowSfOb-1000) and apoapsis < (lowSfOb*1.126) and mode = 1{
            set mode to 2.
        }
        if apoapsis > (lowSfOb*1.126) and mode = 2{
            if body:atm:exists{
                set mode to 3.
            } else{
                //rcs on.
                //Steering control
                lock steering to prograde.
                //Throttle control
                lock throttle to 0.
                //Program step
                set mode to 5.
            }
        }
        if altitude > (lowSfOb-1000) and mode = 3{
            set mode to 5.
            print "set mode to 5".
        }

        //ACTIONS on each MODE
        if mode = 1{//70000
            //Steering control
            set pitch to 90*(1-round(ship:apoapsis)/(lowestSafeOrbit*0.85)).//60000
            lock steering to heading(compassHdg, max(0,pitch)).//LOOK OUT FOR THE VALUES OF STEERING HERE
            //Throttle control
            //throttleControl().
            //Message
            set message to "Ascending".
        }

        if  mode = 2{//80000{
            //Steering control
            set pitch to 90*(1-round(ship:apoapsis)/(lowSfOb-1000)).
            lock steering to heading(compassHdg, max(pitch,0)).//LOOK OUT FOR THE VALUES OF STEERING HERE
            //Throttle control
            //throttleControl().
            //Program step
            
            //Message
            set message to "Ascending_High_Atmosphere".

        }

        if mode = 3{ //and altitude < (lowSfOb-1000) and mode = 2{
            //rcs on.
            //Steering control
            lock steering to prograde.
            //Throttle control
            lock throttle to 0.
            //set dthrottle to 0.
            //Program step
            set mode to 2.
            //Message
            set message to "Coasting to exit atmosphere".
        }

        if mode = 5{
            rcs off.
            set message to "Planning circularization".
            print "---"+message+"---" at (0,19).
            wait 1.
            clearScreen.
            run plan_circ2.
            wait 1.
            set message to "Burning to circularize".
            print "---"+message+"---" at (0,19).
            wait 1.
            //clearScreen.
            run x_node.
            sas off.
            wait 1.
            //auxiliary mode in case periapsis is not high enough
            //print "set mode to 6".
            set mode to 6.
        }

        if mode = 6{
            //print "found mode AT 6".
            if periapsis < lowSfOb{//in case orbit is not satisfactory
                lock steering to prograde.
                lock throttle to 0.1.
                set message to "We are ALMOST at LKO".
            } else{
                set message to "We are at LKO".
            }
            wait 3.
        }

        //fairing deployment
        if altitude > (lowSfOb*0.85) and fairingDeployed = 0{
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

            print "Target throttle : "+ targetThrottle at (0,8).
            
            print "MODE: "+mode at (0,10).

            print "Init Targ Alt: "+lowestSafeOrbit at (0,12).
            print "LwstSfOrb: "+lowSfOb+"     Apo Target: "+(lowSfOb*1.126) at (0,13).
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

    print "Program lto4.ks finished".
    PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0).
    PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0).
    print "We are at LKO".

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

// function throttleControl {
//     if altitude > 25000 and twr > 1.4{ // and mode < 2 {
//         if round(eta:apoapsis, 0){
//             lock targetThrottle to round(20/round(eta:apoapsis, 0),3).
//             if targetThrottle >= 1{
//                 lock throttle to 1.
//             }else if targetThrottle <= 0.2{
//                 lock throttle to 0.
//             }else{
//                 lock throttle to targetThrottle.
//             }
//         }
//         //local aux is throttle.
//         // if throttle < 1 and throttle > 0 and defined targetThrottle {
//         //     if targetThrottle <= 1 and targetThrottle >= 0 {
//         //         lock throttle to targetThrottle.//aux + dthrottle.
//         //     }
//         // }
//     }
// }

    

main().
