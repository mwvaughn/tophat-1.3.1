#!/bin/bash

#$ -N tophat
#$ -j y
#$ -o log.$JOB_ID
#$ -pe 1way 16
#$ -q serial
#$ -l h_rt=8:00:00
#$ -cwd
#$ -V
#$ -A TG-MCB110022

QUERY1=/iplant/home/vaughn/reads.rna.fq
QUERY2=
GENOME=/iplant/home/shared/iplantcollaborative/genomeservices/legacy/0.30/genomes/arabidopsis_thaliana/col-0/v10/genome.fas
ANNOTATION=/iplant/home/shared/iplantcollaborative/genomeservices/legacy/0.30/genomes/arabidopsis_thaliana/col-0/v10/annotation.gtf

output_dir=./tophat_out
mate_inner_dist=200
mate_std_dev=20
min_anchor_length=8
splice_mismatches=0
min_intron_length=70
max_intron_length=50000
max_insertion_length=3
max_deletion_length=3
min_isoform_fraction=0.15
max_multihits=20
library_type=fr-unstranded
segment_length=25

module purge
module load TACC
module swap pgi gcc
module load zlib
module load python/2.7.1
module load irods

echo "madlh918" | iinit

# Path stuff
export CWD=${PWD}
export PATH="${PATH}:${PWD}/bin:${PWD}/bin/tophat-1.3.1.Linux_x86_64"

# Create local temp directory
export TMPDIR="${CWD}/tmp"
mkdir -p $TMPDIR
export OMP_NUM_THREADS=16

# Copy reference sequence...
GENOME_F=$(basename ${GENOME})
CHECKSUM=0
echo "Copying $GENOME_F"
iget -fT ${GENOME} .
# Quick sanity check before committing to do anything compute intensive
if ! [ -e $GENOME_F ]; then echo "Error: Genome sequence not found."; exit 1; fi

# Create temp .fa
if [[ ! $GENOME_F =~ ".fa$" ]]; then ln -s $GENOME_F ${GENOME_F}.fa ; fi

# and its index files
for J in 1.ebwt 2.ebwt 3.ebwt 4.ebwt rev.1.ebwt rev.2.ebwt
do
	echo "${GENOME}.${J}"
	iget -f "${GENOME}.${J}" .
done

# Determine pair-end or not
PE=0
if [[ -n $QUERY1 ]] && [[ -n $QUERY2 ]]; then let PE=1; echo "Paired-end"; fi

# Query sequences
QUERY1_F=$(basename ${QUERY1})
iget -fT ${QUERY1} .

QUERY2_F=
if [ $PE == 1 ]; then
	QUERY2_F=$(basename ${QUERY2})
	iget -fT ${QUERY2} .
fi

tophat --num-threads $OMP_NUM_THREADS --output-dir $output_dir --mate-inner-dist $mate_inner_dist --mate-std-dev $mate_std_dev --min-anchor-length $min_anchor_length --splice-mismatches $splice_mismatches --min-intron-length $min_intron_length --max-intron-length $max_intron_length --max-insertion-length $max_insertion_length --max-deletion-length $max_deletion_length --min-isoform-fraction $min_isoform_fraction --max-multihits $max_multihits --library-type $library_type --segment-length $segment_length $GENOME_F $QUERY1_F $QUERY2_F
