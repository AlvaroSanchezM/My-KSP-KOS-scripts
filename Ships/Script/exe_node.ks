set nd to nextnode.
//turn off SAS
SAS off.

print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).
print "Node date-time:" + (nd:eta+missionTime).
//calculate ship's max acceleration
set max_acc to ship:maxthrust/ship:mass.

// Now we just need to divide deltav:mag by our ship's max acceleration
// to get the estimated time of the burn.
//
// Please note, this is not exactly correct.  The real calculation
// needs to take into account the fact that the mass will decrease
// as you lose fuel during the burn.

set burn_duration to nd:deltav:mag/max_acc.
print "Crude Estimated burn duration: " + round(burn_duration) + "s".
set beginNodeBurn to missionTime + nd:eta - burn_duration/2.
print "Node burn begins at date-time:" + (beginNodeBurn).

//initial aproximation to node vector
set np to nd:deltav. //points to node, don't care about the roll direction.
lock steering to np.
set modeBurning to 0.
if beginNodeBurn-.2 = missionTime{
    set modeBurning to 1.
}

until modeBurning = 1{
    rcs on.
    print "First wait to align".
    !wait until vang(np, ship:facing:vector) < 1.//{
    //     if nd:eta >= (burn_duration/2 + 5){
    //         print "Must begin burn right now".
    //         set modeBurning to 1.
    //         break.
    //     }.
    // }
    wait 0.
    //Let’s give us some time, 60 seconds, to prepare for the maneuver burn
    //print "warping".
    //warpto(time:seconds + nd:eta - (burn_duration/2 + 60)).
    //wait until nd:eta <= (burn_duration/2 + 60).


    //Exercise: automation of warping for a given period of time


    //The wait has finished, and now we need to start turning our ship in the direction of the burn

    set np to nd:deltav. //points to node, don't care about the roll direction.

    lock steering to np.

    //now we need to wait until the burn vector and ship's facing are aligned
    print "2nd wait to align".
    !wait until vang(np, ship:facing:vector) < 0.25.//{
    //     if nd:eta >= (burn_duration/2 + 5){
    //         print "Must begin burn right now".
    //         set modeBurning to 1.
    //         break.
    //     }.
    // }
    wait 0.
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
    !wait until nd:eta <= (burn_duration/2).

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
        !wait until vdot(dv0, nd:deltav) < 0.5.

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