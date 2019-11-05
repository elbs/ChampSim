#!/bin/bash

source common.cfg

if [ "$#" -lt 3 ]; then
    echo "Usage: bash $0 {binary} {n_line} {INCLUSION} [option]"
    echo
    echo "    * binary: name of the binary compiled that is located in ./bin/"
    echo
    echo "    * n_line: number of line on the file"
    exit
fi

binary=${1}
n_warm=2000
n_sim=10000000 #800000 #1B
num=${2}
INCLUSION=${3}
option= #${5}

SIM_LIST=${TRACELISTS}/4core_list1.txt

trace1=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $1}'`
trace2=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $2}'`
trace3=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $3}'`
trace4=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $4}'`

binary_running_path=${BINARY_DIR}
#binary_running_path=${BINARY_DIR}/running/${INCLUSION}
results_dir=${RESULTS_DIR}/${INCLUSION}
mkdir -p ${results_dir}

echo "Results: ${results_dir}/mix${num}-${binary}${option}.txt"

#valgrind ${binary_running_path}/${binary} -warmup_instructions ${n_warm} -simulation_instructions ${n_sim} ${option} -traces ${TRACE_DIR}/${trace1}.trace.gz ${TRACE_DIR}/${trace2}.trace.gz ${TRACE_DIR}/${trace3}.trace.gz ${TRACE_DIR}/${trace4}.trace.gz
(/usr/bin/time -v ${binary_running_path}/${binary} -warmup_instructions ${n_warm} -simulation_instructions ${n_sim} ${option} -traces ${TRACE_DIR}/${trace1}.trace.gz ${TRACE_DIR}/${trace2}.trace.gz ${TRACE_DIR}/${trace3}.trace.gz ${TRACE_DIR}/${trace4}.trace.gz) &> ${results_dir}/mix${num}-${binary}${option}.txt
