# Back Trajectories Scripts for Matlab
 A collection of useful functions and scripts for using HYSPLIT back trajectories with Matlab

- "calculate_backtraj.m" is used together with HYSPLIT V4 to setup and calculate back trajectories with 6-h time resolution for the desired number of startig location (up to thousands) for a single month.
- "import_multiple_backtraj.m" can be used to automatically import HYSPLIT backtrajectory output files into Matlab
- "endpoints_frequency.m" can be used to calculate the frequency of trajectory endpoints per map unit. The script produces a map. Example data "ready to run" provided.
- "CWT_with_errors.m" script for calculating the Concentration Weighted Trajectories field (Work in Progress)
- "moisture_uptake.m" function to determine moisture uptake location using the procedure described in Sodemann et al. 2008. Example data "ready to run" provided.