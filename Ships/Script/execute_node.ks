function maneuverBurnTime { //OJO, muy exacto pero solo sirve para quemas en la misma etapa, no calcula quemas con 2 o más etapas
    parameter mnv.
    local dV is mnv:deltaV:mag.
    local g0 is 9.80665.
    local m0 is ship:mass.
    local F is ship:maxthrust.

    local isp is 0.

    list engines in myEngines.
    for en in myEngines{
        if en:ignition and not en:flameout{
            set isp to isp + (en:isp * (en:maxThrust / ship:maxthrust)).
        }
    }

    //dV = isp * g0 * ln(m0 / mf)
    //mf = m0 - (fuelFlow*t)
    //F = isp * g0 * fuelFlow

    local mf is m0 / constant:e^(dV / (isp * g0) ).
    local fuelFlow is F / (isp * g0).
    local t is (m0 - mf) / fuelFlow.

    return t.
}

set nd to nextnode.
//turn off SAS
SAS off.

//print out node's basic parameters - ETA and deltaV
print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

//calculate ship's max acceleration
set max_acc to ship:maxthrust/ship:mass.

//OJO, hay un error, si se encuentra en una stage a punto de acabarse en
//medio del burn, es necesario modificar el cálculo de burn_duration:
//Verificar si la deltaV es menor que la que queda en esta fase, si no,
//calcular la max_acc de la siguiente fase y aplicarla a la fórmula
//de calcular burn duration

set burn_duration to maneuverBurnTime(nd).// nd:deltav:mag/max_acc.
print "Estimated burn duration: " + burn_duration + "s".

//initial aproximation to node vector
set np to nd:deltav. //points to node, don't care about the roll direction.
lock steering to np.
set modeBurning to 0.
until modeBurning = 1{
    rcs on.
    print "First wait to align".
    until vang(np, ship:facing:vector) < 1{
        if nd:eta < (burn_duration/2 + 30){
            print "Must begin burn right now".
            set modeBurning to 1.
            break.
        } else{
            wait 0.
        }
    }
    wait 0.
    //The wait has finished, and now we need to start turning our ship in the direction of the burn

    set np to nd:deltav. //points to node, don't care about the roll direction.
    lock steering to np.

    //now we need to wait until the burn vector and ship's facing are aligned
    print "2nd wait to align".
    until vang(np, ship:facing:vector) < 0.25{
        if nd:eta < (burn_duration/2 + 5){
            print "Must begin burn right now".
            set modeBurning to 1.
            break.
        } else{
            wait 0.
        }
    }
    wait 0.

    set nd to nextnode.

    set np to nd:deltav.
    lock steering to np.

    print "2nd warping?".
    if nd:eta >= (burn_duration/2 + 15){
        print "2nd warping doing".
        warpto(time:seconds + nd:eta - (burn_duration/2 + 5)).
    }.
    set np to nd:deltav.
    lock steering to np.

    //the ship is facing the right direction, let's wait for our burn time
    print "wait to begin burning node".
    wait 0.
    wait until nd:eta <= (burn_duration/2).

    set np to nd:deltav.
    lock steering to np.
    
    //Now we are ready to burn. It is usually done in the until loop, checking main parameters of the burn every iteration until the burn is complete

    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    set tset to 0.
    lock throttle to tset.

    set done to False.
    //initial deltav
    set dv0 to nd:deltav.

    set actual to 0.//staging variable
    print "Burning Node".
    rcs off.
    set modeBurning to 1.
}

until done
{
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