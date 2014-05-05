#! /bin/bash
awk '{for (i=1; i<=NF; i++) data[NR,i]=$i}END{for (j=1; j<=NF; j++) {for (k=1; k<=NR; k++) printf "\t" data[k,j]; printf "\n"}}' $1 | sed 's/\t//'
