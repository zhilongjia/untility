#!/home/jiazl/python

from Bio import SeqIO
from Bio.Seq import translate
import argparse
from sys import stdout


def parse_arguments():
    parser = argparse.ArgumentParser(description="translate DNA to Protein.", epilog="Report %(prog)s bugs to zhilongjia@gmail.com, please.")
    parser.add_argument('i', type=str, help='DNA/RNA fasta file.')
    parser.add_argument('-o', nargs='?', type=argparse.FileType('w'),default=stdout, help='outfile. Default:stdout.')
    parser.add_argument('-v', '--version', action='version', version='%(prog)s 1.0.')
    args = parser.parse_args()
    return args


def translate_fasta(fastafile, outfile):
    for record in SeqIO.parse(fastafile, "fasta"):
         outfile.write(">" + record.id + "\n")
         outfile.write(translate(str(record.seq))[:-1] + "\n")
    return None


def main():
    args = parse_arguments()
    translate_fasta(args.i, args.o)


if __name__ == '__main__':
    main()
