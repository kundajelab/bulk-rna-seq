#!/usr/bin/env bash

# Summary:
#   Run trimmomatic on a single pair of fastqs. The purpose is to remove
#   adapter sequences, and to make all reads a consistent length.
#
# Example usage:
#   trim_rna_trimmomatic.sh \
#       --R1 {R1.fq.gz} --R2 {R2.fq.gz} --output {output_prefix} \
#       --readLength {read_len} --ncpus {num_threads}
#
# Input arguments (all required):
#   --R1 : path to read 1 fastq.gz file
#   --R2 : path to read 2 fastq.gz file
#   --output : the base path and filename prefix to write output
#   --readLength : int > 1; trimmed read length
#   --ncpus : int > 0; number of threads to use
#
# Ouput files:
#   {output_prefix}_R1.trimmed.fastq.gz
#   {output_prefix}_R2.trimmed.fastq.gz
#   {output_prefix}.trim.log.txt.gz
#
# N.B.: R1 and R2 must end in either .fq.gz or .fastq.gz
#

### Get the paths for packaged Trimmomatic and adapters files ###
CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TRIMMOMATIC_DIR="${CURDIR}/Trimmomatic-0.36/"
TRIMMOMATIC_JAR="${TRIMMOMATIC_DIR}/trimmomatic-0.36.jar"
ADAPTERS_FILE="${TRIMMOMATIC_DIR}/TruSeq-adapters.fa"

### Parse command line arguments ###

while [[ $# > 1 ]]
do
key="$1"

case $key in
    --R1)
    R1PATH="$2"
    shift
    ;;
    --R2)
    R2PATH="$2"
    shift
    ;;
    --output)
    OUTFNAMEBASE="$2"
    shift
    ;;
    --ncpus)
    NCPU="$2"
    shift
    ;;
    --readLength)
    READLENGTH="$2"
    shift
    ;;
    *)
    ;;
esac
shift
done

if [ -z "$R1PATH" ] || [ ! -e ${R1PATH} ]
then
  echo "error: R1 (${R1PATH}) does not exist."
  exit 1
fi

if [ -z "$R2PATH" ] || [ ! -e ${R2PATH} ]
then
  echo "error: R2 (${R2PATH}) does not exist."
  exit 1
fi

if [ -z "$OUTFNAMEBASE" ] || [ ! -e $(dirname ${OUTFNAMEBASE}) ]
then
  (>&2 echo "error: output path (${OUTFNAMEBASE}) does not exist.")
  exit 1
fi

if [ -z "$READLENGTH" ] || [ $READLENGTH -lt 2 ]
then
  (>&2 echo "error: --readLength (${READLENGTH}) not set,"\
            " or not valid number.")
  exit 1
fi

if [ -z "$NCPU" ] || [ $NCPU -lt 1 ]
then
  (>&2 echo "error: --ncpus (${NCPU}) not set, or not valid number.")
  exit 1
fi

### Run Trimmomatic ###

trim_log_file="${OUTPUT_BASE}.trim.log.txt"

java \
    -Xms1336m -Xmx1336m \
    -jar "${TRIMMOMATIC_JAR}" \
    PE \
    -threads $NCPU \
    -trimlog "${trim_log_file}" \
    "${R1PATH}" "${R2PATH}" \
    -baseout "${OUTPUT_BASE}" \
    "ILLUMINACLIP:${ADAPTERS_FILE}:2:20:7:1:true" \
    "CROP:${READLENGTH}"

mv "${OUTPUT_BASE}_1P.fq.gz" ${OUTPUT_BASE}_R1.trimmed.fq.gz
mv "${OUTPUT_BASE}_2P.fq.gz" ${OUTPUT_BASE}_R2.trimmed.fq.gz
rm "${OUTPUT_BASE}_1U.fq.gz"
rm "${OUTPUT_BASE}_2U.fq.gz"
gzip "${trim_log_file}"
