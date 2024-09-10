set message to "Monitoring".
until periapsis > 71000{//loop para que corra siempre
    set pitch to 90 - vectorangle(ship:up:forevector, ship:facing:forevector). // Da el angulo de profundidad de la nave. Necesario rehacer la operación para actualizar el ángulo
    
    SET northPole TO latlng(90,0).
    LOCK head TO mod(360 - northPole:bearing,360).

    local pointing is ship:facing.
    local trig_x is vdot(pointing:topvector,ship:up:vector).
    if abs(trig_x) < 0.0035 {//this is the dead zone for roll when within 0.2 degrees of vertical
        lock roll to 0.
    } else {
        local vec_y is vcrs(ship:up:vector,ship:facing:forevector).
        local trig_y is vdot(pointing:topvector,vec_y).
        lock roll to arctan2(trig_y,trig_x).
    }

    print "Roll:"+round(roll,0) at (0,16).
    print "P   :"+round(pitch,0) at (0,17).
    print "HEAD:"+round(head,0) at (0,18).
    print "---"+message+"---" at (0,19).
    wait .01.
    clearScreen.
}