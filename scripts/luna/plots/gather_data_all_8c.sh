#!/bin/bash

if [ $# -ne 2 ]
then
    echo "Usage: $0 result_dir output_dir"
    exit
fi

#traces=$1
resdir=$1
ofile=$2

echo "traces resdir $resdir, ofile $ofile"

L1PREFS=( no next_line )
L2PREFS=( no ip_stride next_line daampm bop ) #kpcp ) #next_line
REPPOLS=( lru eaf ship drrip ) #kpcr ) #ship  lru plru smdpp srrip drrip) # ship)
INCS=( INC NON EXC )
MIX1=( mix1 mix2 mix3 mix4 mix5 ) # gromacs
#MIX1=( astar bwaves bzip2 cactusADM mcf ) # gromacs

echo "trace,l1p,l2p,repl,inc,metric,value" > ${ofile}

for mix in ${MIX1[@]}
do
    for l1p in ${L1PREFS[@]}
    do
        for l2p in ${L2PREFS[@]}
        do
            for re in ${REPPOLS[@]}
            do
                for inc in ${INCS[@]}
                do
                    ifiles=`ls ${resdir}/${inc}/${mix}_champsim-${inc}-perceptron-${l1p}-${l2p}-${re}-8core.*`
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
                        ## mix
                        #app1=`awk -F[./] '/CPU 0 runs/ {print $7}' ${ifile}`
                        #app2=`awk -F[./] '/CPU 1 runs/ {print $7}' ${ifile}`
                        #app3=`awk -F[./] '/CPU 2 runs/ {print $7}' ${ifile}`
                        #app4=`awk -F[./] '/CPU 3 runs/ {print $7}' ${ifile}`
                        #app5=`awk -F[./] '/CPU 4 runs/ {print $7}' ${ifile}`
                        #app6=`awk -F[./] '/CPU 5 runs/ {print $7}' ${ifile}`
                        #app7=`awk -F[./] '/CPU 6 runs/ {print $7}' ${ifile}`
                        #app8=`awk -F[./] '/CPU 7 runs/ {print $7}' ${ifile}`
                        # metrics
                        ins1=`awk '/CPU 0 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins2=`awk '/CPU 1 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins3=`awk '/CPU 2 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins4=`awk '/CPU 3 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins5=`awk '/CPU 4 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins6=`awk '/CPU 5 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins7=`awk '/CPU 6 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        ins8=`awk '/CPU 7 cumulative IPC:/ {print $7;exit}' ${ifile}`
                        cycles=`awk '/CPU 0 cumulative IPC:/ {print $9;exit}' ${ifile}`

                        ipc=`echo "($ins1 + $ins2 + $ins3 + $ins4 + $ins5 + $ins6 + $ins7 + $ins8) / ($cycles * 8)" | bc -l`

                        echo "${mix},${l1p},${l2p},${re},${inc},ipc,${ipc}" >> ${ofile}
                        #echo "${mix},${l1p},${l2p},${re},${inc},cycles,${cycles}" >> ${ofile}
                        #echo "${mix},${l1p},${l2p},${re},${inc},l1_evict,${l1_evict}" >> ${ofile}
                        #echo "${mix},${l1p},${l2p},${re},${inc},l2_evict,${l2_evict}" >> ${ofile}
                        #echo "${mix},${l1p},${l2p},${re},${inc},llc_evict,${llc_evict}" >> ${ofile}
                        #echo "${mix},${l1p},${l2p},${re},${inc},llc_mpki,${llc_mpki}" >> ${ofile}
                    done
                done
            done
        done
    done
done
