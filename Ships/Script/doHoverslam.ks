function main {
    sas off.
    lock steering to srfRetrograde.
    lock pct to stoppingDistance() / distanceToGround().
    set warp to 4.
    wait until pct > 0.01.
    set warp to 3.
    wait until pct > 0.04.
    set warp to 2.
    wait until pct > 0.15.
    set warp to 0.
    wait until pct > 0.9.
    lock throttle to pct.
    when distanceToGround() < 500 then { gear on. }
    wait until ship:verticalSpeed > 0.
    lock throttle to 0.
    lock steering to groundSlope().
    wait 30.
    unlock steering.
    sas on.
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