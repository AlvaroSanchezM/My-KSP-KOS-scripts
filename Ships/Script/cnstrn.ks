//

function main {
    //doLaunch()
    //doAscent()
    //...reach orbit
    rcs off.
    until false{ //Esto permite tenerlo corriendo en el background sin hacer nada planificando nuestra maniobra y pulsar RCS para ejecutar la maniobra
        wait until rcs.
        print maneuverBurnTime(nextnode).
        rcs off.
    }
    print "it ran!!".
}

function executeManeuver {
    parameter utime, radial, normal, prograde.
    local mnv is node(utime, radial, normal, prograde).
    addManeuverToFlightPlan(mnv).
    local startTime is calculateStartTime(mnv).
    wait until time:seconds > startTime - 10.
    lockSteeringAtManeuverTarget(mnv).
    wait until time:seconds > startTime.
    lock throttle to 1.
    wait until isManeuverComplete(mnv).
    lock throttle to 0.
    removeManeuverFromFlightPlan(mnv).
}

function addManeuverToFlightPlan {
    parameter mnv.
    add mnv.
}

function calculateStartTime {
    parameter mnv.
    return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

function maneuverBurnTime {
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

function lockSteeringAtManeuverTarget {
    parameter mnv.
    lock steering to mnv:burnvector.
}

function isManeuverComplete {
    parameter mnv.
    if not(defined originalVector) or originalVector = -1{
        declare global originalVector to mnv:burnvector.
    }
    if vang(originalVector, mnv:burnvector) > 90{
        declare global originalVector to -1.
        return true.
    }
    return false.
}