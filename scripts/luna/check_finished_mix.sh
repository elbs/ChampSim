cd results_jc
test1=${1}.txt

num=0
while [ $num -lt 70 ]; 
do
    let num=num+1
    check=`grep "Final stats Core: 0" ./mix${num}-${test1}`
    if [ "$check" ]; then
        echo "mix${num}-${test1} finished"
    fi
done 
