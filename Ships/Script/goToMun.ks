// Final Launch Script

function main {
  doLaunch().
  doAscent().
  until apoapsis > 100000 {
    doAutoStage().
  }
  doShutdown().
  set mapview to true.
  doCircularization().
  doTransfer().
  set mapview to false.
  doHoverslam().
  wait until false.
}

function doCircularization {
  local circ is list(0).
  set circ to improveConverge(circ, eccentricityScore@).
  wait until altitude > 70000.
  executeManeuver(list(time:seconds + eta:apoapsis, 0, 0, circ[0])).
}

function protectFromPast {
  parameter originalFunction.
  local replacementFunction is {
    parameter data.
    if data[0] < time:seconds + 15 {
      return 2^64.
    } else {
      return originalFunction(data).
    }
  }.
  return replacementFunction@.
}

function doTransfer {
  local startSearchTime is ternarySearch(
    angleToMun@,
    time:seconds + 30, 
    time:seconds + 30 + orbit:period,
    1
  ).
  local transfer is list(startSearchTime, 0, 0, 0).
  set transfer to improveConverge(transfer, protectFromPast(munTransferScore@)).
  executeManeuver(transfer).
  wait 1.
  warpto(time:seconds + obt:nextPatchEta - 5).
  wait until body = Mun.
  wait 1.
}

function angleToMun {
  parameter t.
  return vectorAngle(
    Kerbin:position - positionAt(ship, t),
    Kerbin:position - positionAt(Mun, t)
  ).
}

function munTransferScore {
  parameter data.
  local mnv is node(data[0], data[1], data[2], data[3]).
  addManeuverToFlightPlan(mnv).
  local result is 0.
  if mnv:orbit:hasNextPatch {
    set result to mnv:orbit:nextPatch:periapsis.
  } else {
    set result to distanceToMunAtApoapsis(mnv).
  }
  removeManeuverFromFlightPlan(mnv).
  return result.
}

function distanceToMunAtApoapsis {
  parameter mnv.
  local apoapsisTime is ternarySearch(
    altitudeAt@, 
    time:seconds + mnv:eta, 
    time:seconds + mnv:eta + (mnv:orbit:period / 2),
    1
  ).
  return (positionAt(ship, apoapsisTime) - positionAt(Mun, apoapsisTime)):mag.
}

function altitudeAt {
  parameter t.
  return Kerbin:altitudeOf(positionAt(ship, t)).
}

function ternarySearch {
  parameter f, left, right, absolutePrecision.
  until false {
    if abs(right - left) < absolutePrecision {
      return (left + right) / 2.
    }
    local leftThird is left + (right - left) / 3.
    local rightThird is right - (right - left) / 3.
    if f(leftThird) < f(rightThird) {
      set left to leftThird.
    } else {
      set right to rightThird.
    }
  }
}

function eccentricityScore {
  parameter data.
  local mnv is node(time:seconds + eta:apoapsis, 0, 0, data[0]).
  addManeuverToFlightPlan(mnv).
  local result is mnv:orbit:eccentricity.
  removeManeuverFromFlightPlan(mnv).
  return result.
}

function improveConverge {
  parameter data, scoreFunction.
  for stepSize in list(100, 10, 1) {
    until false {
      local oldScore is scoreFunction(data).
      set data to improve(data, stepSize, scoreFunction).
      if oldScore <= scoreFunction(data) {
        break.
      }
    }
  }
  return data.
}

function improve {
  parameter data, stepSize, scoreFunction.
  local scoreToBeat is scoreFunction(data).
  local bestCandidate is data.
  local candidates is list().
  local index is 0.
  until index >= data:length {
    local incCandidate is data:copy().
    local decCandidate is data:copy().
    set incCandidate[index] to incCandidate[index] + stepSize.
    set decCandidate[index] to decCandidate[index] - stepSize.
    candidates:add(incCandidate).
    candidates:add(decCandidate).
    set index to index + 1.
  }
  for candidate in candidates {
    local candidateScore is scoreFunction(candidate).
    if candidateScore < scoreToBeat {
      set scoreToBeat to candidateScore.
      set bestCandidate to candidate.
    }
  }
  return bestCandidate.
}

function executeManeuver {
  parameter mList.
  local mnv is node(mList[0], mList[1], mList[2], mList[3]).
  addManeuverToFlightPlan(mnv).
  local startTime is calculateStartTime(mnv).
  warpto(startTime - 15).
  wait until time:seconds > startTime - 10.
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  until isManeuverComplete(mnv) {
    doAutoStage().
  }
  lock throttle to 0.
  unlock steering.
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
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:availableThrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow.

  return t.
}

function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

function removeManeuverFromFlightPlan {
  parameter mnv.
  remove mnv.
}

function doLaunch {
  lock throttle to 1.
  doSafeStage().
}

function doAscent {
  lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
  set targetDirection to 90.
  lock steering to heading(targetDirection, targetPitch).
}

// Bad function if you change throttle limit mid flight
function doAutoStage {
  if not(defined oldThrust) {
    global oldThrust is ship:availablethrust.
  }
  if ship:availablethrust < (oldThrust - 10) {
    until false {
      doSafeStage(). wait 1.
      if ship:availableThrust > 0 { 
        break.
      }
    }
    global oldThrust is ship:availablethrust.
  }
}

function doAutoStageByFuel {
    local tanks is ship:partsTagged("FuelTank").
    for tank in tanks{
        if tank:resources[0]:amount() = 0{
            //Si algún tanque llega a 0 fuel, STAGE!
            PRINT "Staging".
            doSafeStage().
            wait 1.
        }
    }
}

function doShutdown {
  lock throttle to 0.
  lock steering to prograde.
}

function doSafeStage {
  wait until stage:ready.
  stage.
}

function doHoverslam {
  lock steering to srfRetrograde.
  lock pct to stoppingDistance() / distanceToGround().
  set warp to 4.
  wait until pct > 0.1.
  set warp to 3.
  wait until pct > 0.4.
  set warp to 0.
  wait until pct > 1.
  lock throttle to pct.
  until distanceToGround() < 1000 {
    doAutoStageByFuel().
  }
  when distanceToGround() < 500 then { gear on. }
  wait until ship:verticalSpeed > 0.
  lock throttle to 0.
  lock steering to groundSlope().
  wait 30.
  unlock steering.
}

function distanceToGround {
  return altitude - body:geopositionOf(ship:position):terrainHeight - 4.7.
}

function stoppingDistance {
  local grav is constant():g * (body:mass / body:radius^2).
  local maxDeceleration is (ship:availableThrust / ship:mass) - grav.
  return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

function groundSlope {
  local east is vectorCrossProduct(north:vector, up:vector).

  local center is ship:position.

  local a is body:geopositionOf(center + 5 * north:vector).
  local b is body:geopositionOf(center - 3 * north:vector + 4 * east).
  local c is body:geopositionOf(center - 3 * north:vector - 4 * east).

  local a_vec is a:altitudePosition(a:terrainHeight).
  local b_vec is b:altitudePosition(b:terrainHeight).
  local c_vec is c:altitudePosition(c:terrainHeight).

  return vectorCrossProduct(c_vec - a_vec, b_vec - a_vec):normalized.
}

main().