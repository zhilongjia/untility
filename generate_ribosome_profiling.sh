#! /bin/bash

function cmd_there(){
# is there the cmd
    command -v bamToBed >/dev/null || (echo "Please visite the http://code.google.com/p/bedtools and install the bedtools software." && exit 1) 
}
cmd_there


#DEBUG="true"
DEBUG()  
   {  
    if [ "$DEBUG" = "true" ]  
    then  
        $@  
    fi  
    }  


function get_help(){
# show the help page
    echo "USAGE :"
    echo "-i filename : input bam file or bed file, such as accepted_hits.bam"
    echo "-d dirname : temp file output Dir, default value is ./temp"
    echo "-h or -help : show this help page"
    echo "-g map_genome.gff/gtf/bed : the mapping genome gtf/gff/bed file, such as gene.gtf. The gff format is gff version3. You can get the gtf format from http://genome.ucsc.edu/cgi-bin/hgTables?org=human."
    echo "-n value : value should be divided by 3. this means keep [value] nt before the start site of CDS. In other words, the [value] nt in the 5'-UTR should be kelp"
    echo ""
    echo "Report $0 bugs to zhilongjia@gmail.com"
}


# there must be options. 
if [ X = "X$1" ]
then
    get_help
    exit 1
fi


while getopts ":i:d:g:n:h" optname
#parse the options
  do
    case "$optname" in
      "i")
	bamfile=$OPTARG
        echo "The bam/bed file is $OPTARG."
        ;;
      "d")
	temp_dir=$OPTARG
        echo "The temp output directory is $OPTARG"
        ;;
      "g")
	gtf_or_gff_file=$OPTARG
	echo "The gtf/gff/bed file is $OPTARG"
        ;;
      "n")
	  precodonN=$OPTARG
	  if [ precodonN%3 -eq 0 ]
	  then
	      echo "keep $OPTARG nt before the start codon of CDSes"
	  else
	      echo "-n parament should be divided exactly by 3"
	  fi
	  ;;
      "?")
        echo "invalid option -$OPTARG"
	echo "Try $0 -h for more information."
	exit 0
        ;;
      ":")
	if [ "X$OPTARG" = "Xd" ]
	then
	    temp_dir="temp_rp"
	    echo "The temp putput directory is ./temp_rp"
	elif [ "X$OPTARG" = "Xn" ]
        then
	    precodonN=15
	    echo "keep 15 nt before the start codon of CDSes"
	else
             echo "No argument value for option $OPTARG"
        fi
        ;;
      "h"|"help")
	  get_help
	  exit 0
	;;
      *)
        echo "Unknown error while processing options"
	exit 1
        ;;
    esac
  done

# creat a temp directory
DEBUG set -x
if [ ! -d ${temp_dir:=temp_rp} ]
then
    mkdir $temp_dir
fi

precodonN=${precodonN:=15}

