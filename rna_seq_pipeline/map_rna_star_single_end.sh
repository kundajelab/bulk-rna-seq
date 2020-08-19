#!/usr/bin/env bash

# Summary:
#   Simple STAR wrapper script, based on the ENCODE DCC long RNA pipeline.
#   The only differences to the ENCODE long RNA pipeline are:
#       1) We do not modify the SAM header format with ENCODE identifiers.
#       2) We do use 2-pass mapping (specifically, --twopassMode Basic).
#
# Example usage:
#   map_rna_star.sh \
#       --R1 {R1.fq.gz}  --starGenomeDir {star_genome_dir} \
#       --ncpus {num_threads} --outputbase {output_prefix}
#
# Input arguments (all required):
#   --R1 : path to read 1 fastq.gz file
#   --starGenomeDir : path to STAR genome directory
#   --outputbase : prefix for all outputs (path and filename prefix)
#   --ncpus : int > 0; number of cpus
#
# Ouput files:
#   {output_prefix}Aligned.toTranscriptome.out.bam
#   {output_prefix}Aligned.sortedByCoord.out.bam
#   {output_prefix}Log.progress.out
#   {output_prefix}Log.final.out
#   {output_prefix}SJ.out.tab
#   {output_prefix}Log.out
#
# N.B.: Successful alignment completion is indicated by the
#       existence of the file {output_prefix}Log.final.out
#

### Parse command line arguments ###

while [[ $# > 1 ]]
do
key="$1"

case $key in
    --R1)
    R1PATH="$2"
    shift
    ;;
    --starGenomeDir)
    GENOMEDIR="$2"
    shift
    ;;
    --ncpus)
    NCPU="$2"
    shift
    ;;
    --outputbase)
    OUTFNAMEBASE="$2"
    shift
    ;;
    *)
    ;;
esac
shift
done

if [ -z "$R1PATH" ] || [ ! -e ${R1PATH} ]
then
  (>&2 echo "error: R1 (${R1PATH}) does not exist.")
  exit 1
fi


if [ -z "$GENOMEDIR" ] || [ ! -e ${GENOMEDIR} ] \
    || [ ! -e "${GENOMEDIR}/Genome" ]
then
  (>&2 echo "error: genome path (${GENOMEDIR}) does not exist, " \
    "or does not contain a valid STAR genome index.")
  exit 1
fi

if [ -z "$OUTFNAMEBASE" ] || [ ! -e $(dirname ${OUTFNAMEBASE}) ]
then
  (>&2 echo "error: output path (${OUTFNAMEBASE}) does not exist.")
  exit 1
fi

if [ -z "$NCPU" ] || [ $NCPU -lt 1 ]
then
  (>&2 echo "error: --ncpus (${NCPU}) not set, or not valid number.")
  exit 1
fi

star_path=$(which STAR)
if [ -x "$star_path" ] ; then
    echo "Using STAR: ($star_path)"
else
    (>&2 echo "error: STAR executable not found in PATH.")
    exit 1
fi

star_version=$(STAR --version)
echo "STAR version: ($star_version)"
echo $OUTFBASENAME
### Run STAR ###
STAR \
    --genomeDir "${GENOMEDIR}" \
    --readFilesIn "${R1PATH}" \
    --outFileNamePrefix "${OUTFNAMEBASE}" \
    --readFilesCommand zcat \
    --runThreadN ${NCPU} \
    --genomeLoad NoSharedMemory \
    --outFilterMultimapNmax 20 \
    --alignSJoverhangMin 8 \
    --alignSJDBoverhangMin 1 \
    --outFilterMismatchNmax 999 \
    --outFilterMismatchNoverReadLmax 0.04 \
    --alignIntronMin 20 \
    --alignIntronMax 1000000  \
    --alignMatesGapMax 1000000 \
    --outSAMunmapped Within \
    --outFilterType BySJout \
    --outSAMattributes NH HI AS NM MD \
    --outSAMtype BAM SortedByCoordinate \
    --quantMode TranscriptomeSAM \
    --sjdbScore 1 \
    --limitBAMsortRAM  60000000000 \
    --twopassMode Basic \
    --twopass1readsN -1 
