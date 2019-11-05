# Run 4-core experiments (mix11 ~ mix20) registed in sim_list/4core_workloads.txt 
# Warmup 10M instructions and run 50M detailed instructions
# Usage: ./roll_mix11-20.sh no-lru-4core

binary=$1
option=$2
num=10

while [ $num -lt 20 ]
do
    ((num++))
    ./run_4core.sh ${binary} 10 50 ${num} ${option} &
done
