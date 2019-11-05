#!/bin/bash

source common.cfg

PREFETCHERS=( no ) #daampm bop ip_stride next_line) #vldp
REPLPOLS=( lru eaf kpcr ship srrip) #lru plru smdpp srrip drrip) # ship)
L1PREF=no #next_line
#tracelist=${TRACELISTS}/8core_list1.txt
tracelist=${TRACELISTS}/all_1core.txt

#NCORES=8
NCORES=1
OUTPUT_DIR=${PLOTS_DIR}/inclusivity/cores_${NCORES}
INPUT_DIR_BASE=${RESULTS_DIR}/noPref-smallC
#INPUT_DIR_BASE=${RESULTS_DIR}/inclusivity_results
INPUT_DIR_INC=${INPUT_DIR_BASE}/INC/results_1B
INPUT_DIR_NON=${INPUT_DIR_BASE}/NON/results_1B
INPUT_DIR_EXC=${INPUT_DIR_BASE}/EXC/results_1B

mkdir -p ${OUTPUT_DIR}

OUTPUT_IPC=${OUTPUT_DIR}/ipc
OUTPUT_SPEEDUP=${OUTPUT_DIR}/sp
OUTPUT_LLC_MPKI=${OUTPUT_DIR}/llc_mpki.csv
OUTPUT_EVICTIONS=${OUTPUT_DIR}/evict

INC_FOLDER=${RESULTS_DIR}/inclusivity_results/inclusive/results_1B
NON_FOLDER=${RESULTS_DIR}/inclusivity_results/non_inclusive/results_1B


rm -f ${OUTPUT_DIR}/*.csv

decimals=10

# IPC product per each prefetcher, in the same order as PREFETCHERS=(...)
speedup_prod=1


i=0
n=0
for pr in `seq 0 $((${#PREFETCHERS[@]}-1))`;
do
    echo "Starting with prefetcher number ${pr}/$((${#PREFETCHERS[@]}-1)) (${PREFETCHERS[$pr]})..."
    speedup_prod=1
    ntrpf=0
    pf=${PREFETCHERS[${pr}]} #`echo ${filename}|cut -d'-' -f3`
    for re in `seq 0 $((${#REPLPOLS[@]}-1))`;
    do
        echo "Starting with replacement policy number ${re}/$((${#REPLPOLS[@]}-1)) (${PREFETCHERS[$pr]}+${REPLPOLS[$re]})..."
        reppol=${REPLPOLS[${re}]} #`echo ${filename}|cut -d'-' -f4`
        while read trace
        do
            f=${RESULTS_DIR}/results_1B/${trace}-champsim-${L1PREF}-${pf}-${reppol}-${NCORES}core.txt
            LRU_f=${RESULTS_DIR}/results_1B/${trace}-champsim-${L1PREF}-${pf}-lru-${NCORES}*
            
            if [ -f ${LRU_f} ] ; then 
            if grep -q "Exit status: 0" ${LRU_f}; then
            if [ -f ${f} ] ; then 
            if grep -q "Exit status: 0" ${f}; then
                filename=`echo $f|xargs -0 -n 1 basename`
                trace=`echo ${filename}|cut -d'-' -f1`
                ipc=`grep "IPC:" ${f}|tail -1|cut -d':' -f4|xargs|cut -d' ' -f1`
                ipc_LRU=`grep "IPC:" ${LRU_f}|tail -1|cut -d':' -f4|xargs|cut -d' ' -f1`
                speedup=`echo "scale=${decimals}; ${ipc}/${ipc_LRU}"|bc`

                # Inclusivity
                l1_evict=`grep "l1d.sim_evict="|awk '{print $2;}'`

                #llc_mpki=`grep "Final:" ${f} -A 2|awk '{print $9;}'`
                #echo "IPC=${ipc} (${filename}), IPC_LRU=${ipc_LRU} (${LRU_f}), Sp=${speedup}"
                
                if [ ! -f ${OUTPUT_SPEEDUP}_${pf}.csv ] ; then
                    echo "trace,prefetcher,replpol,speedup" > ${OUTPUT_SPEEDUP}_${PREFETCHERS[$pr]}.csv
                fi

#                if [[ ${f} != *"-lru"* ]] ; then
                    # SPEEDUP
                    echo "${trace},${pf},${reppol},${speedup}" >> ${OUTPUT_SPEEDUP}_${pf}.csv
                    #echo "${trace},${pf},${reppol},${speedup}"
#                fi

                # IPC
                if [ ! -f ${OUTPUT_IPC}_${pf}.csv ] ; then
                    echo "trace,prefetcher,replpol,ipc" > ${OUTPUT_IPC}_${pf}.csv
                fi
                echo "${trace},${pf},${reppol},${ipc}" >> ${OUTPUT_IPC}_${pf}.csv

                # geomean
                if [ $(echo "${ipc} > 0"|bc) -eq 1 ] ; then
                    prev_sppr=${speedup_prod}
                    speedup_prod=`echo "scale=${decimals}; ${speedup}*${speedup_prod}"|bc`
                fi


                i=$((i+1))
                ntrpf=$((ntrpf+1))
            else
                echo "Missing: ${f}"
            fi
            n=$((n+1))
            fi
            fi
            fi
        done < ${tracelist}
    # geomean
    geomean="Error"
    if [ $(echo "${speedup_prod} >= 0"|bc) -eq 1 ] ; then
        geomean=`awk -v var1="${speedup_prod}" -v var2="$ntrpf" 'BEGIN { printf "%.17g\n", var1^(1/var2)  }'`
    fi
    number='^[0-9]+([.][0-9]+)?$'
    if ! [[ ${geomean} =~ ${number} ]] ; then
        echo "**** Error in geomean for ${PREFETCHERS[$pr]}+${REPLPOLS[$re]}, speedup_prod=${speedup_prod}, geomean=${geomean}"
        exit
    fi
    echo "geomean,${pf},${reppol},${geomean}" >> ${OUTPUT_SPEEDUP}_${pf}.csv
    echo "====Geomean of ${pf} and ${reppol} is: geomean=${geomean}"
    speedup_prod=1
    ntrpf=0
    done
done


echo "Finished ${i} out of ${n}."
