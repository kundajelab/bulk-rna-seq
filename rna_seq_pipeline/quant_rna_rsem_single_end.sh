#!/usr/bin/env bash

# Summary:
#   Quantify aligned RNA-seq bam files with RSEM.
#
# Example usage:
#   quant_rna_rsem.sh \
#       --transcriptBAM {transcript_bam} --output {output_prefix} \
#       --ncpus {num_threads}
#
# Input arguments (all required):
#   --transcriptBAM : full path to transcrit BAM file
#                     (this is the "_Aligned.toTranscriptome.out.bam")
#   --output : the base path and filename prefix to write quantified output
#   --rsemGenomeDir : directory for RSEM genome index files
#   --ncpus : int > 0; number of threads to use
#
# Ouput files:
#   {output_prefix}_Aligned.toTranscriptome.sorted.bam : sorted bam used as input for RSEM
#   {output_prefix}.rsem.quant.{} : rsem quantification files
#
#

while [[ $# > 1 ]]
do
key="$1"

case $key in
    --transcriptBAM)
    transcriptBAM="$2"
    shift
    ;;
    --rsemGenomeDir)
    rsemGenomeDir="$2"
    shift
    ;;
    --output)
    outputBase="$2"
    shift
    ;;
    --ncpus)
    NCPU="$2"
    shift
    ;;
    *)
    ;;
esac
shift
done

if [ -z "$transcriptBAM" ] || [ ! -e ${transcriptBAM} ]
then
  (>&2 echo "error: transcript bam file (${transcriptBAM}) does not exist.")
  exit 1
fi

if [ -z "$outputBase" ] || [ ! -e $(dirname ${outputBase}) ]
then
  (>&2 echo "error: output path (${outputBase}) does not exist.")
  exit 1
fi

if  [ -z "$rsemGenomeDir" ] 
then
  (>&2 echo "error: rsemGenomeDir path (${rsemGenomeDir}) does not exist.")
  exit 1
fi

if [ -z "$NCPU" ] || [ $NCPU -lt 1 ]
then
  (>&2 echo "error: --ncpus (${NCPU}) not set, or not valid number.")
  exit 1
fi

### Sort transcriptome .bam file -- makes RSEM output deterministic ###

trBAMsortRAM=12G # memory for sorting
sortTmpDir=$(dirname ${outputBase}) # tmp space for sorting

#bamtools sort -in $transcriptBAM -out $outputBase/Aligned.toTranscriptome.sorted.bam 
#this does not seem to work on scg4? Might be a process substitution problem w/ shell? 
#cat <(samtools view -H "$transcriptBAM") <( samtools view -@ $NCPU "$transcriptBAM" | awk '{printf $0 " "; getline; print}' | sort --parallel=$NCPU -S $trBAMsortRAM -T ${sortTmpDir} | tr ' ' '\n') | samtools view -@ $NCPU -bS - > ${outputBase}_Aligned.toTranscriptome.sorted.bam

### Run RSEM ###

# note that we don't calculate expression confidence intervals -- doing so is very slow

quantOutputBasePath=$outputBase/rsem.quant
quantLoggingBasePath=$outputBase/rsem.log.txt

rsem-calculate-expression  --bam --estimate-rspd --no-bam-output --seed  12345 -p $NCPU --ci-memory 30000 $transcriptBAM $rsemGenomeDir $quantOutputBasePath  >& $quantLoggingBasePath

#### Optional: RSEM diagnostic plot creation ###
# Notes:
# 1. rsem-plot-model requires R (and the Rscript executable)
# 2. This command produces the file Quant.pdf, which contains multiple plots

rsem-plot-model $quantOutputBasePath $outputBase/rsem_quant.pdf
