function deploy_chutes2{
    parameter bodyChuteDeploying.
    local actualBody to ship:body.
    if (bodyChuteDeploying = "default" or bodyChuteDeploying = "") and actualBody:atm:exists { // This deploys all parachutes available
        local partlist to ship:partsdubbedpattern("chute").
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
    } else {
        if bodyChuteDeploying = actualBody and actualBody:atm:exists {
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
}

deploy_chutes2("default").
//Modes:"default" or "" deploys all available parachutes
//      NameOfBody      deploys only the parachutes tagged for that body.
//  Available bodies in stockKSP are: "Eve", "Kerbin", "Duna", "Jool" and "Laythe"
//  However, as long as the parts are tagged with the name of the body and as long as the body has atmosphere, it will deploy them.
//  This script only deploys the parachutes, you could get the same result if you staged them adequately.