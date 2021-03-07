SHELL=/bin/bash

# build-origimage: pangolin
# 	@docker build -t hivdb/pangolin-orig:latest pangolin
# 
# debug-origimage:
# 	@docker run --rm -it hivdb/pangolin-orig:latest bash

build:
	@docker build -t hivdb/pangolin-runner:latest .

debug:
	@docker run \
		-it --rm \
		--volume ~/.aws:/root/.aws:ro \
		--volume $(PWD)/local:/local \
		--entrypoint /bin/bash hivdb/pangolin-runner:latest 

release:
	@docker push hivdb/pangolin-runner:latest
