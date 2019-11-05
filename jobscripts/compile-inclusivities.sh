#!/bin/bash

source common.cfg

INCLUSION=$1
output_folder=${INCLUSION}

if [ "$INCLUSION" == "INC" ] ; then      # INCLUSIVE
    echo "Compiling the INCLUSIVE versions"
    echo
elif [ "$INCLUSION" == "NON" ] ; then    # NON-INCLUSIVE
    echo "Compiling the NON-INCLUSIVE versions"
    echo
elif [ "$INCLUSION" == "EXC" ] ; then    # EXCLUSIVE
    echo "Compiling the EXCLUSIVE versions"
    echo
else
    echo "Wrong inclusion argument, should be: (INC, NON, EXC)"
    exit
fi
    

# L2 Prefecher
PREFETCHERS=( no ) #kpcp ip_stride ) #ip_stride next_line bop daampm kpcp ) #(no daampm bop ip_stride next_line) #vldp
REPLPOLS=( lru ship ) #lru drrip exdrrip ) #lru eaf kpcr ship drrip exdrrip ) #lru plru smdpp srrip drrip) 
L1PREF=( no ) #next_line )
#PREFETCHERS=( no ) #(no daampm bop ip_stride next_line) #vldp
#REPLPOLS=( lru ) #lru plru smdpp srrip drrip) 
#L1PREF=( next_line )
BRANCHPRED=( perceptron ) #bimodal gshare )
PATTERN=( NONE REFTRACE FILL_PC LAST_PC )

NCORES=1
option=""
i=0

binary_running_path=${BINARY_DIR}/running/${INCLUSION}
rm -rf ${binary_running_path}/*-${NCORES}core

mkdir -p ${binary_running_path}
nsims=$(echo "${#PREFETCHERS[@]}*${#REPLPOLS[@]}*${#L1PREF[@]}"|bc)

echo "Compiling all $nsims ${INCLUSION}..."
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
                    if [ ! -e ${binary_running_path}/${binary} ] ; then
                        echo "Compiling binary ${binary}"
                        bash ${ROOT}/build_champsim.sh ${branchpreds} ${l1prefs} ${prefs} ${repls} ${NCORES} ${INCLUSION} ${patterns}
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
