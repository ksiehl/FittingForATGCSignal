SIGNAL PARAMETRIZATION
======================

```
NOTE: This is only garanteed to work on slc6 architecture.

This script creates the complete signal model and creates a datacard and a workspace per channel containing everything needed for the limit extraction.

Setup Instructions
==================
# Make sure you have the right architecture
export SCRAM_ARCH=slc6_amd64_gcc481

# Setup CMSSW
cmsrel CMSSW_7_1_5
cd CMSSW_7_1_5/src
cmsenv

# Clone the repository
git clone git@github.com:ksiehl/FittingForATGCSignal.git

# Clone the Higgs combined limit tool repo; Look at the repo for further details
git clone git@github.com:ksiehl/HiggsAnalysis.git

# Clone the CombinedEWKAnalysis repo; Look at the repo for further details
git clone git@github.com:ksiehl/CombinedEWKAnalysis.git

# Build
scram b -j 20

# Make a folder Input in and FittingForSignal and copy the required files e.g.
cd FittingForATGCSignal; mkdir Input;
cp ../../../../ntuple_output_storage/{WW,WZ}-aTGC_{mu,ele}.root ./Input
mv ./Input/WW-aTGC_ele.root ./Input/WW-aTGC_el.root
mv ./Input/WZ-aTGC_ele.root ./Input/WZ-aTGC_el.root

#####start here when redoing angles#######################
mv ResultsObserved/ ResultsExpected/ *.root *.log *.txt *.pdf *.eps backup-dir/

cp ../../../../BCKGRND_STEP/CMSSW_5_3_32/src/FittingForATGCBackground/cards_mu_HPV_900_4500/wwlvj_mu_HPV_900_4500_workspace.root ./Input/wwlvj_mu_HPV_workspace.root
cp ../../../../BCKGRND_STEP/CMSSW_5_3_32/src/FittingForATGCBackground/cards_el_HPV_900_4500/wwlvj_el_HPV_900_4500_workspace.root ./Input/wwlvj_el_HPV_workspace.root

# Run the main script; this must be done with channel "elmu"; if channel 'el' or 'mu' are selected it will complain about not seeing the cards for the other channel
# Another thing is that this script will produce a segmentation fault error message, but this appears to come only after everything has run, so (pray) it's harmless.
# This creates the signal fitting functions for anomalous parameters (and SM?) and puts them into workspaces; it also produces cards with uncertianties and channels;
# all of this is finalized in the next step (both for LEP and EFT parameters), which immediatelly precedes the actual limits on anomalous parameters
python make_PDF_input_oneCat_angles.py -n -c elmu -p --savep --starangle CUTVALUE
# -n: Read the input trees and create RooDataHists(-> faster access); Needed at the first run or when the input trees are changed.
# -c {channel}: Only run for {channel} (mu or el)
# -p: Make plots
# --savep: Save the plots
# -b: Run in batch mode
# --noatgcint: Set aTGC-interference terms to zero
# --printatgc: Print the coefficients of the signal model
# --atgc: Using different parametrization (Lagrangian approach instead of EFT)
# --binWidth: Use a different bin width than the standard, useful for Asimov data generation
# --cutoff: Specify mWV upper limit in GeV

# The workspaces for the different channels can now be combined with
text2workspace.py aC_WWWZ_simfit.txt -o workspace_simfit.root -P CombinedEWKAnalysis.CommonTools.ACModel:par1par2par3_TF3_shape_Model --PO channels=WWWZ_sig_el,WWWZ_sig_mu,WWWZ_sb_lo_el,WWWZ_sb_lo_mu,WWWZ_sb_hi_el,WWWZ_sb_hi_mu --PO poi=cwww,ccw,cb --PO range_cwww=-20,20 --PO range_ccw=-30,30 --PO range_cb=-75,75
# -o: Name of the created workspace
# -P: Name of the used model
# --PO channels= Names of the channels
# --PO poi= Names of the paramters of interest
# --PO range_= Set paramter range (does't work atm but has to be added to avoid error message)
# For vertex parametrization
text2workspace.py aC_WWWZ_simfit.txt -o workspace_simfitLEP.root -P CombinedEWKAnalysis.CommonTools.ACModel:par1par2par3_TF3_shape_Model --PO channels=WWWZ_sig_el,WWWZ_sig_mu,WWWZ_sb_lo_el,WWWZ_sb_lo_mu,WWWZ_sb_hi_el,WWWZ_sb_hi_mu --PO poi=lZ,dg1z,dkz --PO range_lZ=-0.1,0.1 --PO range_dg1z=-0.1,0.1 --PO range_dkz=-0.1,0.1

# This creates the final workspace called workspace_simfit.root. To inspect this workspace in ROOT you have to load the combined limit .so 
root -b
.L ../../lib/slc6_amd64_gcc481/libHiggsAnalysisCombinedLimit.so.
.q

Limit Calculation
=================
# We use the Higgs combine tool for doing the final data fits and calculating limits on aTGC parameters. Some of the arguments used by the combine tool are:
# -M: Likelihood method, we use MultiDimFit or MaxLikelihoodFit
# -t -1 or --expectSignal=1: -t -1 for Asimov data set generation
# --saveToys: The Asimov data set is saved in the toys directory as RooDataSet
# -n: This is added to the output name
# --points: The number of scanned parameter values
# --redefineSignalPOIs cwww -P cwww: Defines the paramter(s) of interest
# --freezeNuisances ccw,cb: Fixes the other paramters
# --setPhysicsModelParameters cwww=0,ccw=0,cb=0: Sets the initial parameter values
# --setPhysicsModelParameterRange cwww=-3.6,3.6: Sets the parameter range to be scanned
# --cminPreScan so that combine locates the correct global minimum

Fits for Single Point
---------------------
# To get the exact fit results for any point (e.g. cwww=3.6) we need to run
combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=3.6,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs cwww --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n _cwww_3.6 | tee cwww-mll.log

combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=4.5,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs ccw --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n _ccw_4.5 | tee ccw-mll.log

combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=20 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs cb --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n _cb_20 | tee cb-mll.log

# The output is saved in mlfit_cwww_3.6.root containing a RooFitResult fit_s with all final parameter values as well as a RooArgSet norm_fit_s with the final normalizations.

# To get the results for all parameters zero
combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs cwww --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n AllZero_cwww | tee cwww-0-mll.log

combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs ccw --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n AllZero_ccw | tee ccw-0-mll.log

combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs cb --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n AllZero_cb | tee cb-0-mll.log

# We can also freeze all aTGC parameters and set a different POI
combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances cwww,ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs normvar_WJets_el --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n BkgOnly_el | tee bkgnd-el-mll.log

combine workspace_simfit.root -M MaxLikelihoodFit --expectSignal=1 --freezeNuisances cwww,ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs normvar_WJets_mu --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n BkgOnly_mu | tee bkgnd-mu-mll.log

Asimov Data Set Generation
--------------------------
combine workspace_simfit.root -M MaxLikelihoodFit -t -1 --saveToys --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs cwww --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n Asimov_cwww | tee cwww-asmv.log

combine workspace_simfit.root -M MaxLikelihoodFit -t -1 --saveToys --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs ccw --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n Asimov_ccw | tee ccw-asmv.log

combine workspace_simfit.root -M MaxLikelihoodFit -t -1 --saveToys --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --minimizerStrategy 2 --cminPreScan --redefineSignalPOIs cb --saveNormalizations --saveWithUncertainties --skipBOnlyFit -n Asimov_cb | tee cb-asmv.log

# Add --toysFrequentist to generate Asimov data after getting optimal nuisance parameters values from a fit to data. Useful to get projected signal values.

# Before the next step, we need to compile; path can be confirmed with scram tool info roofitcore | grep INCLUDE
cd PDFs/
root -b
gSystem->AddIncludePath("-I/cvmfs/cms.cern.ch/slc6_amd64_gcc481/lcg/roofit/5.34.18-cms3/include");
.L PdfDiagonalizer.cc+
.L Util.cxx+
.L hyperg_2F1.c+
.L HWWLVJRooPdfs.cxx+
.q
cd ..

Postfit Plots
-------------
# first batch of plots; it appears the -P option has no effect on anything??? creates .eps files, uses mlfit, and depending on options, asimov?

python check_combine_result_all.py -n BkgOnly_mu -c mu -P cwww:3.6
python check_combine_result_all.py -n BkgOnly_el -c el -P cwww:3.6

python check_combine_result_all.py -n AllZero_cb -c mu -P cb:0.0
python check_combine_result_all.py -n AllZero_cb -c el -P cb:0.0

python check_combine_result_all.py -n AllZero_ccw -c mu -P ccw:0.0
python check_combine_result_all.py -n AllZero_ccw -c el -P ccw:0.0

python check_combine_result_all.py -n AllZero_cwww -c mu -P cwww:0.0
python check_combine_result_all.py -n AllZero_cwww -c el -P cwww:0.0

python check_combine_result_all.py -n _cb_20 -c mu -P cb:20.0
python check_combine_result_all.py -n _cb_20 -c el -P cb:20.0

python check_combine_result_all.py -n _ccw_4.5 -c mu -P ccw:4.5
python check_combine_result_all.py -n _ccw_4.5 -c el -P ccw:4.5

python check_combine_result_all.py -n _cwww_3.6 -c mu -P cwww:3.6
python check_combine_result_all.py -n _cwww_3.6 -c el -P cwww:3.6


# -n: Addendum to the file name which contains the fit results
# -P: Set parameter value (default is -P cwww:0)
# -a: If we want to plot the Asimov data -a is the full file name which was saved from --saveToys (e.g. higgsCombineAsimov.MaxLikelihoodFit.mH120.123456.root)
# -r: Region

# For the new split plots, use the following for example
python check_combine_result_mJ.py -n AllZero -c el -P cwww:0 -r sig
python check_combine_result_mWV.py -n AllZero -c el -P cwww:0 -r sig

#################################################################################################

1-D Limits--expected
----------
combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cwww -P cwww --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6 --minimizerStrategy=2 --cminPreScan -n _exp-cwww_3.6

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs ccw -P ccw --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _exp-ccw_4.5

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cb -P cb --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _exp-cb_20

# For vertex parametrization
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs lZ -P lZ --freezeNuisances dg1z,dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange lZ=-0.014,0.014 --minimizerStrategy=2 --cminPreScan -n _exp-lZ_0.014
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs dg1z -P dg1z --freezeNuisances lZ,dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange dg1z=-0.018,0.018 --minimizerStrategy=2 --cminPreScan -n _exp-dg1z_0.018
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs dkz -P dkz --freezeNuisances lZ,dg1z --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange dkz=-0.02,0.02 --minimizerStrategy=2 --cminPreScan -n _exp-dkz_0.02

2-D Limits--expected
----------
combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cwww,ccw -P cwww -P ccw --freezeNuisances cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _exp-cwww_3.6_ccw_4.5

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs cwww,cb -P cwww -P cb --freezeNuisances ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _exp-cwww_3.6_cb_20

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs ccw,cb -P ccw -P cb --freezeNuisances cwww --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _exp-ccw_4.5_cb_20

# For vertex parametrization
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs lZ,dg1z -P lZ -P dg1z --freezeNuisances dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange lZ=-0.014,0.014:dg1z=-0.018,0.018 --minimizerStrategy=2 --cminPreScan -n _exp-lZ_0.014_dg1z_0.018
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs lZ,dkz -P lZ -P dkz --freezeNuisances dg1z --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange lZ=-0.014,0.014:dkz=-0.02,0.02 --minimizerStrategy=2 --cminPreScan -n _exp-lZ_0.014_dkz_0.02
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid -t -1 --points=1000 --redefineSignalPOIs dg1z,dkz -P dg1z -P dkz --freezeNuisances dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange dg1z=-0.018,0.018:dkz=-0.02,0.02 --minimizerStrategy=2 --cminPreScan -n _exp-dg1z_0.018_dkz_0.02

#################################################################################################

1-D Limits--observed
----------
combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cwww -P cwww --freezeNuisances ccw,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6 --minimizerStrategy=2 --cminPreScan -n _obs-cwww_3.6

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs ccw -P ccw --freezeNuisances cwww,cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _obs-ccw_4.5

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cb -P cb --freezeNuisances cwww,ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _obs-cb_20

# For vertex parametrization
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs lZ -P lZ --freezeNuisances dg1z,dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange lZ=-0.014,0.014 --minimizerStrategy=2 --cminPreScan -n _obs-lZ_0.014
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs dg1z -P dg1z --freezeNuisances lZ,dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange dg1z=-0.018,0.018 --minimizerStrategy=2 --cminPreScan -n _obs-dg1z_0.018
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs dkz -P dkz --freezeNuisances lZ,dg1z --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange dkz=-0.02,0.02 --minimizerStrategy=2 --cminPreScan -n _obs-dkz_0.02

2-D Limits--observed
----------
combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cwww,ccw -P cwww -P ccw --freezeNuisances cb --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:ccw=-4.5,4.5 --minimizerStrategy=2 --cminPreScan -n _obs-cwww_3.6_ccw_4.5

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs cwww,cb -P cwww -P cb --freezeNuisances ccw --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange cwww=-3.6,3.6:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _obs-cwww_3.6_cb_20

combine workspace_simfit.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs ccw,cb -P ccw -P cb --freezeNuisances cwww --setPhysicsModelParameters cwww=0,ccw=0,cb=0 --setPhysicsModelParameterRange ccw=-4.5,4.5:cb=-20,20 --minimizerStrategy=2 --cminPreScan -n _obs-ccw_4.5_cb_20

# For vertex parametrization
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs lZ,dg1z -P lZ -P dg1z --freezeNuisances dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange lZ=-0.014,0.014:dg1z=-0.018,0.018 --minimizerStrategy=2 --cminPreScan -n _obs-lZ_0.014_dg1z_0.018
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs lZ,dkz -P lZ -P dkz --freezeNuisances dg1z --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange lZ=-0.014,0.014:dkz=-0.02,0.02 --minimizerStrategy=2 --cminPreScan -n _obs-lZ_0.014_dkz_0.02
combine workspace_simfitLEP.root -M MultiDimFit --floatOtherPOIs=0 --algo=grid --expectSignal=1 --points=1000 --redefineSignalPOIs dg1z,dkz -P dg1z -P dkz --freezeNuisances dkz --setPhysicsModelParameters lZ=0,dg1z=0,dkz=0 --setPhysicsModelParameterRange dg1z=-0.018,0.018:dkz=-0.02,0.02 --minimizerStrategy=2 --cminPreScan -n _obs-dg1z_0.018_dkz_0.02

#################################################################################################

mkdir ResultsExpected
mkdir ResultsObserved

mv *_exp-*.root ResultsExpected/
mv *_obs-*.root ResultsObserved/

Get 68% and 95% Confidence Intervals
------------------------------------
python build1DInterval.py -3.6 3.6 ResultsObserved/higgsCombine_obs-cwww_3.6.MultiDimFit.mH120.root cwww > cwww-limits.log
python build1DInterval.py -4.5 4.5 ResultsObserved/higgsCombine_obs-ccw_4.5.MultiDimFit.mH120.root ccw > ccw-limits.log
python build1DInterval.py -20  20  ResultsObserved/higgsCombine_obs-cb_20.MultiDimFit.mH120.root cb > cb-limits.log


# Plot the 1-D expected limits as .pdf files, uses the same files as above step:

python plot1D_limit_Expected.py --POI cwww --pval 3.6
python plot1D_limit_Expected.py --POI ccw --pval 4.5
python plot1D_limit_Expected.py --POI cb --pval 20

# Plot the 2-D expected limits as .pdf files, uses the 2-d multidim fits:

python plot2D_limit_Expected.py --POI cwww,ccw --pval 3.6,4.5
python plot2D_limit_Expected.py --POI cwww,cb --pval 3.6,20
python plot2D_limit_Expected.py --POI ccw,cb --pval 4.5,20

# Plot the 1-D observed+expected limits as .pdf files, uses the same files as above step:

python plot1D_limit.py --POI cwww --pval 3.6
python plot1D_limit.py --POI ccw --pval 4.5
python plot1D_limit.py --POI cb --pval 20

# Plot the 2-D observed+expected limits as .pdf files, uses the 2-d multidim fits:

python plot2D_limit.py --POI cwww,ccw --pval 3.6,4.5
python plot2D_limit.py --POI cwww,cb --pval 3.6,20
python plot2D_limit.py --POI ccw,cb --pval 4.5,20

later: (still unused: all maxlikelihood fit files)

plotCutoffLimits.py
signalInjectionTest.py
