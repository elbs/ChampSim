#!/bin/bash

source common.cfg

INCLUSION=INC
output_folder=${INCLUSION} 

# L2 Prefecher
#PREFETCHERS=( ip_stride next_line ) #(no daampm bop ip_stride next_line) #vldp
#REPLPOLS=(lru eaf kpcr ship srrip) #lru plru smdpp srrip drrip) # ship)
PREFETCHERS=( no daampm bop ip_stride next_line kpcp ) #vldp
REPLPOLS=( lru eaf kpcr ship srrip ) #lru plru smdpp srrip drrip) # ship)
MACHINES=( chalupa cajeta churro jicaleta oblea pozole puchepo tamal torta semita turco cabron manzana tresleches flauta antojito empanada nopalito guacamole flan mole queso ) #tortilla 
L1PREF=( no next_line )
BRANCHPRED=( perceptron ) #bimodal gshare )

NCORES=4
#EDIT TRACELIST IN RUN_4CORE.SH AS WELL!!!!
tracelist=${TRACELISTS}/4core_list1.txt
option=""
#SIMSPERMACHINE=3
MAX_CPU_LOAD=500

ntraces=`cat ${tracelist}|wc -l`
nlines=${ntraces}
nsims=$(echo "${ntraces}*${#PREFETCHERS[@]}*${#REPLPOLS[@]}*${#L1PREF[@]}"|bc)


function check_connectivity {
    i=$1
    #echo Checking connectivity of machine ${MACHINES[${i}]}...
    
    con=`ssh -q -o "BatchMode=yes" ${machine} "echo 2>&1" && echo $host SSH_OK || echo $host SSH_NOK`
    connectivity=`echo $con |awk '{ print $1 }'`
    #echo "connectivity=${connectivity}"
    
    waiting=0
    while [ "${connectivity}" == "SSH_NOK" ]
    do
        #echo "in while for connectivity"
        i=$((i+1))
        if (( $i % ${#MACHINES[@]} == 0 )) ; then
            i=0
        fi
        machine=${MACHINES[${i}]}
        con=`ssh -q -o "BatchMode=yes" ${machine} "echo 2>&1" && echo $host SSH_OK || echo $host SSH_NOK`
        connectivity=`echo $con |awk '{ print $1 }'`
    done
    #echo $i
}


echo "This script will launch ${nsims} simulations:"
echo "    - ${ntraces} simulations of $NCORES traces"
echo "    - ${#PREFETCHERS[@]} prefetchers" 
echo "    - ${#REPLPOLS[@]} replacement policies"
echo -n "All simulations will be distributed in ${#MACHINES[@]} machines. "
echo "Maximum ${MAX_CPU_LOAD} cpu load per machine."
echo

binary_running_path=${BINARY_DIR}/running/${INCLUSION}
mkdir -p ${RESULTS_DIR}/${INCLUSION}

i=0
nsim=0
for branchpreds in "${BRANCHPRED[@]}"
do
    for l1prefs in "${L1PREF[@]}"
    do
        for prefs in "${PREFETCHERS[@]}"
        do
            for repls in "${REPLPOLS[@]}"
            do
                if (( $i % ${#MACHINES[@]} == 0 )) ; then
                    echo "Starting again from first machine"
                    i=0
                fi
                binary=champsim-${INCLUSION}-${branchpreds}-${l1prefs}-${prefs}-${repls}-${NCORES}core
                if [ ! -e ${binary_running_path}/${binary} ] ; then
                    echo "Error: no binary file found for ${binary}"
                    exit
                    #echo "Compiling binary ${binary}"
                    #bash ${ROOT}/build_champsim.sh ${L1PREF} ${prefs} ${repls} ${NCORES}
                fi
                if [ ! -e ${binary_running_path}/${binary} ] ; then
                    echo "Error: no binary file found for ${binary}"
                    exit
                fi
                nl=1 #number of line in tracelist
        
                # For each benchmark set (1 simulation)
                while [ ${nl} -le ${nlines} ]
                do
                    # Choose machine to run this simulation
                    machine=${MACHINES[${i}]}
                    hostnameis=`hostname`
        
                    # Check connectivity to host
#                    echo $i
                    check_connectivity $i
#                    echo $i
        
                    # Do not use machine if it is being used already
                    cpu_load=`ssh -T ${MACHINES[${i}]} "ps -A -o pcpu | tail -n+2 | paste -sd+ | bc"`
                    cpu_load=`perl -w -e "use POSIX; print ceil(${cpu_load})"`
        
                    waiting=0
                    # Do not use machine if it is already on full load defined by SIMSPERMACHINE
                    echo "cpu_load= ${cpu_load}"
                    while (( ${cpu_load} >= ${MAX_CPU_LOAD} ))
                    do
                        echo -n "('${MACHINES[${i}]}' machine on full load (${cpu_load}) already (${nsim}/${nsims})"
                        i=$((i+1))
                        if (( $i % ${#MACHINES[@]} == 0 )) ; then
                            i=0
                        fi
                        #whoisthere=`ssh -T ${MACHINES[${i}]} "who|grep -v lbackes|grep -v unknown|cut -d' ' -f1" </dev/null`
                        #running=`ssh -T ${MACHINES[${i}]} "ps -u lbackes|grep champsim|wc -l" </dev/null`
                        cpu_load=`ssh -T ${MACHINES[${i}]} "ps -A -o pcpu | tail -n+2 | paste -sd+ | bc"`
                        cpu_load=`perl -w -e "use POSIX; print ceil(${cpu_load})"`
                        waiting=$((waiting+1))
                        if [ $waiting -ge 30 ] ; then
                            echo "Sleeping for 10min"
                            sleep 10m
                            waiting=0
                        fi
                    done
        
                    # Run simulation via ssh
                    echo "Running binary '${binary}' line_number '$nl' in '${MACHINES[${i}]}'"
                    ssh -n -f -T ${MACHINES[${i}]} "cd ChampSim; bash ${SCRIPTS_DIR}/run_${NCORES}core.sh ${binary} ${nl} ${INCLUSION}"
                    nsim=$((nsim+1))
                    echo "Running ${nsim}/${nsims}"
                    i=$((i+1))
                    if (( $i % ${#MACHINES[@]} == 0 )) ; then
                        i=0
                    fi
                    nl=$((nl+1))
                done # while lines
                i=$((i+1))
            done
        done
    done
done
