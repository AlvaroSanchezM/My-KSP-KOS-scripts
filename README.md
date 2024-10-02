# My-KSP-KOS-scripts
These scripts are the ones I usually run or that I'm developing for everyday use. May update from time to time. Use at your Kerbals' own risk.

Version: KSP 1.9.1.2788

Mods: kOS: Scriptable Autopilot System 1.2.1.0 , kOS-StockCamera 0.2.0.0 , Kerbal Engineer Redux 1.1.9.0 , Module Manager 4.2.3 , Astrogator v0.10.2 , Trajectories v2.4.5.3 , Toolbar Controller 0.1.9.11 , Toolbar 1.8.0.5 , Click Through Blocker 0.1.10.15 , SpaceTux Library 0.0.8.6 , HyperEdit 1.5.8.0 and Kerbal Alarm Clock v3.13.0.0

As of yet this build is not very unstable and runs well, thanks to CKAN.

Credit where it's due, some fragments of the code have been inspired from multiple origins: KOS documentation examples, KSP forums, KSP videos in YouTube, r/KSP, r/kos, ChatGPT 3.5, Jhonny O'Than's Twitch Plays KSP, etc.

Both doHoverslam and goToMun, and cnstrn under a different name, were originally done by the YouTuber CheersKevin.

Notes:
- Launch to orbit development process from oldest to newest: hellolaunch, launch_to_orbit, mylto, mylto-X, mylto2, lto, lto2, lto3, lto4
- There's not much difference in fuel saving between lto2 and lto3. Also, they may crash (the program first but not usually, and then the ship too if you didn't check the staging) for an error when loading the minimum safe height for the current body, but I can't find out why. Also also, they need the scripts: util/body_utils, plan_circularize, execute_node and deploy_fairing to run in any body, and yes, they should be able to get you to orbit from the surface of any body if there's enough deltaV. Also also also,sometimes plan_circularize may freak out when you are in a course to the apoapsis and begin to inflate ludicrously the deltaV you need for the maneuver, because you need less than 10 m/s of deltaV to circularize. To fix it (in-game), shutdown the script and try to run plan_circularize again on your own, either with smaller steps (not recommended because it takes a lot more time to reach to a solution to circularize) or with a bigger margin of error. Then run execute_node to do the burn.
- In lto3 I'm trying to make it so it can launch you at any desired inclination from the ground, that feature is still unfinished.

- Update of lto3 -> lto4.ks uses plan_circ2.ks and x_node.ks, mode changing is more legible, retracts landing gear when alt:radar > 20 meters.

- Update of plan_circularize.ks -> plan_circ2.ks, reduces the precision of the circularization for small orbits, where 0.5 m/s may be too much and may never get the orbit into the margin of error in the eccentricity.

- Execute node  development process from oldest to newest: exe_node, ex_node, execute_node, x_node.
- DO NOT TRUST ANY execute_node script if your current stage has less deltaV than what you need for the maneuver. That's a feature I'm not sure how to include in the script.
- New phase of the node execution program: x_node.ks, able to calculate burn times more accurately. If you don't have enough deltaV in your vessel, it should warn you that you can't do that burn.

- Don't trust doHoverslam to do the surface burn in any place that's not the Mun or Minmus and out of a vertical freefall, ship crash is highly probable otherwise.

- Landing script: land.ks    Needs doHoverSlam.ks

- deploy_chutes scripts: num2 allows you to only use chutes tagged with the name of the body in which they are intended to be used.
