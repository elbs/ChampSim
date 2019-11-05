#!/bin/bash

source common.cfg

#TRACE_DIR=/filer/tmp/eteran/new_traces/champsim_trace
TRACES=($(ls ${TRACE_DIR}))
#TRACES=($(ls ${TRACE_DIR}|cut -d'.' -f1|xargs -n1 basename))

if [ "$#" -lt 1 ]; then
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

RESULTS_1B=${RESULTS_DIR}/results_1B
mkdir -p ${RESULTS_1B}

binary=${1}
trace=605.mcf_s-665B.champsimtrace.xz
#trace=602.gcc_s-734B.champsimtrace.xz
#trace=607.cactuBSSN_s-2421B.champsimtrace.xz #${2}
#option=${3}
warmup_instr=200000 #20000
sim_instr=2000000 #50000000 #1000000

#Full run
#warmup_instr=200000000
#sim_instr=1000000000
filename=mcf_${1}
#filename=${2}-${1}${3}

hostname
echo "Filename in results folder: ${RESULTS_DIR}/results_1B/${filename}.txt"


(/usr/bin/time -v ${BINARY_DIR}/${binary} -warmup_instructions ${warmup_instr} -simulation_instructions ${sim_instr} ${option} -traces ${TRACE_DIR}/${trace}) &> ${RESULTS_1B}/${filename}.txt
#valgrind --track-origins=yes ${BINARY_DIR}/${binary} -warmup_instructions ${warmup_instr} -simulation_instructions ${sim_instr} ${option} -traces ${TRACE_DIR}/${trace} 
