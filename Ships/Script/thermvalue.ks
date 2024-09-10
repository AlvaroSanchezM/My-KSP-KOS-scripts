parameter ves.
list sensors in senselist.
local thermo_selected is false.
for s in senselist{
    if s:type = "temperature" and not thermo_selected{
        if s:active{
            set thermo_selected to true.
            set thermo_returned to s.
        }
        
    }
}