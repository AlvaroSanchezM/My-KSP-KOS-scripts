@lazyglobal off.

run once "0:/tpksp/util/logging".
run once "0:/tpksp/util/util".

// possiblethrust / possiblethrustat will work for engines that are not yet active, also takes thrust limiter into account
// ispat works for inactive engines, but isp does not
// part:stage seems to be the stage that the engine/decoupler will activate in, or the stage that the part will be decoupled in
// engine:consumedresources:values[0]:maxmassflow can indicate massflow for inactive engines

// returns a list of stageinfo
// each stageinfo is a lexicon containing the following keys:
//   tanks: a list of parts that contain fuel
//   engines: a list of the engine parts that will be active in this stage
//   resources: a list of resources in this stage
//   resourceslex: a lexicon of resources in this stage
//   mass: the stage's current mass
//   totalmass: the mass of the entire rocket including this stage (but not later stages)
//   fuelmass: the mass of the fuel in this stage
//   thrust: the thrust of the engines in this stage
//   isp: the isp at the current pressure 
//   dv: available dv at current pressure
//   burntime: available burntime at max throttle


function get_vessel_stage_info {
    parameter result is list().
    result:clear().

    for i in range(stage:number+1) result:add(lexicon(
        "parts", list(),
        "tanks", list(),
        "engines", list(),
        "resources", list(),
        "resourceslex", lexicon(),
        "mass", 0,
        "totalmass", 0,
        "fuelmass", 0,
        "thrust", 0,
        "isp", 0,
        "dv", 0,
        "burntime", 0
    )).

    // NOTE: this only really works correctly for asparagus setups or ships with a 1:1 stage:engine mapping
    // it assumes the fuel tanks for each stage will be full when that stage activates
    // which will not be true in e.g. a sustainer engine + SRB setup
    // need to attribute some fuel mass from later stages down into earlier ones

    local engines is list().
    list engines in engines.

    local any_active_engines is false.
    for engine in engines if engine:ignition { set any_active_engines to true. break. }

    for engine in engines {
        // if any engines are active, only consider this engine if it is active.  This prevents considering inactive engines in the current stage
        if not any_active_engines or engine:ignition or engine:stage <> stage:number {
            // add the engine properties to all the stages from where it activates to where it decouples
            // if it's already active then put it in the current stage instead of the stage where it would normally activate
            local last_stage_index is (choose stage:number if engine:ignition else engine:stage).
            for stage_index in range(get_part_stage(engine), last_stage_index+1) {
                local stage_info is result[stage_index].
                stage_info:engines:add(engine).
                set stage_info:thrust to stage_info:thrust + engine:possiblethrust.
            }
        }
    }

    for part in ship:parts {
        local stage_info is result[get_part_stage(part)].
        add_part_to_stage_info(part, stage_info).
    }

    finalize_vessel_stage_info(result).

    return result.
}

local function add_part_to_stage_info {
    //Añade la parte "PART" a la info de la fase "StageInfo".
    //Si contiene recursos, calcula su densidad, y si no es 0, es un tanque y añade este recurso a la masa de combustible de la fase.
    //SE USARÁ PARA CALCULAR MASA INICIAL Y FINAL en cada fase
    //Peligroso si se consumen distintos tipos de combustible
    parameter part.
    parameter stage_info.

    stage_info:parts:add(part).

    set stage_info:mass to stage_info:mass + part:mass.

    local part_is_tank is false.

    for resource in part:resources {
        if (resource:enabled) {
            // TODO: consider if the engines actually burn this fuel, and which resource is the limiting factor
            // the engine's consumedresources is buggy because it uses displayname
            set stage_info:fuelmass to stage_info:fuelmass + resource:amount * resource:density.

            if resource:density > 0 {
                set part_is_tank to true.
            }
        }
    }

    if (part_is_tank) {
        stage_info:tanks:add(part).
    }
}

local function finalize_vessel_stage_info {
    parameter vessel_stage_info.

    for stage_index in range(vessel_stage_info:length) {
        local stage_info is vessel_stage_info[stage_index].

        set stage_info:totalmass to stage_info:mass + (choose 0 if stage_index = 0 else vessel_stage_info[stage_index-1]:totalmass).
        set stage_info:isp to get_combined_isp(stage_info:engines).
        // NOTE: this is only correct if the engines are associated with a single stage
        if (stage_info:fuelmass > 0 and stage_info:engines:length) {
            local drymass is stage_info:totalmass - stage_info:fuelmass.
            set stage_info:dv to stage_info:isp * constant:g0 * ln(stage_info:totalmass / drymass).
            local mass_flow_rate is get_mass_flow_rate(stage_info:engines).
            set stage_info:burntime to choose 0 if mass_flow_rate = 0 else stage_info:fuelmass / mass_flow_rate.
        }
    }
}

