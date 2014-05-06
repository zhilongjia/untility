#! /usr/bin/awk -f
#print NR, NF
BEGIN{FS=" ";print "row No. and col No." }
END{print NR, NF} 
