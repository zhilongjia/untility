#! /usr/bin/awk -f
#print NR, NF
BEGIN{print "row No. and col No." }
END{print NR, NF} 
