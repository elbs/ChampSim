#!/bin/bash

source common.cfg

INCLUSION=NON
output_folder=${INCLUSION} 

# L2 Prefecher
PREFETCHERS=( no ip_stride next_line bop daampm kpcp ) #(no daampm bop ip_stride next_line) #vldp
REPLPOLS=( lru eaf kpcr ship srrip ) #lru plru smdpp srrip drrip) # ship)
L1PREF=( no next_line )
BRANCHPRED=( perceptron ) #bimodal gshare )


# Job config
NCORES=4
if [ "${NCORES}" -eq 1 ] ; then
    limit_hours=4
    ntasks=2
    tracelist=${TRACELISTS}/all_1core.txt
    #tracelist=${TRACELISTS}/astar.txt
elif [ "${NCORES}" -eq 4 ] ; then
    limit_hours=50
    ntasks=3
    tracelist=${TRACELISTS}/4core_list1.txt #4core_1sim.txt
fi

option=""

ntraces=`cat ${tracelist}|wc -l`
nsims=$(echo "${ntraces}*${#PREFETCHERS[@]}*${#REPLPOLS[@]}*${#L1PREF[@]}"|bc)

echo "This script will launch ${nsims} simulations with ${NCORES} cores:"
echo "    - ${ntraces} traces"
echo "    - ${#PREFETCHERS[@]} x ${#L1PREF[@]} prefetchers" 
echo "    - ${#REPLPOLS[@]} replacement policies"
echo

binary_running_path=${BINARY_DIR}/running/${INCLUSION}
mkdir -p ${RESULTS_DIR}/${INCLUSION}

for branchpreds in "${BRANCHPRED[@]}"
do
    for l1prefs in "${L1PREF[@]}"
    do
        for prefs in "${PREFETCHERS[@]}"
        do
            for repls in "${REPLPOLS[@]}"
            do
                binary=champsim-${INCLUSION}-${branchpreds}-${l1prefs}-${prefs}-${repls}-${NCORES}core
                if [ ! -e ${BINARY_DIR}/running/${INCLUSION}/${binary} ] ; then
                    echo "Error: no binary file found for ${binary}"
                    exit
                fi
                while read trace
                do
                    job=tmp.job #${binary}_${trace}.job

                    IFS=' ' read -r -a trace_names <<< ${trace}

                    prefix="${TRACE_DIR}/"
                    suffix=".trace.gz"

                    trace_routes=()
                    for E in "${trace_names[@]}"; do
                        trace_routes+=("${prefix}${E}${suffix}")
                    done

                    echo "Running traces:"
                    echo "${trace_routes[@]}"
                    echo

                    cat <<EOF > ${job}
##NECESSARY JOB SPECIFICATIONS
#BSUB -L /bin/bash           #Uses the bash login shell to initialize the job's execution environment.
#BSUB -J ${trace_names[0]}_${binary}                                #Set the job name to "JobExample1"
#BSUB -W ${limit_hours}:00                                  #Set the wall clock limit to 48h
#BSUB -n ${ntasks}                                           #Request 2 task
#BSUB -R "span[ptile=${ntasks}]"                            #Request 2 tasks pero node
#BSUB -M 2048
#BSUB -R "rusage[mem=2048]"                                                  #Request 256MB per node
#BSUB -o ${RESULTS_DIR}/${INCLUSION}/${trace_names[0]}_${binary}.%J   #Send stdout/err to "Example1Out.[jobID]"

##OPTIONAL JOB SPECIFICATIONS
#BSUB -N              		#Send email on all job events
#BSUB -u luna.backes@gmail.com 	#Send all emails to email_address

#First Executable Line

module load GCC/5.2.0

${binary_running_path}/${binary} -warmup_instructions 200000000 -simulation_instructions 1000000000 -traces ${trace_routes[@]}
EOF
                bsub < ${job}
                rm ${job}
    
                done < ${tracelist}
            done
        done
    done
done
