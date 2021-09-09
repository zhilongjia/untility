#! /usr/bin/bash

# parameter parsing
while getopts ":d:t:ch" opt; do
  case ${opt} in
    d )
      dir=$OPTARG
      ;;
    # s )
    #   target=$OPTARG
    #   ;;
    t )
      topN=$OPTARG
      ;;  
    c )
      ignorecase=0
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
    h )
      echo "Usage:"
      echo "search_txt_in_image.sh: search txt in images."
      echo "========================================================"
      echo "-d the dir of figures (should be full paths)"
      # echo "-s the searching target."
      echo "-t topN images to show. Default 5"
      echo "-c CASE sensitive. Donot use it if wanting IGNORECASE."
      echo "========================================================"
      echo "seach txt in images after OCR the images with -d parameter."
      echo "The database of the text from image is located ~/.search_txt_in_image.db "
      echo "tesseract, fim should be installed in advance."
      echo "========================================================"
      echo "examples:"
      echo "search_txt_in_image.sh -d "~/Picutres" "cohort" "
      echo "search_txt_in_image.sh -d "~/Picutres ~/pngs" "cohort" "
      echo "search_txt_in_image.sh cohort"
      echo "search_txt_in_image.sh 'cohort|gene' "
      echo "========================================================"
      echo "author: zhilongjia@qq.com"
      echo "9 Sept. 2021"
      exit 0  
      ;; 
  esac
done
shift $((OPTIND -1))

# THEN, access the positional params
# echo "there are $# positional params remaining. Only the first is used."
# for ((i=1; i<=$#; i++)); do
#   printf "%d\t%s\n" $i "${!i}"
# done
target=$1


##############################################################################################################

# db
search_txt_in_image_db=~/.search_txt_in_image.db

# build the db if -d parameter exist
if [[ -v dir ]]
then
    echo "Starting OCR images..."
    
    imgs=`find $dir -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}'`
    
    # deal with filename with space.
    OIFS="$IFS" ; IFS=$'\n';

    # the number of figures
    imgs1=($imgs)
    line=${#imgs1[@]}
    # echo $line
    line_i=1
    
    temp_figure_file=$(mktemp)
    # touch ${search_txt_in_image_db}
    for img in ${imgs}
    do  
        printf "$line_i / $line :  ${img}\n"

        printf "${img}\t" >> ${temp_figure_file}
        tesseract ${img} - -l eng+chi_sim --oem 3  | tr  '\n' '\t'| tr -d "[:blank:]" >> ${temp_figure_file}
        echo "\n" >> ${temp_figure_file}
        ((line_i++))
    done
    

    cat ${temp_figure_file} >> ${search_txt_in_image_db}
    rm ${temp_figure_file}

    # deduplicates
    sort -u ${search_txt_in_image_db} -o ${search_txt_in_image_db}

    IFS="$OIFS"
fi

echo " # figures: "`wc -l ${search_txt_in_image_db}`
echo "============================================="
##############################################################################################################
# search and show your result.
# use mktemp so the ouput can be cat and view

if [[ -v target ]]
then
    temp_result_file=$(mktemp)

    awk -v target="$target" -v ignorecase="${ignorecase=1}"  'BEGIN{IGNORECASE=ignorecase; FS=OFS="\t"}$0 ~ target{print $1}' ${search_txt_in_image_db} > ${temp_result_file}

    cat ${temp_result_file}
    
    head -${topN=5} ${temp_result_file} | fim -

    rm ${temp_result_file}
fi

