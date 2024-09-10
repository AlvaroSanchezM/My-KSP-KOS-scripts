//stops sas
sas off.

//staging initial variable
set actual to 0.
set fairingDeployed to 0.

//steering initial variable
set pitch to 90.
//compass direction of orbit: Usual=90; North=0, South=180, Clockwise=270
set compass to 90.
set irregularcompass to false.
set desiredInclination to 0.//Dato INPUT: dato->res: 90-> ,30->32, 30->27, 
//una órbita a 80 km, 0º requiere velocidad de ~2275m/s
//Por defecto en la plataforma tenemos 172m/s dirección E
set firstcompass to 90-desiredInclination.//Este es el input de compás; al final Inclination ~= 85-firstcompass
if firstcompass <> 90 or firstcompass <> 0 or firstcompass <> 180 or firstcompass <> 270{
    set compass to firstcompass. 
}else{
    set compass to ABS(latitude-firstcompass).
    set irregularcompass to true.
}

//thrust control
set g TO SHIP:BODY:MU / (ship:body:radius ^ 2).
lock throttle to 1.
set throttleDiff to .02.
set throttleOrder to 1. //por defecto dejar throttle en 1.

// //TWR según TPKSP
// lock nmass to mass*constant:g0.
// lock thrustweightratio to ship:maxthrust/nmass.
// print thrustweightratio.
// //otro calculo de TWR
// lock twr to ship:availablethrust / ship:mass / body:mu * body:position:sqrmagnitude.
// print twr.

//variable según el tipo de planeta
if ship:body:atm:exists {
    set heightOrbitMin to ship:body:atm:height.
    set delta to 10000.
}else if ship:body = mun{
    set heightOrbitMin to 13000.
    set delta to 3000.
}else if ship:body = minmus{
    set heightOrbitMin to 7000.
    set delta to 1000.
}else if ship:body = moho{
    set heightOrbitMin to 10000.
    set delta to 2000.
}else if ship:body = gilly{
    set heightOrbitMin to 8000.
    set delta to 1000.
}else if ship:body = ike{
    set heightOrbitMin to 16000.
    set delta to 3000.
}else if ship:body = dres{
    set heightOrbitMin to 9000.
    set delta to 3000.
}else if ship:body = eeloo{
    set heightOrbitMin to 8000.
    set delta to 3000.
}else if ship:body = vall{
    set heightOrbitMin to 10000.
    set delta to 1000.
}else if ship:body = tylo{
    set heightOrbitMin to 16000.
    set delta to 3000.
}else if ship:body = bop{
    set heightOrbitMin to 24000.
    set delta to 1000.
}else if ship:body = pol{
    set heightOrbitMin to 8000.
    set delta to 2000.
}else{
    set heightOrbitMin to 70000.
    set delta to 10000.
}
set heightOrbitMax to heightOrbitMin+delta.
set heightAlmostSpace to heightOrbitMin-delta.

//output variable
set message to "Launching".

//flow control
set mode to 0.

//steering control
UNTIL periapsis > (heightOrbitMin+1000){
    //staging control
    set mt to maxThrust.
    if mt < actual or mt = 0{
        PRINT "Staging".
        STAGE.
        wait 1.
    }
    set actual to mt.

    //Throttle control
    set avbthrust TO SHIP:availablethrust.
    set twr to avbthrust / (g * SHIP:MASS).//iterative calculation of twr
    //adjust throttle as ordered
    set throt to throttle.//set para vbles que se actualizan rápidamente, lock para las que se actualizan cada iteración del loop.
    if throttleOrder {//si se ordena aumentar potencia, si potencia no es máx, aumentar en 0.02
        if throttle <> 1 {lock throttle to throt + throttleDiff.}
    }else{//si se ordena disminuir potencia, si potencia no es mínima, disminuir 0.02
        if throttle <> 0 {lock throttle to throt - throttleDiff.}
    }
    //compass control
    if irregularcompass{
        set compass to ABS(latitude-firstcompass).
    }
    
    if apoapsis < heightOrbitMin{
        //Steering control
        set pitch to 90*(1-round(ship:apoapsis)/(heightAlmostSpace)).
        lock steering to heading(compass, max(0,pitch)).//(compass, pitch)
        if altitude > 30000{
            //throttle control
            if eta:apoapsis <= 150 {
                if throttle <> 1 {set throttleOrder to 1.}
            }else{
                if throttle <> 0 {set throttleOrder to 0.}
            }
        }
        set message to "Ascending".
    }
    if apoapsis > heightOrbitMin and apoapsis < heightOrbitMax and altitude < heightOrbitMin{
        //Steering control
        //set pitch to 90*(1-round(ship:apoapsis)/heightOrbitMin).
        lock steering to heading(compass, 0).//(compass, pitch)

        //throttle control
        if eta:apoapsis <= 150 {//
            if throttle <> 1 {set throttleOrder to 1.}
        }else{
            if throttle <> 0 {set throttleOrder to 0.}
        }

        set message to "Ascending_High_Atmosphere".

        set mode to 1.
    }
    if apoapsis > heightOrbitMax and altitude < heightOrbitMin and mode = 1{
        rcs on.
        //Steering control
        lock steering to srfPrograde.

        //throttle control
        set throttleOrder to 0.//cortar potencia de motores

        set message to "Coasting to exit atmosphere".
    }
    
    //fairing deployment
    if altitude > (heightAlmostSpace){
        if fairingDeployed = 0{
            run deploy_fairing.
            set fairingDeployed to 1.
        }
    }
    //final circularization at 80k
    if altitude > heightOrbitMin{
        rcs off.
        set message to "Planning circularization".
        wait .01.
        run plan_circularize.
        wait .01.
        set message to "Burning to circularize".
        wait .01.
        run execute_node.
        wait .01.
        if periapsis < heightOrbitMin{lock steering to prograde. set throttleOrder to 1.}//Last try to stay in orbit
        set message to "We are at LKO".
    }
    
    //OUTPUT
    //PRINT "Prograde:"+(prograde[2]-270) at (0,12).
    Print "1stCompass"+firstcompass AT (0,11).
    PRINT "Compass:"+round(compass,0) AT (0,12).
    PRINT "Lat:"+round(latitude,0) AT (0,13).

    PRINT "P  :"+ROUND(pitch,0) AT (0,14).
    PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0) AT (0,15).
    PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0) AT (0,16).
    PRINT "TWR:"+twr AT (0,17).
    
    //PRINT "DeltaV:"+ROUND(SHIP:DELTAV,0) AT (0,18).
    print "---"+message+"---" at (0,19).
    wait .01.
    clearScreen.

}

print "Program mylto2.ks finished".
PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0).
PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0).

unlock steering.
unlock throttle.
//leave sas on
sas on.

//deploy solar pannels and antennas.
//run deploy_solar.
//antenna on.
