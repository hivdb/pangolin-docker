#! /usr/bin/env python3

import re
import csv
import json
import hashlib
from datetime import datetime


def sanitize_sequence(seq):
    seq = seq.upper()
    return re.sub(r'[^ACGTRYMWSKBDHVN]', '', seq)


def hash_fasta(fp):
    seqhashes = {}
    header = None
    curseq = ''
    for line in fp:
        if line.startswith('>'):
            if header and curseq:
                curseq = sanitize_sequence(curseq).encode('U8')
                seqhashes[header] = hashlib.sha512(curseq).hexdigest()
            header = line[1:].strip()
            curseq = ''
        elif line.startswith('#'):
            continue
        else:
            curseq += line.strip()
    if header and curseq:
        curseq = sanitize_sequence(curseq).encode('U8')
        seqhashes[header] = hashlib.sha512(curseq).hexdigest()
    return seqhashes


with open('/tmp/input.fasta') as fp:
    seqhashes = hash_fasta(fp)

with open('/pangolin_version') as fp:
    pangolin_version = fp.read().strip()

with open('/tmp/pangolin.stdout.log') as fp:
    stdout = fp.read()

with open('/tmp/pangolin.stderr.log') as fp:
    stderr = fp.read()

utcnow = datetime.utcnow().isoformat() + "Z"
results = {
    "pangolin_version": pangolin_version,
    "report_timestamp": datetime.utcnow().isoformat() + "Z",
    "stdout": stdout,
    "stderr": stderr,
    "reports": []
}

with open('/tmp/lineage_report.csv') as fp:
    for row in csv.DictReader(fp):
        row['probability'] = float(row['probability'])
        seqhash = seqhashes[row.pop('taxon')]
        with open('/tmp/reports/{}.json'.format(seqhash), 'w') as out:
            json.dump({
                "pangolin_version": pangolin_version,
                "report_timestamp": utcnow,
                "sha512": seqhash,
                "report": row
            }, out)
