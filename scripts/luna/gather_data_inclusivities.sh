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


rm -f ${OUTPUT_DIR}/*.csv

decimals=10

# IPC product per each prefetcher, in the same order as PREFETCHERS=(...)
speedup_prod_inc=1
speedup_prod_exc=1


i=0
n=0
for pr in `seq 0 $((${#PREFETCHERS[@]}-1))`;
do
    echo "Starting with prefetcher number ${pr}/$((${#PREFETCHERS[@]}-1)) (${PREFETCHERS[$pr]})..."
    speedup_prod_inc=1
    speedup_prod_exc=1
    ntrpf=0
    pf=${PREFETCHERS[${pr}]} #`echo ${filename}|cut -d'-' -f3`
    for re in `seq 0 $((${#REPLPOLS[@]}-1))`;
    do
        echo "Starting with replacement policy number ${re}/$((${#REPLPOLS[@]}-1)) (${PREFETCHERS[$pr]}+${REPLPOLS[$re]})..."
        reppol=${REPLPOLS[${re}]} #`echo ${filename}|cut -d'-' -f4`
        speedup_output_file=${OUTPUT_SPEEDUP}_${pf}_${reppol}.csv
        while read trace
        do
            f_non=${INPUT_DIR_NON}/${trace}-champsim-NON-${L1PREF}-${pf}-${reppol}-${NCORES}core.txt
            f_inc=${INPUT_DIR_INC}/${trace}-champsim-INC-${L1PREF}-${pf}-${reppol}-${NCORES}core.txt
            f_exc=${INPUT_DIR_EXC}/${trace}-champsim-EXC-${L1PREF}-${pf}-${reppol}-${NCORES}core.txt

            if [ -f ${f_non} ] ; then 
            if grep -q "Exit status: 0" ${f_non}; then
            if [ -f ${f_inc} ] ; then 
            if grep -q "Exit status: 0" ${f_inc}; then
            if [ -f ${f_exc} ] ; then 
            if grep -q "Exit status: 0" ${f_exc}; then

                filename_non=`echo $f|xargs -0 -n 1 basename`
                filename_inc=`echo $f|xargs -0 -n 1 basename`
                filename_exc=`echo $f|xargs -0 -n 1 basename`
                
                #trace=`echo ${filename_non}|cut -d'-' -f1`
                
                ipc_non=`grep "IPC:" ${f_non}|tail -1|cut -d':' -f4|xargs|cut -d' ' -f1`
                ipc_inc=`grep "IPC:" ${f_inc}|tail -1|cut -d':' -f4|xargs|cut -d' ' -f1`
                ipc_exc=`grep "IPC:" ${f_exc}|tail -1|cut -d':' -f4|xargs|cut -d' ' -f1`
                
                speedup_inc=`echo "scale=${decimals}; ${ipc_inc}/${ipc_non}"|bc`
                speedup_exc=`echo "scale=${decimals}; ${ipc_exc}/${ipc_non}"|bc`

                # Inclusivity
                #1_evict=`grep "l1d.sim_evict="|awk '{print $2;}'`

                #llc_mpki=`grep "Final:" ${f} -A 2|awk '{print $9;}'`
                #echo "IPC=${ipc} (${filename}), IPC_LRU=${ipc_LRU} (${LRU_f}), Sp=${speedup}"
                
                if [ ! -f ${speedup_output_file} ] ; then
                    echo "trace,prefetcher,replpol,inclusivity,speedup" > ${speedup_output_file}
                fi

#                if [[ ${f} != *"-lru"* ]] ; then
                    # SPEEDUP
                    echo "${trace},${pf},${reppol},inclusive,${speedup_inc}" >> ${speedup_output_file}
                    echo "${trace},${pf},${reppol},exclusive,${speedup_exc}" >> ${speedup_output_file}
                    #echo "${trace},${pf},${reppol},${speedup}"
#                fi

                # IPC
                #if [ ! -f ${OUTPUT_IPC}_${pf}.csv ] ; then
                #    echo "trace,prefetcher,replpol,ipc" > ${OUTPUT_IPC}_${pf}.csv
                #fi
                #echo "${trace},${pf},${reppol},${ipc}" >> ${OUTPUT_IPC}_${pf}.csv

                # geomean
                #if [ $(echo "${ipc} > 0"|bc) -eq 1 ] ; then
                    #prev_sppr_inc=${speedup_prod}
                    #prev_sppr_exc=${speedup_prod}
                    speedup_prod_inc=`echo "scale=${decimals}; ${speedup_inc}*${speedup_prod_inc}"|bc`
                    speedup_prod_exc=`echo "scale=${decimals}; ${speedup_exc}*${speedup_prod_exc}"|bc`

                    #echo "Speedup_prod_inc= ${speedup_prod_inc}"
                    #echo "speedup_prod_exc= ${speedup_prod_exc}"
                #fi


                i=$((i+1))
                ntrpf=$((ntrpf+1))
            else
                echo "Missing: ${f}"
            fi
            n=$((n+1))
            fi
            fi
            fi
            fi
            fi
            #fi
        done < ${tracelist}
    # geomean inc
    geomean_inc="Error"
    if [ $(echo "${speedup_prod_inc} >= 0"|bc) -eq 1 ] ; then
        geomean_inc=`awk -v var1="${speedup_prod_inc}" -v var2="$ntrpf" 'BEGIN { printf "%.17g\n", var1^(1/var2)  }'`
    fi
    number='^[0-9]+([.][0-9]+)?$'
    if ! [[ ${geomean_inc} =~ ${number} ]] ; then
        echo "**** Error in geomean for ${PREFETCHERS[$pr]}+${REPLPOLS[$re]}, speedup_prod_inc=${speedup_prod_inc}, geomean=${geomean_inc}"
        exit
    fi
    echo "geomean,${pf},${reppol},inclusive,${geomean_inc}" >> ${speedup_output_file}
    echo "====Geomean of INCLUSIVE with ${pf} and ${reppol} is: geomean=${geomean_inc}"
    speedup_prod_inc=1

    # geomean exc
    geomean_exc="Error"
    if [ $(echo "${speedup_prod_exc} >= 0"|bc) -eq 1 ] ; then
        geomean_exc=`awk -v var1="${speedup_prod_exc}" -v var2="$ntrpf" 'BEGIN { printf "%.17g\n", var1^(1/var2)  }'`
    fi
    number='^[0-9]+([.][0-9]+)?$'
    if ! [[ ${geomean_exc} =~ ${number} ]] ; then
        echo "**** Error in geomean for ${PREFETCHERS[$pr]}+${REPLPOLS[$re]}, speedup_prod_exc=${speedup_prod_exc}, geomean=${geomean_exc}"
        exit
    fi
    echo "geomean,${pf},${reppol},exclusive,${geomean_exc}" >> ${speedup_output_file}
    echo "====Geomean of EXCLUSIVE with ${pf} and ${reppol} is: geomean=${geomean_exc}"
    speedup_prod_exc=1
    ntrpf=0
    done
done


echo "Finished ${i} out of ${n}."
