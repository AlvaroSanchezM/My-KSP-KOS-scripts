function main{
    sas off.
    local stdir is retrograde.
    local throt is 0.
    lock steering to stdir.
    lock throttle to throt.

    local chuteDeployed is 0.

    if ADDONS:TR:AVAILABLE {
        if ADDONS:TR:HASIMPACT {
            PRINT ADDONS:TR:IMPACTPOS.
            //Has suffixes: ALTITUDEPOSITION, ALTITUDEVELOCITY, BEARING, BODY, DISTANCE, HASSUFFIX, HEADING, INHERITANCE, ISSERIALIZABLE, ISTYPE,
            //              LAT, LNG, POSITION, SUFFIXNAMES, TERRAINHEIGHT, TOSTRING, TYPENAME, VELOCITY
            print "lat="+round(ADDONS:TR:IMPACTPOS:lat,2).
            print "lon="+round(ADDONS:TR:IMPACTPOS:lng,2).
            print "Terrain height="+round(ADDONS:TR:IMPACTPOS:terrainheight,2).
            print "Velocity="+ADDONS:TR:IMPACTPOS:VELOCITY:surface:mag.
        } else {
            PRINT "Impact position is not available".
            //Making new impact position
            set stdir to retrograde.
            
            until periapsis < 0{
                set throt to 1.
            }
            set throt to 0.
            print "lat="+round(ADDONS:TR:IMPACTPOS:lat,2).
            print "lon="+round(ADDONS:TR:IMPACTPOS:lng,2).
            print "Terrain height="+round(ADDONS:TR:IMPACTPOS:terrainheight,2).
            print "Velocity="+ADDONS:TR:IMPACTPOS:VELOCITY:surface:mag.
        }

        set stdir to retrograde.
        local orbSrfSpeed is groundSpeed.

        if not body:atm:exists{
            //Kill srfVelocity
            until groundSpeed < (orbSrfSpeed * 0.1){
                lock steering to srfRetrograde.
                set throt to 1.
            }
            set throt to 0.
            lock steering to stdir.
            print "Horizontal Velocity killed".
            print "Impact Position Data:".
            print "lat="+round(ADDONS:TR:IMPACTPOS:lat,2).
            print "lon="+round(ADDONS:TR:IMPACTPOS:lng,2).
            print "Terrain height="+round(ADDONS:TR:IMPACTPOS:terrainheight,2).
            print "Velocity="+ADDONS:TR:IMPACTPOS:VELOCITY:surface:mag.

            //Run doHoverSlam for vertical velocity and impact terrain height
            run "doHoverSlam.ks".
        } else {
            //Kill srfVelocity
            until groundSpeed < (orbSrfSpeed * 0.7){
                doAutoStageByFuel().
                lock steering to srfRetrograde.
                set throt to 1.
            }
            set throt to 0.
            lock steering to stdir.
            print "Horizontal Velocity killed".
            print "Impact Position Data:".
            print "lat="+round(ADDONS:TR:IMPACTPOS:lat,2).
            print "lon="+round(ADDONS:TR:IMPACTPOS:lng,2).
            print "Terrain height="+round(ADDONS:TR:IMPACTPOS:terrainheight,2).
            print "Velocity="+ADDONS:TR:IMPACTPOS:VELOCITY:surface:mag.
            
            doHoverSlam().
        }

    } else {
        PRINT "Trajectories is not available.".
    }

    unlock steering.
    unlock throttle.
    //leave sas on
    sas on.
}

function doHoverSlam {
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
    until distanceToGround() < 1000 {
        //Deploy parachutes
        if not chuteDeployed and alt:radar < 5000{
            set chuteDeployed to 1.
            if ship:body:atm:exists{
                deploy_chutes2(ship:body).
            }
        }
        doAutoStageByFuel().
    }
    when distanceToGround() < 500 then { gear on. }
    wait until ship:verticalSpeed > 0.
    lock throttle to 0.
    lock steering to groundSlope().
    wait 15.
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

function doSafeStage {
  wait until stage:ready.
  stage.
}

function deploy_chutes{
    local actualBody to ship:body.
    if actualBody:atm:exists {
        //Get only the chutes that are tagged with the same name as the body where they will be deployed
        local chutesForBody is ship:partstaggedpattern(bodyChuteDeploying).
        local partlist to chutesForBody:partsdubbedpattern("chute").
        //print "--partlist ="+partlist.
        if partlist:length <> 0{
            //print "---there exists chutes in part list".
            local x to partlist:length-1.
            //loop through the chute parts
            until x < 0{
                //print "----part"+x+"="+partlist[x].
                local events to partlist[x]:getModule("ModuleParachute"):allevents.
                local y to events:length-1.
                //loop through the events
                until y < 0{
                    //print "-----event"+y+"="+events[y].
                    if events[y] = "(callable) deploy chute, is KSPEvent"{
                        partlist[x]:getModule("ModuleParachute"):doevent("deploy").
                    }
                    set y to y-1.
                    if y = -1{break.}
                }
                //print "X pre="+x.
                set x to x-1.
                //print "X aft="+x.
                if x = -1{break.}
            }
        }else{
            //print "---No chute in part list".
        }
    }
}


main().