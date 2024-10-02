function plan_circ2{
    local marginErrorEccentr is 0.0001.
    set chngDeltaV to 0.1.//how much the deltav changes in each step

    set myNode to node(0, 0, 0, 0).
    add myNode.
    if ship:orbit:eccentricity < 1{
        if eta:apoapsis < eta:periapsis{
            print "Apo nearer, eta="+round(eta:apoapsis,0).
            set myNode:eta to eta:apoapsis.
            set ApoNear to 1.
            print "apoapsis is "+apoapsis.
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

    if ApoNear{//so that it doesn't overshoot when searching for an adequate node.
        if apoapsis < 80000{
            if apoapsis < 50000{
                set marginErrorEccentr to 0.01.
            }else{
                set marginErrorEccentr to 0.001.
            }
            
        }
    }
    
    print "Margin of error for eccentricity is "+marginErrorEccentr.

    until mynode:orbit:eccentricity <= marginErrorEccentr{
        if ApoNear{
            set myNode:prograde to myNode:prograde+chngDeltaV.
            //set rem to eta:apoapsis.
        }else{
            set myNode:prograde to myNode:prograde-chngDeltaV.
            //set rem to eta:periapsis.
        }.
    }.

    print myNode.
}

plan_circ2().