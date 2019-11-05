#!/bin/bash

#MACHINES=(cajeta chalupa churro flauta jicaleta oblea pozole puchepo tamal torta tortilla)
MACHINES=( chalupa cajeta churro jicaleta oblea pozole puchepo tamal torta semita turco cabron manzana tresleches flauta antojito empanada nopalito guacamole flan mole queso ) #tortilla


for m in "${MACHINES[@]}"
do
    ssh -n  ${m} "pkill -u lbackes"
done
