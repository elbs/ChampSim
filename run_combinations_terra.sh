#!/bin/bash

# Source the config file for variables
source common.cfg

# Argument helps date runs
DATE=$2

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
L2PREF=( no )

# LLC Prefetcher
#LLCPREF=( no next_line )
LLCPREF=( no )

# LLC Replacement policy
#LLCREPPOLS=( drrip lru ship srrip )
LLCREPPOLS=( lru )

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
    tracelist=${TRACELISTS}/spec2017_benchs.txt
fi

ntraces=`cat ${tracelist}|wc -l`
nsims=$(echo "${ntraces}*${#BRANCHPRED[@]}*${#L1IPREF[@]}*${#L1DPREF[@]}*${#L2PREF[@]}*${#LLCPREF[@]}*${#LLCREPPOLS[@]}"|bc)

echo "This script will launch ${nsims} simulations with ${NCORES} cores:"
echo "    - ${ntraces} traces"
echo "    - ${#BRANCHPRED[@]} Branch Predictors" 
echo "    - ${#L1IPREF[@]} L1I prefetchers" 
echo "    - ${#L1DPREF[@]} L1D prefetchers" 
echo "    - ${#L2PREF[@]} L2 prefetchers" 
echo "    - ${#LLCPREF[@]} LLC prefetchers" 
echo "    - ${#LLCREPPOLS[@]} LLC replacement policies"
echo

binary_running_path=${BINARY_DIR}/running/uncommented/
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
            binary=${branchpreds}-${l1iprefs}-${l1dprefs}-${l2prefs}-${llcprefs}-${repls}-${NCORES}core
            
            if [ ! -e ${BINARY_DIR}/running/uncommented/${binary} ] ; then
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
#SBATCH --job-name=${trace_name}_${binary}               # Set the job name to "JobExample1"
#SBATCH --time=${limit_hours}:00:00                      # Set the wall clock limit to 48h
#SBATCH --ntasks=${ntasks}                               # Request 2 task
#SBATCH --mem=1024M                                      # Request 1GB per node
#SBATCH --output=${RESULTS_DIR}/${DATE}/${NCORES}cores/${trace_name}_${binary}.%j   #Send stdout/err to "Example1Out.[jobID]"

##OPTIONAL JOB SPECIFICATIONS
#SBATCH --mail-type=ALL              		                # Send email on all job events
#SBATCH --mail-user=elba@tamu.edu	                      # Send all emails to email_address

##First Executable Line
${binary_running_path}/${binary} -warmup_instructions ${WARMUP} -simulation_instructions ${INSTRS} -traces ${trace_routes[@]}
EOF

                echo "$binary with mix $i (${trace})"
                sbatch ${job}
                rm ${job}
              fi

            done < ${tracelist}
               
            # Why this?
            #if [[ ${repls} = "lru" ]]; then 
            #    break
            #fi
          done
        done
      done
    done
  done
done

#SBATCH --export=NONE                		#Do not propagate environment
