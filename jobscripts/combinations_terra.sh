#!/bin/bash

source common.cfg
INCLUSION=$1
output_folder=${INCLUSION}
DATE=$2

if [ "$INCLUSION" == "INC" ] ; then      # INCLUSIVE
    echo "Launching the INCLUSIVE versions"
    echo
elif [ "$INCLUSION" == "NON" ] ; then    # NON-INCLUSIVE
    echo "Lunching the NON-INCLUSIVE versions"
    echo
elif [ "$INCLUSION" == "EXC" ] ; then    # EXCLUSIVE
    echo "Launching the EXCLUSIVE versions"
    echo
else
    echo "Wrong inclusion argument, should be: (INC, NON, EXC)"
    echo "bash $0 INCLUSION{INC,NON,EXC} DATE"
    exit
fi
if [ $# -ne 2 ]; then
    echo "bash $0 INCLUSION{INC,NON,EXC} DATE(yymmdd)"
    exit
fi


# L2 Prefecher
PREFETCHERS=( no ) #kpcp ip_stride ) #next_line ) #ip_stride bop daampm kpcp next_line ) #vldp
#PREFETCHERS=( no ip_stride bop daampm kpcp next_line ) #(no daampm bop ip_stride next_line) #vldpREPLPOLS=( exdrrip drrip lru ) #lru eaf kpcr ship drrip ) #lru plru smdpp srrip drrip) # ship)
REPLPOLS=( lru ship ) #lru eaf kpcr ship drrip ) #lru plru smdpp srrip drrip) # ship)
L1PREF=( no ) #next_line )
#PREFETCHERS=( no ) #(no daampm bop ip_stride next_line) #vldp
#REPLPOLS=( lru ) #drrip ) #lru plru smdpp srrip drrip) # ship)
BRANCHPRED=( perceptron ) #bimodal gshare )
PATTERN=( NONE REFTRACE FILL_PC LAST_PC )
WARMUP=500000000 #200000000
INSTRS=5000000000 #1000000000


# Job config
NCORES=1
if [ "${NCORES}" -eq 1 ] ; then
    limit_hours=20 # 5 for 1B is enough
    ntasks=1
    tracelist=${TRACELISTS}/spec2017_benchs.txt
    #tracelist=${TRACELISTS}/other_benchs.txt
    #tracelist=${TRACELISTS}/spec06.txt
    #tracelist=${TRACELISTS}/mcf17.txt
    #tracelist=${TRACELISTS}/asserted.txt #spec2017_benchs.txt
    #tracelist=${TRACELISTS}/non-spec.txt
    #tracelist=${TRACELISTS}/all_1core.txt
    #tracelist=${TRACELISTS}/astar.txt
elif [ "${NCORES}" -eq 4 ] ; then
    limit_hours=50
    ntasks=1
    tracelist=${TRACELISTS}/other_benchs_4c.txt
    #tracelist=${TRACELISTS}/daniel_spec2017_4core.txt #spec2017_benchs_mixes4.txt
    #tracelist=${TRACELISTS}/asserted8.txt
    #tracelist=${TRACELISTS}/spec2017_benchs_mixes8.txt
    #tracelist=${TRACELISTS}/4core_list1.txt #4core_1sim.txt
else
    echo "Error: incorrect number of cores (${NCORES} instead of 1 or 8)"
    echo "bash $0 INCLUSION{INC,NON,EXC} NCORES{1,8}"
    exit
fi

option=""

#MIXES=( 1 )
run_mix=1
#ntraces=`${#MIXES[@]}`  #`cat ${tracelist}|wc -l`
ntraces=`cat ${tracelist}|wc -l`
echo $ntraces
nsims=$(echo "${ntraces}*${#PREFETCHERS[@]}*${#REPLPOLS[@]}*${#L1PREF[@]}*${#PATTERN[@]}"|bc)

echo "This script will launch ${nsims} simulations with ${NCORES} cores:"
echo "    - ${ntraces} traces"
echo "    - ${#PREFETCHERS[@]} x ${#L1PREF[@]} prefetchers" 
echo "    - ${#REPLPOLS[@]} replacement policies"
echo "    - ${#PATTERN[@]} patterns"
echo


binary_running_path=${BINARY_DIR}/running/${INCLUSION}
mkdir -p ${RESULTS_DIR}/${DATE}/${NCORES}cores/${INCLUSION}

for branchpreds in "${BRANCHPRED[@]}"
do
    for l1prefs in "${L1PREF[@]}"
    do
        for prefs in "${PREFETCHERS[@]}"
        do
            for repls in "${REPLPOLS[@]}"
            do
                for patterns in "${PATTERN[@]}"
                do
                    binary=champsim-${INCLUSION}-${branchpreds}-${l1prefs}-${prefs}-${repls}-${NCORES}core-${patterns}
                    if [ ! -e ${BINARY_DIR}/running/${INCLUSION}/${binary} ] ; then
                        echo "Error: no binary file found for ${binary}"
                        exit
                    fi
                    i=0
                    while read trace
                    do
                        job=tmp.job #${binary}_${trace}.job
                        ((i++))
                        #if [ ${NCORES} -eq 4 ] ; then
                        #    run_mix=0
                        #    for m in "${MIXES[@]}"
                        #    do
                        #        if [ $m -eq $i ] ; then
                        #            run_mix=1
                        #            continue
                        #        fi
                        #    done
                        #fi

                        if [ ${run_mix} -eq 1 ] ; then

                            if [ ${NCORES} -eq 1 ] ; then
                                trace_name=`echo ${trace}|cut -d'.' -f2|cut -d'_' -f1`
                            elif [ "${NCORES}" -eq 4 ] ; then
                                trace_name="mix${i}"
                            fi
                            IFS=' ' read -r -a trace_names <<< ${trace}

                            prefix="${TRACE_DIR}/"
                            #suffix=".trace.gz"

                            trace_routes=()
                            for E in "${trace_names[@]}"; do
                                trace_routes+=("${prefix}${E}")
                                #trace_routes+=("${prefix}${E}${suffix}")
                            done

                            #echo "Running traces:"
                            #echo "${trace_routes[@]}"
                            #echo

                            cat <<EOF > ${job}
#!/bin/bash
##ENVIRONMENT SETTINGS; CHANGE WITH CAUTION
#SBATCH --get-user-env=L             		#Replicate login environment

##NECESSARY JOB SPECIFICATIONS
#SBATCH --job-name=${trace_name}_${binary}                                #Set the job name to "JobExample1"
#SBATCH --time=${limit_hours}:00:00                                  #Set the wall clock limit to 48h
#SBATCH --ntasks=${ntasks}                                           #Request 2 task
#SBATCH --mem=1024M                                                   #Request 1GB per node
#SBATCH --output=${RESULTS_DIR}/${DATE}/${NCORES}cores/${INCLUSION}/${trace_name}_${binary}.%j   #Send stdout/err to "Example1Out.[jobID]"

##OPTIONAL JOB SPECIFICATIONS
#SBATCH --mail-type=ALL              		#Send email on all job events
#SBATCH --mail-user=luna.backes@gmail.com 	#Send all emails to email_address

#First Executable Line

${binary_running_path}/${binary} -warmup_instructions ${WARMUP} -simulation_instructions ${INSTRS} -traces ${trace_routes[@]}
EOF

                            echo "$binary with mix $i (${trace})"
                            sbatch ${job}
                            rm ${job}
                        fi
    
                    done < ${tracelist}
                    if [[ ${repls} = "lru" ]]; then 
                        break
                    fi
                done
            done
        done
    done
done
##SBATCH --export=NONE                		#Do not propagate environment
