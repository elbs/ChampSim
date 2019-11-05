#!/bin/bash

source common.cfg

#TRACE_DIR=/filer/tmp/eteran/new_traces/champsim_trace
TRACES=($(ls ${TRACE_DIR}|cut -d'.' -f1|xargs -n1 basename))

if [ "$#" -lt 3 ]; then
    echo "Usage: {binary} {trace} {output_folder} [option]"
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

result_folder=${3}

RESULTS_1B=${RESULTS_DIR}/${result_folder}
mkdir -p ${RESULTS_1B}

binary=${1}
trace=${2}
option=${4}
warmup_instr=200000000
sim_instr=1000000000
filename=${2}_${1}

binary_running_path=${BINARY_DIR}/running/${result_folder}

hostname
echo "Filename in results folder: ${filename}"


(/usr/bin/time -v ${binary_running_path}/${binary} -warmup_instructions ${warmup_instr} -simulation_instructions ${sim_instr} ${option} -traces ${TRACE_DIR}/${trace}.trace.gz) &> ${RESULTS_1B}/${filename}.txt
