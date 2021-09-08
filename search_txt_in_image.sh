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
      echo "search_txt_in_image.sh"
      echo "seach txt in images after OCR the images with -d parameter."
      echo "-d the dir of figures (should be full paths)"
      echo "-s the searching target."
      echo "-t topN images to show"
      echo "-c CASE sensitive. Donot use it if wanting IGNORECASE."
      echo "========================================================"
      echo "The database of the text from image is located ~/.search_txt_in_image.db "
      echo "tesseract, fim should be installed in advance."
      echo "========================================================"
      echo "examples:"
      echo "search_txt_in_image.sh -d ~/Picutres "cohort" "
      echo "search_txt_in_image.sh cohort"
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
echo "Starting OCR images..."
# db
search_txt_in_image_db=~/.search_txt_in_image.db

# build the db if -d parameter exist
if [[ -v dir ]]
then
    imgs=`find $dir -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}'`
    
    # the number of figures
    imgs1=($imgs)
    line=${#imgs1[@]}
    # echo $line
    line_i=1
    
    # touch ${search_txt_in_image_db}
    for img in ${imgs}
    do
        printf "$line_i / $line :  ${img}\n"

        printf "${img}\t" >> ${search_txt_in_image_db}
        tesseract ${img} - -l eng+chi_sim --oem 1  | tr  '\n' '\t' >> ${search_txt_in_image_db}
        echo "\n" >> ${search_txt_in_image_db}
        ((line_i++))
    done
    
    # deduplicates
    sort -u ${search_txt_in_image_db} -o ${search_txt_in_image_db}

fi

echo " #figures: "`wc -l ${search_txt_in_image_db}`

##############################################################################################################
# search and show your result.
awk -v target="$target" -v ignorecase="${ignorecase=1}"  'BEGIN{IGNORECASE=ignorecase}$0 ~ target{print $1}' ${search_txt_in_image_db} | head -${topN=5} | fim -

