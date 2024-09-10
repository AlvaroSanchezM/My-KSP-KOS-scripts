set actual to 0.

until false{
    set mt to maxThrust.
    when mt < actual or mt = 0 then{
        PRINT "Staging".
        STAGE.
        preserve.
    }.
    set actual to mt.
    wait 1.
}.

// WHEN MAXTHRUST=0 THEN {
//     PRINT "Staging".
//     STAGE.
//     PRESERVE.
// }.

// LIST ENGINES IN elist.
// until false {
//      FOR e IN elist {
//         IF e:FLAMEOUT{
//             STAGE.
//             PRINT "STAGING!" AT (0,0).

//             UNTIL STAGE:READY {
//                 WAIT 0.
//             }

//             LIST ENGINES IN elist.
//             CLEARSCREEN.
//             BREAK.
//         }   
//     }
// }.