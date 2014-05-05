#! /bin/bash
#print the last i (default 5) rows inversely and first i columns
#USAGE:
#cuttail filename Expected_Num_of_Lines
#cuttail a.dat 10

i=$2
tac $1 | awk 'NR<=i{for (j=1;j<=i;j++) printf ("%s\t", $j); printf "\n"}' i=${i:=5} -
