#! /usr/bin/awk -f
#print the first i (default 5) columns and rows
#USAGE of EXAMPLE
#cuthead.awk i=5 filename
BEGIN{i=i?i:5}
NR<=i{for  (j=1;j<=i;j++) 
      printf ("%s\t", $j); 
      printf "\n"}
