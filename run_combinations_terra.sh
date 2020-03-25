#!/bin/bash

# Source the config file for variables
source common.cfg

# Argument helps date runs
DATE=$1

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
#L2PREF=( no ip_stride kpcp next_line spp_dev )
#L2PREF=( no spp_dev )
L2PREF=( no )

# LLC Prefetcher
#LLCPREF=( no next_line )
#LLCPREF=( no next_line )
LLCPREF=( no )

# LLC Replacement policy
#LLCREPPOLS=( drrip lru ship srrip )
LLCREPPOLS=( drrip_random drrip )

# LLC Randomness
LLCRANDOM=(0 1)

# Matrix File Values
RANDOMMATRIX=( 0 1 2 )

# How many instructions we warm up to
# How many we keep stats for
# How many cores are used for each run 
#WARMUP=100000000
WARMUP=1000000
#INSTRS=500000000
INSTRS=5000000
NCORES=1

run_mix=1

# Job configuration
if [ "${NCORES}" -eq 1 ] ; then
    limit_hours=20 # 5 for 1B is enough
    ntasks=1
    #tracelist=${TRACELISTS}/spec2017_benchs.txt
    tracelist=${TRACELISTS}/spec2017_benchs_short.txt
fi

ntraces=`cat ${tracelist}|wc -l`
nsims=$(echo "${ntraces}*${#BRANCHPRED[@]}*${#L1IPREF[@]}*${#L1DPREF[@]}*${#L2PREF[@]}*${#LLCPREF[@]}*${#LLCREPPOLS[@]}*${#LLCRANDOM[@]}*${#RANDOMMATRIX[@]}"|bc)

echo "This script will launch up to ${nsims} simulations with ${NCORES} cores:"
echo "    - ${ntraces} traces"
echo "    - ${#BRANCHPRED[@]} Branch Predictor(s)" 
echo "    - ${#L1IPREF[@]} L1I prefetcher(s)" 
echo "    - ${#L1DPREF[@]} L1D prefetcher(s)" 
echo "    - ${#L2PREF[@]} L2 prefetcher(s)" 
echo "    - ${#LLCPREF[@]} LLC prefetcher(s)" 
echo "    - ${#LLCREPPOLS[@]} LLC replacement polic(y | ies)"
echo "    - ${#LLCRANDOM[@]} LLC randomness  polic(y | ies)"
echo "    - ${#RANDOMMATRIX[@]} LLC randomness matri(x | ies)"
echo

binary_running_path=${BINARY_DIR}/running/
if [ -e ${RESULTS_DIR}/${DATE}/${NCORES}cores/ ]; then
  rm -rf ${RESULTS_DIR}/${DATE}/${NCORES}cores/
fi

mkdir -p ${RESULTS_DIR}/${DATE}/${NCORES}cores/

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
                # Skip all combos of the matrix file values 
                # when no randomness is used
                if { [ ${rand} -eq 0 ] && [ ${mats} -gt 0 ]; } || { [ ${rand} -eq 1 ] && [ ${mats} -eq 0 ]; } ; then
                  echo "Skipping combination of ${rand} randomness and matrix file ${mats}"
                else 

                  binary=${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core

                  if [ ! -e ${BINARY_DIR}/running/${binary} ] ; then
                    echo "Error: no binary file found for ${binary}"
                    exit
                  fi

                  i=0
                  while read trace
                  do
                    job=${binary}_${trace}.job
                    ((i++))

                    if [ ${run_mix} -eq 1 ] ; then

                      if [ ${NCORES} -eq 1 ] ; then
                        trace_name=`echo ${trace}|cut -d'.' -f2|cut -d'_' -f1`
                      fi
                      IFS=' ' read -r -a trace_names <<< ${trace}

                      prefix="${TRACE_DIR}/"

                      trace_routes=()
                      for E in "${trace_names[@]}"; do
                          trace_routes+=("${prefix}${E}")
                          #trace_routes+=("${prefix}${E}${suffix}")
                      done

                      echo "Running traces:"
                      echo "${trace_routes[@]}"
                      echo

                      cat <<EOF > ${job}
#!/bin/bash
##ENVIRONMENT SETTINGS; CHANGE WITH CAUTION
#SBATCH --get-user-env=L                                #Replicate login environment

##NECESSARY JOB SPECIFICATIONS
#SBATCH --job-name=${trace_name}_${binary}_${rand}rand_${mats}mat              # Set the job name to "JobExample1"
#SBATCH --time=${limit_hours}:00:00                      # Set the wall clock limit to 48h
#SBATCH --ntasks=${ntasks}                               # Request 2 task
#SBATCH --mem=1024M                                      # Request 1GB per node
#SBATCH --output=${RESULTS_DIR}/${DATE}/${NCORES}cores/${trace_name}_${binary}_${rand}rand_${rand}mat.%j   #Send stdout/err to "Example1Out.[jobID]"

##OPTIONAL JOB SPECIFICATIONS
#SBATCH --mail-type=ALL              		                # Send email on all job events
#SBATCH --mail-user=elba@tamu.edu	                      # Send all emails to email_address

##First Executable Line
${binary_running_path}/${binary} -warmup_instructions ${WARMUP} -simulation_instructions ${INSTRS} -random_llc ${rand} -matrix_num ${mats} -traces ${trace_routes[@]} 
EOF

                      echo "$binary with mix $i (${trace}) and ${rand} randomness with ${mats} matrix"
                      sbatch ${job}
                      rm ${job}
                    fi
                  done < ${tracelist}
                fi
              done
            done
          done
        done
      done
    done
  done
done

#SBATCH --export=NONE                		#Do not propagate environment
