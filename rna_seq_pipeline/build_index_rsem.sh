#!/usr/bin/env bash

# Summary:
#   Build an index for RSEM quantification.
#
# Example usage:
#   build_index_rsem.sh \
#       --genomeFa {genome_fasta_path} --genomeGtf {genome_gtf_path} \
#        --rsemGenomeDir {rsem_genome_dir} --ncpus {num_threads}
#
# Input arguments (all required):
#   --genomeFa : file path for reference genome .fa file
#   --genomeGtf : file path for reference genome .gtf file
#   --rsemGenomeDir : directory for RSEM genome index files
#   --ncpus : int > 0; number of threads to use
#
# Ouput files:
#
# Reference annotation files:
#   Information on the GRCh38 mapped versions of GENCODE v24 is availible here:
#       http://www.gencodegenes.org/releases/24lift37.html
#   We suggest using the following reference files:
#   GTF: ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_24/GRCh37_mapping/gencode.v24lift37.annotation.gtf.gz
#   Fasta: ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_24/GRCh37_mapping/gencode.v24lift37.annotation.gtf.gz
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
    --rsemGenomeDir)
    rsemGenomeDir="$2"
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

if [ -z "$rsemGenomeDir" ] || [ ! -e $(dirname ${rsemGenomeDir}) ]
then
  (>&2 echo "error: rsemGenomeDir path (${rsemGenomeDir}) does not exist.")
  exit 1
fi

if [ -z "$NCPU" ] || [ $NCPU -lt 1 ]
then
  (>&2 echo "error: --ncpus (${NCPU}) not set, or not valid number.")
  exit 1
fi

### Build RSEM index ###

rsemGenomePrefix="$rsemGenomeDir/rsem"

rsem-prepare-reference \
    --gtf "$genomeGtf" \
    --num-threads $NCPU \
    "$genomeFa" \
    "$rsemGenomePrefix"
