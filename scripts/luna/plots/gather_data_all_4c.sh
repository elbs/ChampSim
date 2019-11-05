#!/bin/bash

if [ $# -ne 2 ]
then
    echo "Usage: $0 traces output_dir"
    exit
fi

traces=$1
resdir=/scratch/user/luna.backes/results
ofile=$2

echo "traces resdir $resdir, output_file $ofile"

L1PREFS=( no next_line )
L2PREFS=( no ip_stride next_line daampm bop kpcp ) #next_line
REPPOLS=( lru eaf ship drrip kpcr ) #ship  lru plru smdpp srrip drrip) # ship)
#L1PREFS=( next_line )
#L2PREFS=( bop ) #next_line
#REPPOLS=( kpcr ) #ship  lru plru smdpp srrip drrip) # ship)
INCS=( NON INC EXC )
#MIX1=( astar bwaves bzip2 cactusADM mcf ) # gromacs
NMIXES=$(wc -l $traces)
echo nmixes=${NMIXES}

echo "trace,l1p,l2p,repl,inc,metric,value" > ${ofile}

#for trace1 in ${MIX1[@]}
#for ((mix=1;mix<=20;mix++))
for ((mix=1; mix <= 4; mix++))
do
    for l1p in ${L1PREFS[@]}
    do
        for l2p in ${L2PREFS[@]}
        do
            for re in ${REPPOLS[@]}
            do
                for inc in ${INCS[@]}
                do
                    ifiles=`ls ${resdir}/4cores/${inc}/mix${mix}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}-4core.*`
                    #ifiles=`ls ${resdir}/multicore/4cores/${inc}/mix${mix}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}-4core.*`
                    for ifile in ${ifiles[@]}
                    do
                        if [ ! -f "${ifile}" ]
                        then
                            echo "File does not exist: ${ifile}"
                            exit
                        fi
                        if ! grep -q "ChampSim completed all CPUs" ${ifile}
                        then
                            echo "Sim not completed successfully: ${ifile}"
                            #exit
                        fi
                        # mix
                        app1=`grep "CPU 0 runs" ${ifile}|cut -d' ' -f4 |cut -d'/' -f8|cut -d'.' -f2|cut -d'_' -f1` #`awk -F[./] '/CPU 0 runs/ {print $9}' ${ifile}`
                        app2=`grep "CPU 1 runs" ${ifile}|cut -d' ' -f4 |cut -d'/' -f8|cut -d'.' -f2|cut -d'_' -f1` #`awk -F[./] '/CPU 1 runs/ {print $7}' ${ifile}`
                        app3=`grep "CPU 2 runs" ${ifile}|cut -d' ' -f4 |cut -d'/' -f8|cut -d'.' -f2|cut -d'_' -f1` #`awk -F[./] '/CPU 2 runs/ {print $7}' ${ifile}`
                        app4=`grep "CPU 3 runs" ${ifile}|cut -d' ' -f4 |cut -d'/' -f8|cut -d'.' -f2|cut -d'_' -f1` #`awk -F[./] '/CPU 3 runs/ {print $7}' ${ifile}`

                        # single core benchs
                        app1single=`ls ${resdir}/multicore/1cores/${inc}/${app1}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}*`
                        app2single=`ls ${resdir}/multicore/1cores/${inc}/${app2}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}*`
                        app3single=`ls ${resdir}/multicore/1cores/${inc}/${app3}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}*`
                        app4single=`ls ${resdir}/multicore/1cores/${inc}/${app4}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}*`

                        #echo "mix=$mix app4=$app4 vs app1single=${app4single}"
                        

                        # metrics
                        ipc1=`awk '/CPU 0 cumulative IPC:/ {print $5;exit}' ${ifile}`
                        ipc2=`awk '/CPU 1 cumulative IPC:/ {print $5;exit}' ${ifile}`
                        ipc3=`awk '/CPU 2 cumulative IPC:/ {print $5;exit}' ${ifile}`
                        ipc4=`awk '/CPU 3 cumulative IPC:/ {print $5;exit}' ${ifile}`
                        cycles=`awk '/CPU 0 cumulative IPC:/ {print $9;exit}' ${ifile}`

                        # metrics single core
                        ipc1single=`awk '/CPU 0 cumulative IPC:/ {print $5;exit}' ${app1single}`
                        ipc2single=`awk '/CPU 0 cumulative IPC:/ {print $5;exit}' ${app2single}`
                        ipc3single=`awk '/CPU 0 cumulative IPC:/ {print $5;exit}' ${app3single}`
                        ipc4single=`awk '/CPU 0 cumulative IPC:/ {print $5;exit}' ${app4single}`
                        #echo "ipc1=$ipc1    ipc1single=${ipc1single}"
                        #echo "ipc2=$ipc2    ipc2single=${ipc2single}"
                        #echo "ipc3=$ipc3    ipc3single=${ipc3single}"
                        #echo "ipc4=$ipc4    ipc4single=${ipc4single}"

                        test_ipc1=`echo "(${ipc1} / ${ipc1single})"|bc -l`
                        test_ipc2=`echo "(${ipc2} / ${ipc2single})"|bc -l`
                        test_ipc3=`echo "(${ipc3} / ${ipc3single})"|bc -l`
                        test_ipc4=`echo "(${ipc4} / ${ipc4single})"|bc -l`
                        #echo "test_ipc1=${test_ipc1}"
                        #echo "test_ipc2=${test_ipc2}"
                        #echo "test_ipc3=${test_ipc3}"
                        #echo "test_ipc4=${test_ipc4}"
                        weighted_ipc=`echo "(${ipc1} / ${ipc1single}) + (${ipc2} / ${ipc2single}) + (${ipc3} / ${ipc3single}) + (${ipc4}/${ipc4single})"|bc -l`
                        ipc=${weighted_ipc}
                        #echo "weighted_ipc=${weighted_ipc}"
                        #ins1=`awk '/CPU 0 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        #ins2=`awk '/CPU 1 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        #ins3=`awk '/CPU 2 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        #ins4=`awk '/CPU 3 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        #ipc=`echo "($ins1 + $ins2 + $ins3 + $ins4) / ($cycles * 4)" | bc -l`
                        llc_mpki=`awk '/llc.mpki/ {print $2}' ${ifile}`
                        l3_evict=`awk '/llc.sim_evict=/ {print $2}' ${ifile}`

                        echo "mix${mix},${l1p},${l2p},${re},${inc},ipc,${ipc}" >> ${ofile}
                        echo "mix${mix},${l1p},${l2p},${re},${inc},llc_mpki,${llc_mpki}" >> ${ofile}
                        echo "mix${mix},${l1p},${l2p},${re},${inc},l3_evict,${l3_evict}" >> ${ofile}
                        #echo "mix${mix},${l1p},${l2p},${re},${inc},ipc,${ipc}"
                        #echo "${trace},${l1p},${l2p},${re},${inc},cycles,${cycles}" >> ${ofile}
                        #echo "${trace},${l1p},${l2p},${re},${inc},l1_evict,${l1_evict}" >> ${ofile}
                        #echo "${trace},${l1p},${l2p},${re},${inc},llc_mpki,${llc_mpki}" >> ${ofile}
                    done
                done
            done
        done
    done
done
