#! /usr/bin/awk -f
#print NR, NF
# examples:
#dim.awk -F"," fn
BEGIN{ print "row No. and col No." }
END{print NR, NF} 
