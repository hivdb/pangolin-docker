SHELL=/bin/bash

# build-origimage: pangolin
# 	@docker build -t hivdb/pangolin-orig:latest pangolin
# 
# debug-origimage:
# 	@docker run --rm -it hivdb/pangolin-orig:latest bash

build:
	@docker build -t hivdb/pangolin-runner:latest .

shell:
	@docker run \
		-it --rm \
		--volume ~/.aws:/root/.aws:ro \
		--volume $(PWD)/local:/local \
		--entrypoint /bin/bash hivdb/pangolin-runner:latest 

emulate:
	docker run -p 9015:8080 hivdb/pangolin-runner:latest 

login:
	@aws ecr-public get-login-password --region us-east-1 | \
		docker login --username AWS --password-stdin public.ecr.aws/w0r9y0f4

release: login
	@docker tag hivdb/pangolin-runner:latest public.ecr.aws/w0r9y0f4/hivdb/pangolin-runner:latest
	@docker push public.ecr.aws/w0r9y0f4/hivdb/pangolin-runner:latest