local function get_part_stage { //Sirve para detectar a qué "STAGE" pertenece cada parte/pieza, ES UTIL PARA DETECTAR EN QUÉ FASE NOS DESHAREMOS DE SU PESO y para calcular el peso final y la dv que aporta al cohete
    parameter part.
    local result is 0.
    // NOTE: this ignores directionality of the decoupler and assumes it does not stay with the ship
    if (part:istype("launchclamp") or part:istype("decoupler")) and not part:istype("dockingport"){
        set result to part:stage+1.
    } else {
        set result to part:decoupledin+1.
    }

    // if result < 0 or result > stage:number print part:title + " " + part:stage + " " + part:decoupledin.

    return min(result, stage:number).
}

local function get_total_ship_dv {
    parameter vessel_stage_info.

    local result is 0.

    for stage_info in vessel_stage_info
        set result to result + stage_info:dv.

    return result.
}

// for stage_info in vessel_stage_info{
//     print "stage_info is "+stage_info:engines[0]:maxpossiblethrust.
// }//:suffixnames.}
        //--++Outputs a list of info (burntime, dv, engines, fuelmass, isp, mass, parts, resources, resourceslex, tanks, thrust, totalmass) per stage++--
//local totshipdv is get_total_ship_dv(vessel_stage_info).
//print "+++total ship deltav is "+totshipdv+"+++".

// Para hacer el cálculo de tiempo de maniobra en varias etapas, calculamos el tiempo de quemado en cada etapa para con sus propios datos.
// Etapa actual con toda su deltaV, si es suficiente para la quema, calcular el tiempo y pasar a la quema, si no:
//  -ver si basta con la deltaV de la siguiente etapa, si no, ver si basta con la siguiente... ,
//  y luego, o si sí basta, calcular cuanto tiempo hace falta para la quema de los x metros por segundo de esta etapa, y añadirlo a la pila de tiempo de la quema

function maneuverBurnTime {
    parameter mnv.
    parameter vessel_stage_info.
    local burntime is 0.
    local dv is mnv:deltav:mag.
    local remaining_dv is dv.
    local g0 is 9.80665. 
    //Lista de stage info pero desde el final hacia el inicio
    for i in range(vessel_stage_info:length){
        local stage_info is vessel_stage_info[vessel_stage_info:length - i - 1].
        print "stage_info is "+ stage_info:engines.
        if stage_info:dv > remaining_dv{
            //calculate remaining ship mass
                local m0 is ship:mass.
            //calculate this stage's maxthrust in the event it has more than 1 engine.
                local F is stage_info:engines[0]:maxpossiblethrust.
                
            //calculate this ship's isp
            local isp is 0.

            for en in stage_info:engines{
                if en:ignition and not en:flameout{
                    set isp to isp + (en:isp * (en:maxThrust / ship:maxthrust)).
                }
            }

            //calculate this stage's fuel flow in the event it has more than 1 engine.
                local fuelFlow is F / (isp * g0).
            
            local mf is m0 / constant:e^(dV / (isp * g0) ).
            local t is (m0 - mf) / fuelFlow.
            set remaining_dv to 0.
            set burntime to burntime + t.
            break.
        }else{
            set remaining_dv to remaining_dv - stage_info:dv.
            set burntime to burntime + stage_info:burntime.
        }
    }
    return burntime.
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


local vessel_stage_info is get_vessel_stage_info().

local nd to nextnode.

if nd:deltav:mag < get_total_ship_dv(){

    //turn off SAS
    SAS off.

    //print out node's basic parameters - ETA and deltaV
    print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

    //calculate ship's max acceleration
    local max_acc to ship:maxthrust/ship:mass.

    //OJO, hay un error, si se encuentra en una stage a punto de acabarse en
    //medio del burn, es necesario modificar el cálculo de burn_duration:
    //Verificar si la deltaV es menor que la que queda en esta fase, si no,
    //calcular la max_acc de la siguiente fase y aplicarla a la fórmula
    //de calcular burn duration

    local burn_duration to maneuverBurnTime(nd, vessel_stage_info).// nd:deltav:mag/max_acc.
    print "Estimated burn duration: " + burn_duration + "s".

    //initial aproximation to node vector
    local np to nd:deltav. //points to node, don't care about the roll direction.
    lock steering to np.
    local modeBurning to 0.

    local tset to 0.
    local done to False.
    local dv0 to nd:deltav.

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
        doAutoStageByFuel().
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
} else{
    print "ERROR: UNABLE TO BURN NODE, NOT ENOUGH DELTAV IN THIS VESSEL!".
}