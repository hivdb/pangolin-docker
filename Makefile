SHELL=/bin/bash
VERSION = $(shell date -u +"%Y%m%d%H%M%S")

# build-origimage: pangolin
# 	@docker build -t hivdb/pangolin-orig:latest pangolin
# 
# debug-origimage:
# 	@docker run --rm -it hivdb/pangolin-orig:latest bash

build: login-pubecr
	@docker build -t hivdb/pangolin-lambda:latest .

shell:
	@docker run \
		-it --rm \
		--volume ~/.aws:/root/.aws:ro \
		--volume $(PWD)/local:/local \
		--entrypoint /bin/bash hivdb/pangolin-lambda:latest 

emulate:
	@docker run \
		--volume ~/.aws:/root/.aws:ro \
		-p 9015:8080 hivdb/pangolin-lambda:latest 

login-pubecr:
	@aws ecr-public get-login-password --region us-east-1 | \
		docker login --username AWS --password-stdin public.ecr.aws/lambda

login:
	@aws ecr get-login-password --region us-west-2 | \
		docker login --username AWS --password-stdin 931437602538.dkr.ecr.us-west-2.amazonaws.com

release: login
	@docker tag hivdb/pangolin-lambda:latest 931437602538.dkr.ecr.us-west-2.amazonaws.com/hivdb/pangolin-lambda:latest
	@docker tag hivdb/pangolin-lambda:latest 931437602538.dkr.ecr.us-west-2.amazonaws.com/hivdb/pangolin-lambda:${VERSION}
	@docker push 931437602538.dkr.ecr.us-west-2.amazonaws.com/hivdb/pangolin-lambda:latest
	@docker push 931437602538.dkr.ecr.us-west-2.amazonaws.com/hivdb/pangolin-lambda:${VERSION}
	@echo ${VERSION} > .latest_version

deploy:
	@bash deploy.sh
