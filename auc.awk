#!/usr/bin/awk -f
#./auc.awk <(sort -nk2 real_prob.csv )

BEGIN {
        FS = OFS = "\t";
        pos_label = 1;
        x0 = x = y0 = y = 0;
        auc = 0;
}
{
        label = $2;
        if(label == pos_label) 
            y++;
        else 
            x++;
        auc+=(x-x0)*(y+y0);
        x0 = x;
        y0 = y;
}
END {
    auc+=(x-x0)*(y+y0);
    auc/=2*x*y;
    print auc;
}