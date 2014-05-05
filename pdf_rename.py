#! /usr/bin/python
'''Short description here for this script
Pdf rename
by Zhilong Jia <zhilongjia@gmail.com>,
Copyright @ 2012, All Rights Reserved.
'''
Author  = 'Zhilong Jia <zhilongjia@gmail.com> CZlab, BIRM, China'
Date    = 'Apr-5-2012'
License = 'GPL v3'
Version = '%(prog)s version 1.0'



from pyPdf import PdfFileReader
import argparse
import os


def get_args():
    '''Handle options'''
    parser = argparse.ArgumentParser(description='obtain the pdf file name')
    parser.add_argument('filename', type=str, nargs='?')
    args = parser.parse_args()
    return args


def get_name(filename):
    '''get pdf name'''
    try:
        file_obj = file(filename, "rb")
        input1 = PdfFileReader(file_obj)
        title = input1.getDocumentInfo().title
	subject = input1.getDocumentInfo().subject
	if title:
	    if not subject:
		new_name ="{0}.pdf".format(str(title))
	    else:
                new_name = ("{0}_{1}.pdf".format(str(title), str(subject).replace("/", "-").replace(" ", "_")))
	else:
	    new_name = filename
	file_obj.close()
    except:
	print "NO CHANGES!"
    return new_name


def rename(filename, new_name):
    '''rename pdf'''
    print("Original Name:{0}".format(filename))
    print("New Name:{0}".format(new_name))
    os.rename(filename, new_name)
    return None


def main():
    args = get_args()
    filename = args.filename
    new_name = get_name(filename)
    rename(filename, new_name)


if __name__ == "__main__":
    main()
