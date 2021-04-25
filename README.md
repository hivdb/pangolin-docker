# Pangolin-Lambda

Pangolin-Lambda is a simple wrapper of the original [Pangolin][pangolin-github]
program and its [PangoLEARN][pangolearn-github] trained model. It provides
ability to use AWS Lambda and S3 to host a serverless Pangolin web API.


## Preparation

You need to have an AWS account and created dedicated instances for these two
AWS service:

- A Lambda function
- An S3 repository

In addition to the default AWSLambdaBasicExecutionRole, the Lambda function must
have full access to the S3 repository. Here is an example of the policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::pangolin-assets.hivdb.org",
        "arn:aws:s3:::pangolin-assets.hivdb.org/*"
      ]
    }
  ]
}
```

No addition policy is required for the S3 repository.

You also need to have [Docker][docker] and [AWSCli (v2)][awscli] installed.


## Build

```shell
make build
```

This make command will build a Docker image that is compatible with AWS Lambda.
The Docker image is based on [AWS base images for Python 3.8][aws-image-py38].
It installs Pangolin dependencies such as minimap2, gofasta, and snakemake. It
also installs Pangolin from the linked sub-repository `pangolin` and from the
GitHub release of `PangoLEARN`. The version of `PangoLEARN` is anchored to a
constant version defined by the argument `PANGOLEARN_VER` in `Dockerfile`.


## Access sandbox shell locally

```shell
make shell

# To display version:
pangolin -v
pangolin -pv
```

This make command will hijack the default Docker image enterpoint and provide
the developer a fully functional Pangolin shell environment. To access the
pangolin shell command just type in "pangolin" after you entered the sandbox
shell.

Note: this command requires AWS config and credentials under host machine path
`~/.aws`. For more information, visit [this AWS instruction][awscli-config].


## Emulate web API locally

```shell
make emulate
```

This make command will emulate a web server that provides the exact web API
deployed on AWS Lambda. The web API listens on port 9015 of the Docker host
machine. For more information, visit [this AWS instruction][lambda-test].

Note: this command requires AWS config and credentials.


## Release local Docker image

```shell
make release
```

This make command will upload the latest Docker image to given AWS ECR
repository. The AWS user id, region and function name are hard-coded in the
Makefile. If you want to make a fork of this repository, ensure you have updated
these variables.

Note: this command requires AWS config and credentials.


## Deploy to AWS Lambda

```shell
make deploy
```

This make command will deploy the **released** Docker image to an existing AWS
Lambda function.

Note: this command requires AWS config and credentials.


## API Interface

A payload that includes FASTA format text is required to trigger the Lambda
function. Follow is the request format:

```json
{
  "body": ">Wuhan/WH04/2020\nNNNN...."
}
```

Response format:

```json
{
  "statusCode": 200,
  "header": {
    "Content-Type": "application/json"
  },
  "body": "..."
}
```

The `"body"` of response is an encoded JSON string:

```json
{
  "runHash": "<SHA512_HASH_OF_REQUEST_BODY>",
  "version": "pangolin: x.y.z; pangoLEARN: YYYY-MM-DD",
  "reportTimestamp": "YYYY-MM-DDTHH:mm:SS.ssssssZ",
  "returncode": 0,
  "stdout": "<PANGOLIN_STDOUT>",
  "stderr": "<PANGOLIN_STDERR>",
  "reports": [
    {
      "taxon": "Wuhan/WH04/2020",
      "lineage": "A",
      "probability": 1.0,
      "status": "passed_qc",
      "note": ""
    }
    ...
  ]
}
```

### Aync usage

To retrieve the Pangolin result asynchronously, an S3 url can be construct for
polling. For example:

```bash
aws s3 cp s3://pangolin-assets.hivdb.org/reports/<runHash>.json
```

The format of the `<runHash>.json` is similar to the response payload.


[pangolin-github]: https://github.com/cov-lineages/pangolin
[pangolearn-github]: https://github.com/cov-lineages/pangoLEARN
[docker]: https://docs.docker.com/get-docker/
[awscli]: https://aws.amazon.com/cli/
[aws-image-py38]: https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-base
[awscli-config]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
[lambda-test]: https://docs.aws.amazon.com/lambda/latest/dg/images-test.html
