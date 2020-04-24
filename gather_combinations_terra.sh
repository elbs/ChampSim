#!/bin/bash

# Source the config file for variables
source common.cfg

# Argument helps identify run directory
DATE=$1

# We will check all possible combinations...
# Branch Predictor
#BRANCHPRED=( bimodal gshare hashed_perceptron perceptron )
BRANCHPRED=( hashed_perceptron )

# L1I Prefetcher
#L1IPREF=( no next_line )
L1IPREF=( no )

# L1D Prefetcher 
#L1DPREF=( no next_line )
L1DPREF=( no )

# L2 Prefecher
#L2PREF=( no spp_dev )
L2PREF=( no )

# LLC Prefetcher
#LLCPREF=( no next_line )
LLCPREF=( no )
# LLC Replacement policy
#LLCREPPOLS=( drrip_random drrip lru ship_random ship srrip )
LLCREPPOLS=( drrip_half drrip ship_half ship )

# LLC Randomness
LLCRANDOM=( 0 1 )

# Matrix File Values
RANDOMMATRIX=( 0 1 2 3 4 5 6 7 8 9 10 )

# Number of cores we tested on
NCORES=( 1 )

traces_path=${TRACELISTS}/spec2017_benchs.txt
results_path=${RESULTS_DIR}/${DATE}/${NCORES}cores/

# Read all trace names, removing numbers, and extensions
traces=()
i=0
while read trace 
do
  tracename=`echo ${trace}|cut -d'.' -f2|cut -d'_' -f1`
  traces[$i]="$trace"
  i=$((i+1))
done < ${traces_path}


# Debug
echo "This script will check directory ${results_path} for results files."
echo
                   
# First, print out the setting labels of the run
printf "Trace Name , Branch Predictor , L1I Prefetch , L1D Prefetch , L2 Prefetch , LLC Prefetch , "
printf "LLC Replacement Policy , Num Cores , Randomization , Matrix Num , "
printf "Num Sampled Sets , Num Instructions, Num Cycles , IPC \n"

for trace in "${traces[@]}"
do
  # Debug
  echo "Now working on trace ${trace}..."
  
  for branchpreds in "${BRANCHPRED[@]}"
  do
    for l1iprefs in "${L1IPREF[@]}"
    do
      for l1dprefs in "${L1DPREF[@]}"
      do
        for l2prefs in "${L2PREF[@]}"
        do
          for llcprefs in "${LLCPREF[@]}"
          do
            for repls in "${LLCREPPOLS[@]}"
            do
              for rand in "${LLCRANDOM[@]}"
              do
                for mats in "${RANDOMMATRIX[@]}"
                do
                  result_file=${trace}_${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core_${rand}rand_${mats}mat
                  result_file_search=${trace}_${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core_${rand}rand_${mats}mat*
                  if [ -f ${results_path}/${result_file_search} ] ; then
                   # Debug
                   #echo "found configuration: ${result_file}!"

                   printf "${trace} , ${branchpreds} , ${l1iprefs} , ${l1dprefs} , ${l2prefs} , ${llcprefs} , "
                   printf "${repls} , ${NCORES} , ${rand} , ${mats} , "
                  
                   # TODO - awk search every value
                   cat ${results_path}/${result_file}.* | awk 'BEGIN {FS=" "} { if ($1=="Finished") print $5 " , " $7 " , " $10} END{ }' 
                  fi
                done
                echo
              done
            done
          done
        done
      done
    done
  done
  echo
done

#SBATCH --export=NONE                		#Do not propagate environment
