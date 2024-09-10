clearScreen.
print "Program: ex_node" at (0,2).
//Calculos iniciales: timestamp(), nd:eta, burn_duration, half_burn_duration, etc.
set nd to nextnode.
//turn off SAS
SAS off.

print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag) at (0,4).
print "Node date-time:" + (nd:eta+missionTime) at (0,5).
//calculate ship's max acceleration
set max_acc to ship:maxthrust/ship:mass.

// Now we just need to divide deltav:mag by our ship's max acceleration
// to get the estimated time of the burn.
//
// Please note, this is not exactly correct.  The real calculation
// needs to take into account the fact that the mass will decrease
// as you lose fuel during the burn.

set burn_duration to nd:deltav:mag/max_acc.
print "Crude Estimated burn duration: " + round(burn_duration) + "s"at (0,7).
set beginNodeBurn to missionTime + nd:eta - burn_duration/2.
print "Node burn begins at date-time:" + (beginNodeBurn) at (0,8).

//initial aproximation to node vector
set np to nd:deltav. //points to node, don't care about the roll direction.
lock steering to np. //apuntar al vector nodo, prioridad 0

set dv0 to nd:deltav. //guarda el valor inicial de la deltav del nodo

set begunNode to 1.//ESTADO: indica si se ha iniciado la quema del nodo

set done to False.

//we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
set tset to 0.
lock throttle to tset.

until done{
    //Apuntar al vector nodo, prioridad 0
    //recalculate steering
    set np to nd:deltav.
    lock steering to np.

    //esperar a estar apuntado, prioridad 3
    //esperar a que llegue el nodo, prioridad 5
    //iniciar quema del nodo, prioridad 1 (ejecutar 1 sola vez)
    if missionTime >= beginNodeBurn{
        if throttle = 0 and begunNode = 0 {
            //iniciar quema del nodo
            set tset to 1.
            set begunNode to 1.//ESTADO: indica que se ha empezado a quemar
            set actual to 0.//staging variable
        }
    } else {
        clearScreen.
        print "Direccion dV a "+ round(vang(np, ship:facing:vector),.01)+" grados del cohete" at (0,10).
        if vang(np, ship:facing:vector) < 0.25{
            warpto(beginNodeBurn - 5).
        }
    }
    
    if throttle = 1{
        //recalculate steering
        set np to nd:deltav.
        lock steering to np.
        //recalculate current max_acceleration, as it changes while we burn through fuel
        if ship:maxthrust > 0{
            set max_acc to ship:maxthrust/ship:mass.
        }
        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(nd:deltav:mag/max_acc, 1).
    }
    
    //reducir potencia para ajustar precisión, prioridad 2-4
     //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    if vdot(dv0, nd:deltav) < 0
    {
        lock throttle to 0.
        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        break.
    }

    //we have very little left to burn, less then 0.1m/s
    if nd:deltav:mag < 0.1
    {
        print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        //this usually means we are on point
        wait until vdot(dv0, nd:deltav) < 0.5.

        lock throttle to 0.
        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        set done to True.
    }
    //print "loop timestamp: "+missionTime.
    //stage if neccessary
    set mt to maxThrust.
    if mt < actual or mt = 0{
        PRINT "Staging".
        STAGE.
        wait 1.
    }.
    set actual to mt.
    //apagar motor para terminar nodo, prioridad 4-5
    set done to True.

    //Outputs


}

unlock steering.
unlock throttle.
rcs off.
wait 1.

//we no longer need the maneuver node
remove nd.

//set throttle to 0 just in case.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

//leave SAS on
SAS on.
unlock steering.