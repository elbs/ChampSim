#!/bin/bash

source common.cfg

#TRACE_DIR=/filer/tmp/eteran/new_traces/champsim_trace
TRACES=($(ls ${TRACE_DIR}|cut -d'.' -f1|xargs -n1 basename))

if [ "$#" -lt 2 ]; then
    echo "Usage: {binary} {trace} [option]"
    echo
    echo "    * binary: name of the binary compiled that is located in ./bin/"
    echo
    echo "    * trace: name of the trace from the trace directory ${TRACE_DIR} that we want to simulate"
    echo "         - Possible values: ${TRACES[*]}"
    echo
    echo "    * options:"
    echo "      - low_bandwidth: Restrict the DRAM bandwidth (default: 1600MT/s bw)"
    echo "      - scramble_loads: Apply more randomness in load/store ordering"
    exit
fi

RESULTS="${RESULTS_DIR}/test"
mkdir -p ${RESULTS}

binary=${1}
trace="603.bwaves_s-1080B.champsimtrace.xz" #${2}
option=${3}
warmup_instr=2000
sim_instr=10000
filename=${2}-${1}${3}

hostname
echo "Filename in results folder: ${RESULTS}/${filename}.txt"


(/usr/bin/time -v ${BINARY_DIR}/${binary} -warmup_instructions ${warmup_instr} -simulation_instructions ${sim_instr} ${option} -traces ${TRACE_DIR}/${trace}) &> ${RESULTS}/${filename}.txt
