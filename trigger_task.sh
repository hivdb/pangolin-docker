#! /bin/bash

set -e

if [ ! -f "$1" ]; then
    echo "Usage: $0 <INPUT_FASTA>" 1>&2
    exit 1
fi

aws s3 cp $1 s3://pangolin-assets.hivdb.org/uploads/$(basename $1)

aws ecs run-task \
    --task-definition pangolin-runner:2 \
    --platform-version 1.4.0 \
    --cluster codfreq-runner \
    --launch-type FARGATE \
    --count 1 \
    --region us-west-2 \
    --network-configuration '{"awsvpcConfiguration":{"subnets":["subnet-02f7aeefbe32139e6","subnet-0d99ba6fe930466bc"],"securityGroups":["sg-0ab407848018a5604"],"assignPublicIp":"ENABLED"}}' \
    --overrides "{\"containerOverrides\":[{\"name\":\"pangolin-runner\",\"environment\":[{\"name\":\"INPUT_FASTA\",\"value\":\"$(basename $1)\"}]}]}"
