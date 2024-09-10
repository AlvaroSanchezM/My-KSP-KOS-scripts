// Script para alunizaje en Mun con mínimo combustible y bajo riesgo de estrellarse

//stops sas
sas off.

// Configuración inicial
set targetAltitude to 10000. // Altitud objetivo para el periapsis (10 km)
set landingAltitude to 0. // Altitud para aterrizar
set safeSpeed to 4. // Velocidad segura para el contacto con la superficie en m/s
set MaxGs to 10.
set maxDeceleration to MaxGs*10. // Máxima desaceleración en m/s²

// Circularizar la órbita a una altitud baja
print "Ajustando periapsis a " + targetAltitude + " metros...".
lock steering to retrograde.
until periapsis <= targetAltitude {
    lock throttle to 1.
    wait 0.1.
}
lock throttle to 0.
print "Periapsis ajustado a " + periapsis + " metros.".
lock steering to prograde.
wait 2.
// Esperar hasta el periapsis para iniciar el descenso

if eta:periapsis > 120{
    print "Warping...".
    warpto(time:seconds + eta:periapsis - 120).//Warp a 2 min del perigeo
    wait 1.
}
lock steering to retrograde.
print "Steering towards retrograde...".
wait until altitude < targetAltitude.
print "Iniciando descenso...".
set mode to 0.
set spAdj to 0.

//Función de cálculo de altura
function get_altitude_above_terrain {
    // Obtener la altitud del radar, que es la altitud sobre el terreno
    local radar_altitude is ship:altitude - ship:geoposition:terrainheight.

    // Si la altitud del radar es negativa (debajo del terreno), ajustarla a cero
    if radar_altitude < 0 {
        set radar_altitude to 0.
    }

    return radar_altitude.
}
set message to "Descendiendo".
set deltaTr to "0".
// Desbloquear el acelerador para el descenso
lock throttle to 1.
set steer to 0.
until get_altitude_above_terrain() < 10{
    set throt to throttle.
    local radarAlt is get_altitude_above_terrain().
    if radarAlt > 1000 {
        //Steer control
        if steer = 1 or (vang(srfRetrograde:vector, up:vector) < 0.25 and velocity:surface:mag < 50){
            lock steering to up.
            set steer to 1.
        }else{
            lock steering to srfRetrograde.
        }
        // Monitoriza la velocidad y desacelera gradualmente
        if velocity:surface:mag > 50 {
            //set t0 to time:seconds.
            lock throttle to 0.8.
        }
        else{
            lock throttle to 0.
        }
    }
    else{//a menos de 1000 mts de altura
        //Steering control
        if steer = 1 or (vang(srfRetrograde:vector, up:vector) < 0.25 and velocity:surface:mag < 50){
            lock steering to up.
            set steer to 1.
        }else{
            lock steering to srfRetrograde.
        }
        //Throttle control
        if mode = 0{
            print "Fase final del descenso...".
            set mode to 1.
            gear on.
            lock throttle to 0.3.
            unlock throttle.
        }
        if mode = 1 and radarAlt > 250{
            // Desacelerar para el aterrizaje
            if velocity:surface:mag > safeSpeed*4 and verticalspeed < -safeSpeed*4 {
                if throt < 0.4{
                    lock throttle to throt + 0.1.
                }
                set deltaTr to "+".
            } else {
                lock throttle to throt - 0.2.
                set deltaTr to "-".
            }
        }
        if mode = 2 or (radarAlt < 250 and radarAlt > 50){// Desaceleración final
            if mode = 1{
                set message to "Descenso controlado, ajustando para el aterrizaje...".
                set mode to 2.
                lock throttle to 0.2.
            }
            if velocity:surface:mag > safeSpeed*3{
                if throt < 0.3{
                    lock throttle to throt + 0.05.
                }
                set deltaTr to "+".
            } else {
                lock throttle to throt - 0.1.
                set deltaTr to "-".
            }
        }
        
        if radarAlt < 50 and radarAlt > 15 or mode = 3 {// Ajuste fino para el contacto suave
            if mode = 2 or mode = 3{
                set mode to 3.
                set message to "Ajuste final...".
                if verticalspeed > safeSpeed*2 {
                    if throt < 0.3{
                        lock throttle to throt + 0.05.
                    }
                    set deltaTr to "+".
                } else {
                    lock throttle to throt - 0.1.
                    set deltaTr to "-".
                }
            }
        }
    }
    //Staging script
    local tanks is ship:partsTagged("FuelTank").
    for tank in tanks{
        if tank:resources[0]:amount() = 0{//Si algún tanque llega a 0 fuel, STAGE!
            PRINT "Staging".
            STAGE.
            wait 0.4.
        }
    }
    //OUTPUT
    PRINT "Alt  :"+ROUND(radarAlt,0) AT (0,14).
    //PRINT "Per:"+ROUND(SHIP:PERIAPSIS,0) AT (0,15).
    //PRINT "Apo:"+ROUND(SHIP:APOAPSIS,0) AT (0,16).
    //PRINT "DeltaV:"+ROUND(SHIP:DELTAV,0) AT (0,18).
    print "---"+message+"---" at (0,19).
    print "throttle-Delta = "+deltaTr at (0,20).
    print "mode = "+mode at (0,21).
    print "steer = "+steer at (0,22).
    wait .005.
    clearScreen.
}

lock steering to up.
print "Aterrizaje completado!".

// Apagar motores
lock throttle to 0.
wait 2.
print "Alunizaje exitoso en Mun!".

unlock steering.
unlock throttle.
//leave sas on
sas on.