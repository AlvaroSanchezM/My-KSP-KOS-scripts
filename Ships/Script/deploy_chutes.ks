function deploy_chutes{
    local partlist to ship:partsdubbedpattern("chute").
    //print "--partlist ="+partlist.
    if partlist:length <> 0{
        //print "---there exists chutes in part list".
        local x to partlist:length-1.
        //loop through the fairing parts
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
        //print "---No fairing in part list".
    }
}

deploy_chutes().