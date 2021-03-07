#! /bin/bash

set -e

if [ -z "$INPUT_FASTA" ]; then
    echo "Environ INPUT_FASTA is missing." 1>&2
    exit 1
fi

mkdir /tmp/reports
aws s3 cp s3://pangolin-assets.hivdb.org/uploads/$INPUT_FASTA /tmp/input.fasta
aws s3 rm s3://pangolin-assets.hivdb.org/uploads/$INPUT_FASTA
pangolin /tmp/input.fasta -o /tmp --outfile lineage_report.csv > /tmp/pangolin.stdout.log 2> /tmp/pangolin.stderr.log
make_reports.py
aws s3 sync /tmp/reports s3://pangolin-assets.hivdb.org/reports
