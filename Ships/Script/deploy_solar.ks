local partlist to ship:partsdubbedpattern("solar").
print "--partlist ="+partlist.
if partlist:length <> 0{
    print "---there exists solar in part list".
    local x to partlist:length-1.
    //loop through the solar parts
    until x < 0{
        print "----part"+x+"="+partlist[x].
        local modules to partlist[x]:allmodules.
        local y to modules:length-1.
        //loop through the modules
        until y < 0{
            print "-----module"+y+"="+modules[y].
            if modules[y] = "ModuleDeployableSolarPanel"{
                local events to partlist[x]:getModule("ModuleDeployableSolarPanel"):allevents.
                local z to events:length-1.
                //loop through the events
                until z < 0{
                    print "-----event"+y+"="+events[y].
                    if events[z] = "(callable) deploy solar panel, is KSPEvent"{
                        partlist[x]:getModule("ModuleDeployableSolarPanel"):doevent("deploy solar panel").
                    }
                    local z1 to z-1.
                    local z to z1.
                    if z = -1{break.}
                }
                local y1 to y-1.
                local y to y1.
            }else{local y1 to y-1. local y to y1.}
            if y = -1{break.}
        }
        //print "X pre="+x.
        local x1 to x-1.
        local x to x1.
        //print "X aft="+x.
        if x = -1{break.}
    }
    print "Pannels deployed".
}else{
    print "No pannels to deploy".
}