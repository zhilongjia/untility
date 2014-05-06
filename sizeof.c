/* sizeof.c */

#include <stdio.h>
#include <limits.h>
#include <float.h>

int main(int argc, char *argv[])
{
    printf("sizeof(signed char):         %d\n", sizeof(signed char));
    printf("sizeof(unsigned char):       %d\n", sizeof(unsigned char));
    printf("sizeof(int):                 %d\n", sizeof(int));
    printf("sizeof(signed short int):    %d\n", sizeof(signed short int));
    printf("sizeof(unsigned short int):  %d\n", sizeof(unsigned short int));
    printf("sizeof(signed long int):     %d\n", sizeof(signed long int));
    printf("sizeof(unsigned long int):   %d\n", sizeof(unsigned long int));
    printf("sizeof(float):               %d\n", sizeof(float));
    printf("sizeof(double):              %d\n", sizeof(double));
    printf("sizeof(long double):         %d\n", sizeof(long double));

    printf("CHAR_BIT:   %d\n",  CHAR_BIT);
    printf("CHAR_MAX:   %d\n",  CHAR_MAX);
    printf("UCHAR_MAX:  %u\n",  UCHAR_MAX);
    printf("SCHAR_MAX:  %d\n",  SCHAR_MAX);
    printf("CHAR_MIN:   %d\n",  CHAR_MIN);
    printf("SCHAR_MIN:  %hd\n", SCHAR_MIN);
    printf("INT_MAX:    %d\n",  INT_MAX);
    printf("INT_MIN:    %d\n",  INT_MIN);
    printf("SHRT_MAX:   %hd\n", SHRT_MAX);
    printf("SHRT_MIN:   %hd\n", SHRT_MIN);
    printf("LONG_MAX:   %ld\n", LONG_MAX);
    printf("LONG_MIN:   %ld\n", LONG_MIN);
    printf("UINT_MAX:   %u\n",  UINT_MAX);
    printf("ULONG_MAX:  %lu\n", ULONG_MAX);
    printf("USHRT_MAX:  %hu\n", USHRT_MAX);
    printf("FLT_MAX:    %E\n",  FLT_MAX);

    return 0;
}
