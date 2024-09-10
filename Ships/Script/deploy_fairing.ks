local partlist to ship:partsdubbedpattern("fairing").
//print "--partlist ="+partlist.
if partlist:length <> 0{
    //print "---there exists fairing in part list".
    local x to partlist:length-1.
    //loop through the fairing parts
    until x < 0{
        //print "----part"+x+"="+partlist[x].
        local events to partlist[x]:getModule("ModuleProceduralFairing"):allevents.
        local y to events:length-1.
        //loop through the events
        until y < 0{
            //print "-----event"+y+"="+events[y].
            if events[y] = "(callable) deploy, is KSPEvent"{
                partlist[x]:getModule("ModuleProceduralFairing"):doevent("deploy").
            }
            local y to y-1.
            if y = -1{break.}
        }
        //print "X pre="+x.
        local x to x-1.
        //print "X aft="+x.
        if x = -1{break.}
    }
}else{
    //print "---No fairing in part list".
}