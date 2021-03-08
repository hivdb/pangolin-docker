import csv
import json
import subprocess
from datetime import datetime

from pangolin import __version__ as pangolin_version


def main(event, context):
    fasta = event.get('body') or ''
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
        "pangolin_version": pangolin_version,
        "report_timestamp": datetime.utcnow().isoformat() + "Z",
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
    }
    with open('/tmp/lineage-report.csv') as fp:
        rows = []
        for row in csv.DictReader(fp):
            row['probability'] = float(row['probability'])
            rows.append(row)
        results['reports'] = rows
    return {
        'statusCode': 200,
        'header': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(results)
    }
