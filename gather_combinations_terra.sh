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
LLCREPPOLS=( drrip drrip_half ship ship_half )

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
#echo "This script will check directory ${results_path} for results files."
#echo
                   
# First, print out the setting labels of the run
printf "Trace Name , Branch Predictor , L1I Prefetch , L1D Prefetch , L2 Prefetch , LLC Prefetch , " >> results_${DATE}.csv
printf "LLC Replacement Policy , Num Cores , Randomization , Matrix Num , " >> results_${DATE}.csv
printf "Num Sampled Sets , Num Instructions, Num Cycles , IPC \n" >> results_${DATE}.csv

for trace in "${traces[@]}"
do
  # Debug
  #echo "Now working on trace ${trace}..."
  
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
                
                # Just get the trace name again
                tracename=`echo ${trace}|cut -d'.' -f2|cut -d'_' -f1`
                
                for mats in "${RANDOMMATRIX[@]}"
                do
                  # Result file name
                  result_file=${tracename}_${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core_${rand}rand_${mats}mat
                 
                  # Add Kleene for file search, since each has job number extension
                  result_file_search=${tracename}_${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core_${rand}rand_${mats}mat*
                  
                  if [ -f ${results_path}/${result_file_search} ] ; then
                   # Debug
                   #echo "found configuration: ${result_file}!"
                   printf "${tracename} , ${branchpreds} , ${l1iprefs} , ${l1dprefs} , ${l2prefs} , ${llcprefs} , " >> results_${DATE}.csv
                   printf "${repls} , ${NCORES} , ${rand} , ${mats} , " >> results_${DATE}.csv
                  
                   cat ${results_path}/${result_file}.* | awk 'BEGIN {FS=" "} { if ($1=="Finished") print $5 " , " $7 " , " $10} END{ }' >> results_${DATE}.csv
                  fi
                done
                
                # Debug 
                #echo
              done
            done
          done
        done
      done
    done
  done
  # Debug 
  #echo
done

# Now, let us make summaries
cat results_${DATE}.csv | awk 'BEGIN{FS=" , "; OFS=" , "} {if (NR==1 || $10=="0") {print $0;} else if ($10 > 0 && $10 < 10) {avgs[$1][$7] += $13;} else {avgs[$1][$7] += $13; $NF=""; print $0" , "(avgs[$1][$7]/10);}} END{}' > results_${DATE}_avg.csv

#SBATCH --export=NONE                		#Do not propagate environment
