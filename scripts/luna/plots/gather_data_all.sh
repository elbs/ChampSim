#!/bin/bash

if [ $# -lt 2 ]
then
    echo "Usage: $0 result_dir output_file"
    exit
fi

#traces=$1
resdir=$1
ofile=$2
tracelist_dir=/home/luna.backes/ChampSim/sim_list

TRACELISTS=( spec2017_benchs.txt ) #spec06.txt other_benchs.txt )

echo "traces $1 resdir $resdir, ofile $ofile"

L1PREFS=( no ) #next_line )
L2PREFS=( no ) #no ip_stride kpcp ) #next_line daampm bop kpcp )
REPPOLS=( lru ship ) #lru #eaf ship drrip kpcr ) #lru plru smdpp srrip drrip) # ship)
INCS=( EXC ) #INC NON EXC ) #( INC NON EXC )
PATTERNS=( NONE REFTRACE FILL_PC LAST_PC )
NCORES=1

echo "suite,trace,l1p,l2p,repl,inc,pattern,metric,value" > ${ofile}

for traces in ${TRACELISTS[@]}
do
    trace_file=${tracelist_dir}/${traces}
    while read trace
    do
        echo "trace: $trace"
        for l1p in ${L1PREFS[@]}
        do
            for l2p in ${L2PREFS[@]}
            do
                for re in ${REPPOLS[@]}
                do
                    for inc in ${INCS[@]}
                    do
                        for pattern in ${PATTERNS[@]}
                        do
                            if [ ${NCORES} -eq 1 ] ; then
                                trace_name=`echo ${trace}|cut -d'.' -f2|cut -d'_' -f1`
                            elif [ "${NCORES}" -eq 8 ] ; then
                                trace_name="mix${i}"
                            fi
    
                            #ifile=`ls ${resdir}/${inc}/${trace_name}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}-1core.*`
                            for ifile in ${resdir}/${inc}/${trace_name}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}-1core-${pattern}.*
                            do
                                if [ ${re} = "lru" ] && [ ${pattern} != "NON" ]; then 
                                    break
                                fi
                                if [ ! -f "${ifile}" ]
                                then
                                    echo "File does not exist: ${ifile}"
                                    exit
                                fi
                                if ! grep -q "ChampSim completed all CPUs" ${ifile}
                                then
                                    echo "Sim not completed successfully: ${ifile}"
                                    #exit
                                    break
                                fi
                                if   [[ "$traces" == "spec06.txt" ]] && grep -q "speccpu2017/xz/set/1" $ifile; then
                                    suite=spec06
                                    for base in ${resdir}/${inc}/${trace_name}_champsim-EXC-perceptron-no-no-lru-1core-NONE*
                                    do
                                        if grep -q "speccpu2017/xz/set/1" $base; then
                                            baseline=${base}
                                        fi
                                    done
                                elif [[ "$traces" == "spec2017_benchs.txt" ]] && grep -q "speccpu2017/xz/set/6" $ifile; then 
                                    suite=spec17
                                    for base in ${resdir}/${inc}/${trace_name}_champsim-EXC-perceptron-no-no-lru-1core-NONE*
                                    do
                                        if grep -q "speccpu2017/xz/set/6" $base; then
                                            baseline=${base}
                                        fi
                                    done
                                elif grep -q "speccpu2017/xz/set/0" $ifile; then
                                    if grep -q "speccpu2017/xz/set/003" $ifile; then
                                        suite=ml
                                        baseline=`ls ${resdir}/${inc}/${trace_name}_champsim-EXC-perceptron-no-no-lru-1core-NONE.*`
                                    else
                                        suite=cloud
                                        baseline=`ls ${resdir}/${inc}/${trace_name}_champsim-EXC-perceptron-no-no-lru-1core-NONE.*`
                                    fi
                                else
                                    #echo "*******error? file: $ifile"
                                    continue
                                fi
                                trace_name_out=${trace_name}_${suite}
    
                                # metrics
                                ipc=`awk '/CPU 0 cumulative IPC:/ {print $5}' ${ifile}`
                                ipc_base=`awk '/CPU 0 cumulative IPC:/ {print $5}' ${baseline}`
                                cycles=`awk '/CPU 0 cumulative IPC:/ {print $9}' ${ifile}`
                                l1_evict=`awk '/l1d.sim_evict=/ {print $2}' ${ifile}`
                                l2_evict=`awk '/l2c.sim_evict=/ {print $2}' ${ifile}`
                                l3_evict=`awk '/llc.sim_evict=/ {print $2}' ${ifile}`
                                l1_evict_inc=`awk '/l1d.sim_evict_inc=/ {print $2}' ${ifile}`
                                l2_evict_inc=`awk '/l2c.sim_evict_inc=/ {print $2}' ${ifile}`
                                l1d_mpki=`awk '/l1d.mpki/ {print $2}' ${ifile}`
                                l2c_mpki=`awk '/l2c.mpki/ {print $2}' ${ifile}`
                                llc_mpki=`awk '/llc.mpki/ {print $2}' ${ifile}`
                                llc_misses=`awk '/llc.misses=/ {print $2}' ${ifile}`
                                speedup=$(bc <<< "scale=4; ${ipc}/${ipc_base}")
    
                                
                                #echo "ipc=${ipc} ipc_base=${ipc_base}"
                                #echo "$ifile    vs    ${baseline}"
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},speedup,${speedup}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},ipc,${ipc}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},cycles,${cycles}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l1_evict,${l1_evict}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l2_evict,${l2_evict}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l3_evict,${l3_evict}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l1d_mpki,${l1d_mpki}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l2c_mpki,${l2c_mpki}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},llc_mpki,${llc_mpki}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},llc_misses,${llc_misses}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l1_evict_inc,${l1_evict_inc}" >> ${ofile}
                                echo "${suite},${trace_name_out},${l1p},${l2p},${re},${inc},${pattern},l2_evict_inc,${l2_evict_inc}" >> ${ofile}
                            done
                        done
                    done
                done
            done
        done
    done < ${trace_file}
done
