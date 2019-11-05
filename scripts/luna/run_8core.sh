#!/bin/bash

source common.cfg

if [ "$#" -lt 1 ]; then
    echo "Usage: {binary} {trace} [option]"
    echo
    echo "    * binary: name of the binary compiled that is located in ./bin/"
    echo
    echo "    * n_line: number of line on the file"
    exit
fi

binary=${1}
n_warm=200000000
n_sim=1000000000
num=${2}
option= #${5}

SIM_LIST=${ROOT}/sim_list/8core_list1.txt

trace1=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $1}'`
trace2=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $2}'`
trace3=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $3}'`
trace4=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $4}'`
trace5=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $5}'`
trace6=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $6}'`
trace7=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $7}'`
trace8=`sed -n ''$num'p' ${SIM_LIST} | awk '{print $8}'`

results_dir=${RESULTS_DIR}/results_8core
mkdir -p ${results_dir}

(/usr/bin/time -v ${BINARY_DIR}/${binary} -warmup_instructions ${n_warm} -simulation_instructions ${n_sim} ${option} -traces ${TRACE_DIR}/${trace1}.trace.gz ${TRACE_DIR}/${trace2}.trace.gz ${TRACE_DIR}/${trace3}.trace.gz ${TRACE_DIR}/${trace4}.trace.gz ${TRACE_DIR}/${trace5}.trace.gz ${TRACE_DIR}/${trace6}.trace.gz ${TRACE_DIR}/${trace7}.trace.gz ${TRACE_DIR}/${trace8}.trace.gz) &> ${results_dir}/testmix${num}-${binary}${option}.txt
