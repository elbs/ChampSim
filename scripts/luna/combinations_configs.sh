#!/bin/bash

source common.cfg

INCLUSION=INC
output_folder=${INCLUSION} #non_inclusive

MACHINES=( chalupa cajeta churro jicaleta oblea pozole puchepo tamal torta semita turco cabron manzana tresleches flauta antojito empanada nopalito guacamole flan mole queso ) #tortilla 

NCORES=1
#tracelist=${TRACELISTS}/astar.txt
RERUN=${TRACELISTS}/to_rerun.txt
option=""
MAX_CPU_LOAD=400
#SIMSPERMACHINE=3

nsims=`cat ${RERUN}|wc -l`

echo "This script will launch ${nsims} simulations:"
echo "From file ${RERUN}"
echo  "All simulations will be distributed in ${#MACHINES[@]} machines. "
echo "Maximum ${MAX_CPU_LOAD} cpu load per machine."
echo

binary_running_path=${BINARY_DIR}/running/${INCLUSION}


#if [ -d ${binary_running_path} ] ; then
#    echo "Error: ${binary_running_path} exists, potentially about to rewrite results."
#    echo "Please, save results to a different directory."
#    exit
#fi

#mkdir -p ${binary_running_path}

echo "Launching simulations..."

nsim=0
i=0
while read config
do
    trace=`echo "${config}"|awk 'BEGIN {FS = "_champsim-"} {print $1}'`
    binary=`echo "${config}"|awk 'BEGIN {FS = "_champsim-"} {print $2}'`
    binary="champsim-"${binary}
    echo "Binary: ${binary}"

    if [ ! -e ${binary_running_path}/${binary} ] ; then
        echo "Error: no binary file found for ${binary}"
        exit
    fi
    machine=${MACHINES[${i}]}
    running=`ssh -T ${MACHINES[${i}]} "ps -u lbackes|grep champsim|wc -l" </dev/null`
    while [ -z ${running} ] ; do
        echo "Running does not match. Exiting."

        i=$((i+1))
        if (( $i % ${#MACHINES[@]} == 0 )) ; then
            i=0
        fi
        running=`ssh -T ${MACHINES[${i}]} "ps -u lbackes|grep champsim|wc -l" </dev/null`
    done

    echo "Running=$running"
    cpu_load=`ssh -T ${MACHINES[${i}]} "ps -A -o pcpu | tail -n+2 | paste -sd+ | bc" </dev/null`
    cpu_load=`perl -w -e "use POSIX; print ceil(${cpu_load})"`
    echo "cpu_load= ${cpu_load}"
    
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
done < ${RERUN}

date
