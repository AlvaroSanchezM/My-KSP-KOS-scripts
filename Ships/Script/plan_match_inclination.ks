// set margError to 500.//margin of error in meters
// set chngDeltaV to 0.1.//how much the deltav changes in each step

//set myNode to node(0, 0, 0, 0).
//add myNode.

//ship variables vectors
set shpos to ship:position - ship:body:position.
print "shpos: "+shpos.
set shvel to velocity.
print "shvel: "+shvel.

//target variables vectors
set tgpos to target:position - ship:body:position.
print "tgpos: "+tgpos.
set tgvel to target:velocity:orbit.
print "tgvel: "+tgvel.

//get vector normal to the plane of the ship's orbit
set normal2ship to vectorCrossProduct(shpos, shvel).

//get vector normal to the plane of the target's orbit
set normal2target to vectorCrossProduct(tgpos, tgvel).

print "ship's normal vector to orbit ="+normal2ship.
print "target's normal vector to orbit ="+normal2target.

//^^^^^^ no funciona ^^^^^^

// set shipLOAN to orbit:longitudeofascendingnode.
// set shipInc to orbit:inclination.
// set targetLOAN to target:orbit:longitudeofascendingnode.
// set targetInc to target:orbit:inclination.





// until round(mynode:orbit:apoapsis/margError) = round(mynode:orbit:periapsis/margError){
//     if ApoNear{
//         set myNode:prograde to myNode:prograde+chngDeltaV.
//         //set rem to eta:apoapsis.
//     }else{
//         set myNode:prograde to myNode:prograde-chngDeltaV.
//         //set rem to eta:periapsis.
//     }.
// }.



//print myNode.