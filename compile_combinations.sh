#!/bin/bash

# Source the config file for variables
source common.cfg

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
#L2PREF=( no ip_stride kpcp next_line spp_dev)
#L2PREF=( no spp_dev )
L2PREF=( no )

# LLC Prefetcher
#LLCPREF=( no next_line )
#LLCPREF=( no next_line )
LLCPREF=( no next_line )

# LLC Replacement policy
#LLCREPPOLS=( drrip lru ship srrip)
LLCREPPOLS=( drrip_half drrip ship_half ship )

# How many cores are used by each variation
NCORES=1

binary_running_path=${BINARY_DIR}/running/
rm -rf ${binary_running_path}/*-${NCORES}core

# A directory for the binaries
mkdir -p ${binary_running_path}

# How many combinations are we compiling?
nsims=$(echo "${#BRANCHPRED[@]}*${#L1IPREF[@]}*${#L1DPREF[@]}*${#L2PREF[@]}*${#LLCPREF[@]}*${#LLCREPPOLS[@]}"|bc)

echo "Compiling all $nsims variations..."

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
            binary=${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core
            if [ ! -e ${binary_running_path}/${binary} ] ; then
              echo "Compiling binary ${binary}"
              bash ${ROOT}/build_champsim.sh ${branchpreds} ${l1iprefs} ${l1dprefs} ${l2prefs} ${llcprefs} ${repls} ${NCORES}
              mv ${BINARY_DIR}/${binary} ${binary_running_path}
            fi
            if [ ! -e ${binary_running_path}/${binary} ] ; then
              echo "Error: no binary file found for ${binary}"
              exit
            fi
          done
        done
      done
    done
  done
done
