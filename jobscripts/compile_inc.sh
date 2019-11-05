#!/bin/bash

source common.cfg

INCLUSION=INC
output_folder=${INCLUSION}

# L2 Prefecher
PREFETCHERS=( no ip_stride next_line bop daampm kpcp ) #(no daampm bop ip_stride next_line) #vldp
REPLPOLS=( lru eaf kpcr ship srrip ) #lru plru smdpp srrip drrip) # ship)
L1PREF=( no next_line )

NCORES=1
option=""
i=0

binary_running_path=${BINARY_DIR}/running/${INCLUSION}
rm -rf ${binary_running_path}

mkdir -p ${binary_running_path}

echo "Compiling all ${INCLUSION}..."
for l1prefs in "${L1PREF[@]}"
do
    for prefs in "${PREFETCHERS[@]}"
    do
        for repls in "${REPLPOLS[@]}"
        do
            binary=champsim-${INCLUSION}-${l1prefs}-${prefs}-${repls}-${NCORES}core
            if [ ! -e ${binary_running_path}/${binary} ] ; then
                echo "Compiling binary ${binary}"
                bash ${ROOT}/build_champsim.sh ${l1prefs} ${prefs} ${repls} ${NCORES} ${INCLUSION}
                mv ${BINARY_DIR}/${binary} ${binary_running_path}
            fi
            if [ ! -e ${binary_running_path}/${binary} ] ; then
                echo "Error: no binary file found for ${binary}"
                exit
            fi
        done
    done
done
