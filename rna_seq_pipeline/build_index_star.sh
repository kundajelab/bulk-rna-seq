#!/usr/bin/env bash

# Summary:
#   Build an index for STAR alignment.
#
# Example usage:
#   build_index_star.sh \
#       --genomeFa {genome_fasta_path} --genomeGtf {genome_gtf_path} \
#       --readLength {read_len} --starGenomeDir {star_genome_dir} \
#       --ncpus {num_threads}
#
# Input arguments (all required):
#   --genomeFa : file path for reference genome .fa file
#   --genomeGtf : file path for reference genome .gtf file
#   --starGenomeDir : directory path for STAR genome index files
#   --readLength : int > 0; the target read length for trimming
#   --ncpus : int > 0; number of threads to use
#
# Ouput files:
#   {starGenomeDir}/ : all STAR genome index files
#
# Notes:
#   Read length and sjdbOverhang:
#       Per the STAR manual, the --sjdbOverhang should be set to (mate_length - 1).
#       The mate length is the effective mate length after trimming. For the GECCO
#       RNA study, this is 50bp.
#
#   Reference annotation files:
#       Information on the GRCh38 mapped versions of GENCODE v24 is availible here:
#           http://www.gencodegenes.org/releases/24lift37.html
#       We suggest using the following reference files:
#       GTF: ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_24/GRCh37_mapping/gencode.v24lift37.annotation.gtf.gz
#       Fasta: ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_24/GRCh37_mapping/gencode.v24lift37.annotation.gtf.gz
#

### Parse command line inputs ###

while [[ $# > 1 ]]
do
key="$1"

case $key in
    --genomeFa)
    genomeFa="$2"
    shift
    ;;
    --genomeGtf)
    genomeGtf="$2"
    shift
    ;;
    --starGenomeDir)
    starGenomeDir="$2"
    shift
    ;;
    --readLength)
    readLength="$2"
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

if [ -z "$genomeFa" ] || [ ! -e ${genomeFa} ]
then
  (>&2 echo "error: genome fasta file (${genomeFa}) does not exist.")
  exit 1
fi

if [ -z "$genomeGtf" ] || [ ! -e ${genomeGtf} ]
then
  (>&2 echo "error: genome gtf file (${genomeGtf}) does not exist.")
  exit 1
fi

if [ -z "$starGenomeDir" ] || [ ! -e ${starGenomeDir} ]
then
  (>&2 echo "error: STAR genome directory (${starGenomeDir}) does not exist.")
  exit 1
fi

if [ -z "$readLength" ] || [ $readLength -lt 1 ]
then
  (>&2 echo "error: --readLength (${readLength}) not set, or not valid number.")
  exit 1
fi

if [ -z "$NCPU" ] || [ $NCPU -lt 1 ]
then
  (>&2 echo "error: --ncpus (${NCPU}) not set, or not valid number.")
  exit 1
fi

### Build STAR index ###

# Per the STAR manual, the parameter --sjdbOverhang should be set to (mate_length - 1)
sjdbOverhang=$(($readLength - 1))

STAR \
    --runThreadN $NCPU \
    --runMode genomeGenerate \
    --genomeDir "$starGenomeDir" \
    --genomeFastaFiles "$genomeFa" \
    --sjdbGTFfile "$genomeGtf" \
    --sjdbOverhang $sjdbOverhang
