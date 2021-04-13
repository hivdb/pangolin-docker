#! /bin/bash

set -e

docker run -i --rm --volume ~/.aws:/root/.aws:ro --entrypoint python3 hivdb/pangolin-lambda:latest > local/latest_version <<EOF
from pangolin import __version__ as pangolin_version
from pangoLEARN import __version__ as pangoLEARN_version
version = 'pangolin: {}; pangoLEARN: {}'.format(
    pangolin_version, pangoLEARN_version)
print(version)
EOF
aws s3 cp local/latest_version s3://pangolin-assets.hivdb.org/latest_version
