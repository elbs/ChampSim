#!/bin/bash

source common.cfg

INCLUSION=INC
output_folder=${INCLUSION} #non_inclusive

MACHINES=( chalupa cajeta churro jicaleta oblea pozole puchepo tamal torta semita turco cabron manzana tresleches flauta antojito empanada nopalito guacamole flan mole queso ) #tortilla 
# L2 Prefecher
PREFETCHERS=( ip_stride kpcp bop next_line ) #no ip_stride next_line bop daampm kpcp ) #(no daampm bop ip_stride next_line) #vldp
REPLPOLS=( ship kpcr ) #lru eaf kpcr ship srrip ) #lru plru smdpp srrip drrip) # ship)
L1PREF=( no next_line )
BRANCHPRED=( perceptron ) #bimodal gshare )

NCORES=1
#tracelist=${TRACELISTS}/astar.txt
tracelist=${TRACELISTS}/all_1core.txt
option=""
MAX_CPU_LOAD=700
#SIMSPERMACHINE=3

ntraces=`cat ${tracelist}|wc -l`
nsims=$(echo "${ntraces}*${#PREFETCHERS[@]}*${#REPLPOLS[@]}*${#L1PREF[@]}"|bc)

echo "This script will launch ${nsims} simulations:"
echo "    - ${ntraces} traces"
echo "    - ${#PREFETCHERS[@]} prefetchers" 
echo "    - ${#REPLPOLS[@]} replacement policies"
echo -n "All simulations will be distributed in ${#MACHINES[@]} machines. "
echo "Maximum ${MAX_CPU_LOAD} cpu load per machine."
#echo "Maximum ${SIMSPERMACHINE} simulations per machine."
echo

binary_running_path=${BINARY_DIR}/running

if [ -d ${binary_running_path} ] ; then
    echo "Error: ${binary_running_path} exists, potentially about to rewrite results."
    echo "Please, save results to a different directory."
    exit
fi

mkdir -p ${binary_running_path}

echo "Launching simulations..."

nsim=0
i=0
for branchpreds in "${BRANCHPRED[@]}"
do
    for l1prefs in "${L1PREF[@]}"
    do
        for prefs in "${PREFETCHERS[@]}"
        do
            for repls in "${REPLPOLS[@]}"
            do
                binary=champsim-${INCLUSION}-${branchpreds}-${l1prefs}-${prefs}-${repls}-${NCORES}core
                #if [ ! -e ${BINARY_DIR}/${binary} ] ; then
                #    echo "Compiling binary ${binary}"
                #    bash ${ROOT}/build_champsim.sh ${L1PREF} ${prefs} ${repls} ${NCORES} ${INCLUSION}
                #fi
                if [ ! -e ${binary_running_path}/${binary} ] ; then
                    echo "Error: no binary file found for ${binary}"
                    exit
                fi
                while read trace
                do
                    machine=${MACHINES[${i}]}
                    hostnameis=`hostname`
                    #whoisthere=`ssh -T ${MACHINES[${i}]} "who|grep -v lbackes|grep -v unknown|cut -d' ' -f1|head -1" </dev/null`
                    running=`ssh -T ${MACHINES[${i}]} "ps -u lbackes|grep champsim|wc -l" </dev/null`
                    while [ -z ${running} ] ; do
                        echo "Running does not match. Exiting."

                        i=$((i+1))
                        if (( $i % ${#MACHINES[@]} == 0 )) ; then
                            i=0
                        fi
                        running=`ssh -T ${MACHINES[${i}]} "ps -u lbackes|grep champsim|wc -l" </dev/null`

                        #sleep 1m
                        #exit
                    done

                    echo "Running=$running"
                    cpu_load=`ssh -T ${MACHINES[${i}]} "ps -A -o pcpu | tail -n+2 | paste -sd+ | bc"`
                    cpu_load=`perl -w -e "use POSIX; print ceil(${cpu_load})"`
                    echo "cpu_load= ${cpu_load}"
                    #echo "Hostname is $hostnameis and machine is $machine who: $whoisthere"
                    #while [ -n "${whoisthere}" -o ${running} -ge ${SIMSPERMACHINE} ]
                    waiting=0
                    while (( ${cpu_load} >= ${MAX_CPU_LOAD} ))
                    do
                        echo -n "('${MACHINES[${i}]}' machine on full load (${cpu_load}) already (${nsim}/${nsims})"
                        i=$((i+1))
                        if (( $i % ${#MACHINES[@]} == 0 )) ; then
                            i=0
                        fi
                        #whoisthere=`ssh -T ${MACHINES[${i}]} "who|grep -v lbackes|grep -v unknown|cut -d' ' -f1" </dev/null`
                        #running=`ssh -T ${MACHINES[${i}]} "ps -u lbackes|grep champsim|wc -l" </dev/null`
                        cpu_load=`ps -eo pcpu|sort -r -k1|head -9|tail -8|awk '{s+=$1} END {print s}'`
                        waiting=$((waiting+1))
                        if [ $waiting -ge 30 ] ; then
                            echo "Sleeping for 10min"
                            sleep 10m
                            waiting=0
                        fi
                    done

                    echo "Running binary '${binary}' with trace '$trace' in '${MACHINES[${i}]}'"
                    ssh -n -f -T ${MACHINES[${i}]} "cd ChampSim; ${SCRIPTS_DIR}/run_1B.sh ${binary} ${trace} ${output_folder} ${option} &"
                    nsim=$((nsim+1))
                    echo "Running ${nsim}/${nsims}"
                    i=$((i+1))
                    if (( $i % ${#MACHINES[@]} == 0 )) ; then
                        echo "Starting again from first machine"
                        i=0
                    fi
                    #ssh -n -f -T ${MACHINES[${i}]} "sh -c 'hostname; cd champsim; nohup ./${SCRIPTS_DIR}/run_1B.sh ${binary} ${trace} ${option} > /dev/null 2>&1 &'"
                done < ${tracelist}
                i=$((i+1))
                if (( $i % ${#MACHINES[@]} == 0 )) ; then
                    echo "Starting again from first machine"
                    i=0
                fi
            done
        done
    done
done

date
