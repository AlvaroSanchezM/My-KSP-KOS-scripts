//set margError to 1000.//margin of error in meters
set chngDeltaV to 0.1.//how much the deltav changes in each step

set myNode to node(0, 0, 0, 0).
add myNode.
if ship:orbit:eccentricity < 1{
    if eta:apoapsis < eta:periapsis{
        print "Apo nearer, eta="+round(eta:apoapsis,0).
        set myNode:eta to eta:apoapsis.
        set ApoNear to 1.
    }else{
        print "Per nearer, eta="+round(eta:periapsis,0).
        set myNode:eta to eta:periapsis.
        set ApoNear to 0.
    }.
}else{
    print "Only Per exists, eta="+round(eta:periapsis,0).
    set myNode:eta to eta:periapsis.
    set ApoNear to 0.
}.


until mynode:orbit:eccentricity <= 0.0001{
    if ApoNear{
        set myNode:prograde to myNode:prograde+chngDeltaV.
        //set rem to eta:apoapsis.
    }else{
        set myNode:prograde to myNode:prograde-chngDeltaV.
        //set rem to eta:periapsis.
    }.
}.



print myNode.