echo  "converting bam/bed format to bed format for file $bamfile!"
echo -n "Start at `date +%H:%M:%S`. Please wait..."
if [ ${bamfile##*.} = "bam" ]
then
    bamToBed -i $bamfile >"$temp_dir/${bamfile%%.*}.bed"
elif [ ${bamfile##*.} = "bed" ]
then
    cp $bamfile $temp_dir
fi

echo "end at `date +%H:%M:%S`."


#gff2bed or gtf2bed
#gff3 format : ctg123 . gene 1000 9000 . + . ID=gene00001;Name=EDEN
#gtf format :chrI  sacCer2_sgdGene start_codon 130802  130804  0.000000    +   .   gene_id "YAL012W"; transcript_id "Y    AL012W";
#bed format : chr7    127471196  127472363  Pos1  0  +
echo "converting gtf/gff/bed to bed format for file $gtf_or_gff_file"
echo -n "Start at `date +%H:%M:%S`. Please wait..."
if [ ${gtf_or_gff_file##*.} = "bed" ]
then
    {awk -v precodonN="$precodonN" -v dir="$temp_dir" '{$2=$2-$precodonN; print $0}' $gtf_or_gff_file >$dir"/"$gtf_or_gff_file}
else
awk -v filename="${gtf_or_gff_file%%.*}" -v dir="$temp_dir" -v file_format="${gtf_or_gff_file##*.}" -v precodonN=$precodonN '
BEGIN{FS="\t"; OFS="\t"}
$3 == "CDS" {if (file_format == "gtf") {print $1, get_precodon($4, precodonN), $5, get_feature1($9), $6, $7 > dir"/"filename".bed"}
	     else if (file_format == "gff") {print $1, get_precodon($4, precodonN), $5, get_feature2($9), $6, $7 > dir"/"filename".bed"}}

#add the precodonN nt before the start location
function get_precodon(start, precodonN){
if (start <= 15)
    {return start-1}
else
    {return start-1-precodonN}
}

#for gtf format
function get_feature1(feature_id1,    feature_length, feature_list, feature){
feature_length = split(feature_id1, feature_list, " \"|\"; ")
{for (i=1; i<=feature_length; i++)
    {if (feature_list[i] =="transcript_id")
	{flag="found"
	 feature = feature_list[i+1]
         break
	}
 }}
 {if (flag == "found")
     {return feature}
 else
     {print "Your gtf file may be bad format. you could generate gtf file from http://genome.ucsc.edu/cgi-bin/hgTables?org=human"}
 }}

#for gff format
function get_feature2(feature_id2,    feature_length, feature_list, feature, flag){
feature_length = split(feature_id2, feature_list, ";|=")
{for (i=1; i<=feature_length; i++)
    {if (tolower(feature_list[i]) == "id")
	{flag="found"
	 feature = feature_list[i+1]
	 break}
    else if (flag != "found" && tolower(feature_list[i]) == "name")
         {flag="found"
	  feature = feature_list[i+1]
	  break
	 }}}
{if (flag == "found")
     {return feature}
else
    {print "Your gff file should be gff3 format. To validate your gff file, visite http://modencode.oicr.on.ca/cgi-bin/validate_gff3_online, please. Or you could use gtf format file."
    exit 1}}}' $gtf_or_gff_file
fi
echo "end at `date +%H:%M:%S`."


# Using coverageBed -sd computing the profiling.
echo  "Computing coverage by coverageBed and generate file ribosome_profiling.bed which contains the ribosome profiling datas of every codon of CDSes"
echo  -n "Start at `date +%H:%M:%S`. Please wait..."
cd $temp_dir

#computing the total mapping_cds reads counts
eval $(coverageBed -a ${bamfile%%.*}.bed -b ${gtf_or_gff_file%%.*}".bed" -s | awk 'BEGIN{OFS="\t"}{total_cds_reads +=$7}END{print "total_cds_reads="total_cds_reads}')

#generating the ribosome_profiling.txt
coverageBed -a ${bamfile%%.*}.bed -b ${gtf_or_gff_file%%.*}".bed" -s -d | awk 'BEGIN{OFS="\t"}{if ($7%3) {aver+=$8} else {$7 =$7/3; $8=($8+aver)/3; print ; aver=0}}' | awk -v total_cds_reads=$total_cds_reads 'BEGIN{OFS="\t"}{print $1, $2, $3, $4, $5, $6, $7, $8*1000000/total_cds_reads > "ribosome_profiling.txt"}'
echo "end at `date +%H:%M:%S`."


#generate r total scripts to draw the profiling
#ribosome_profiling.txt format : chrI	13631470    13632070	NM_060987   .	+   1	1.44952
linei=0
rdir="ribosome_profiling_of_R_scripts"
if [ ! -d ${rdir} ]
then
    mkdir $rdir
fi
awk -v precodonN=$precodonN 'BEGIN{OFS=" "} 
name == $4{printf ",%s ", $8; feature_length = $7-precodonN/3-1}
name != $4{name = $4;{if (NR != 1) end_print(feature_length, name)}; init_print($4, $8, $7)}
END{end_print(feature_length, name)}

# after read one feature completely call the function end_print
function end_print(feature_length, name){
print ")"
printf "x <- c(-$s/3 ", precodonN
for (i=1-precodonN/3; i <= feature_length; i++){
    printf ",%s ", i}
print ")"
print "tiff(\""name".tiff\")"
print "plot (x, y/mean(y), type=\"l\", lwd=3, col=\"red\", xlab=\"Position (codon)\",ylab=\"Normalized coveraged reads\", main=\"Ribosome Profiling of "name"\")"
print "dev.off()"
print "#END"}

#start a new feature call the init_print
function init_print(name, y, x){
print "#R script for "name
print "#generated by generate_ribosome_profiling.sh."
printf "y <- c(%s ", y }' ribosome_profiling.txt | while read line
do
    # split total R script into single R script.
    {
    linei=$[linei+1]
    if [[ $[$linei%8] -eq 1 ]]
    then
	newname=`echo $line | awk '{print $4}'`
        echo $line>$rdir"/"$newname".R"
    else
        echo $line >>$rdir"/"$newname".R"
    fi
}
done

DEBUG set +x


