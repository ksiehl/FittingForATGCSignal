#! /bin/bash

pwd
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc481
eval `scramv1 project CMSSW CMSSW_7_1_5`
cp libHiggsAnalysisCombinedLimit.so CMSSW_7_1_5/lib/slc6_amd64_gcc481/
cd CMSSW_7_1_5/src/
eval `scramv1 runtime -sh`
echo "CMSSW: "$CMSSW_BASE
cd -

#echo "computing observed 1-D limits.\n"
#1-D Limits--observed
#----------

#./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cwww -P cwww --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6 --minimizerStrategy=2 --cminPreScan -n _obs-cwww_3.6

#./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs ccw -P ccw --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _obs-ccw_4.5

#./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cb -P cb --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _obs-cb_20

#echo "computing observed 2-D limits.\n"

#2-D Limits--observed
#----------

#./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cwww,ccw -P cwww -P ccw --freezeNuisances cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _obs-cwww_3.6_ccw_4.5

#./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cwww,cb -P cwww -P cb --freezeNuisances ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _obs-cwww_3.6_cb_20

#./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs ccw,cb -P ccw -P cb --freezeNuisances cwww --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _obs-ccw_4.5_cb_20

################################################################

echo "computing expected 1-D limits.\n"

#1-D Limits--expected
#----------

./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cwww -P cwww --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6 --minimizerStrategy=2 --cminPreScan -n _exp-cwww_3.6

./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs ccw -P ccw --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _exp-ccw_4.5

./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cb -P cb --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _exp-cb_20

echo "computing expected 2-D limits.\n"

#2-D Limits--expected
#----------

./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cwww,ccw -P cwww -P ccw --freezeNuisances cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _exp-cwww_3.6_ccw_4.5

./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cwww,cb -P cwww -P cb --freezeNuisances ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _exp-cwww_3.6_cb_20

./combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs ccw,cb -P ccw -P cb --freezeNuisances cwww --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _exp-ccw_4.5_cb_20
