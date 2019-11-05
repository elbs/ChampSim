#!/bin/bash


TRACES=($(ls ${TRACE_DIR}|cut -d'.' -f1|xargs -n1 basename))

if [ "$#" -lt 2 ]; then
    echo "Usage: {binary} {tracelist_file} [option]"
    echo
    echo "    * binary: name of the binary compiled that is located in ./bin/"
    echo
    echo "    * tracelist_file: file containing trace names, one per line"
    echo
    echo "    * options:"
    echo "      - low_bandwidth: Restrict the DRAM bandwidth (default: 1600MT/s bw)"
    echo "      - scramble_loads: Apply more randomness in load/store ordering"
    exit
fi

binary=$1
tracelist=$2
option=$3

while read trace
do
    ./run_1B.sh ${binary} ${trace} ${option} &
done < ${tracelist}
