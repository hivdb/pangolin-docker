import csv
import json
import boto3
import hashlib
import subprocess
from datetime import datetime

from pangolin import __version__ as pangolin_version
from pangoLEARN import __version__ as pangoLEARN_version


def main(event, context):
    version = 'pangolin: {}; pangoLEARN: {}'.format(
        pangolin_version, pangoLEARN_version)
    fasta = event.get('body') or ''
    runhash = hashlib.sha512(fasta.encode('utf-8')).hexdigest()
    with open('/tmp/input.fasta', 'w') as fp:
        fp.write(fasta)
    proc = subprocess.run(
        ['/var/lang/bin/pangolin',
         '/tmp/input.fasta',
         '-o', '/tmp',
         '--outfile', 'lineage-report.csv'],
        capture_output=True,
        encoding='UTF-8'
    )
    results = {
        "runHash": runhash,
        "version": version,
        "reportTimestamp": datetime.utcnow().isoformat() + "Z",
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
    }
    with open('/tmp/lineage-report.csv') as fp:
        rows = []
        for row in csv.DictReader(fp):
            # explict list fields in case pangolin added more columns
            if row['conflict'] == 'NA':
                conflict = None
                probability = None
            else:
                try:
                    conflict = float(row['conflict'])
                except ValueError:
                    conflict = 0
                probability = 1 - conflict
            rows.append({
                'taxon': row['taxon'],
                'lineage': row['lineage'],
                'probability': probability,
                'conflict': conflict,
                'status': row['status'],
                'note': row['note'],
            })
        results['reports'] = rows
    body = json.dumps(results)
    s3_client = boto3.client('s3')
    s3_client.put_object(
        Body=version.encode('utf-8'),
        Bucket='pangolin-assets.hivdb.org',
        Key='latest_version')
    s3_client.put_object(
        Body=body.encode('utf-8'),
        Bucket='pangolin-assets.hivdb.org',
        Key='reports/{}.json'.format(runhash))
    return {
        'statusCode': 200,
        'header': {
            'Content-Type': 'application/json'
        },
        'body': body
    }
