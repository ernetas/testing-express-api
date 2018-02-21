export SHELL := /bin/bash
CLIENT = personal
APP = api
PACKER_BIN = /usr/bin/packer-io
# I don't have a mac, so the above will only work if Packer is installed at that path. The below is meant as a template for what should make it work on Mac, too.
#ifeq ($(wildcard $(PACKER_BIN)),)
#PACKER_BIN = /usr/local/bin/packer
#endif

global-setup:
	cd terraform/providers/aws_$(CLIENT)/global \
	&& AWS_PROFILE=$(CLIENT) terraform get -update

global-init:
	cd terraform/providers/aws_$(CLIENT)/global \
	&& AWS_PROFILE=$(CLIENT) terraform init

global-plan: global-setup
	cd terraform/providers/aws_$(CLIENT)/global \
	&& AWS_PROFILE=$(CLIENT) terraform plan -out terraform.tfplan

global-apply: global-setup ## terraform apply an existing plan global env (requires global-plan)
	cd terraform/providers/aws_$(CLIENT)/global \
	&& AWS_PROFILE=$(CLIENT) terraform apply terraform.tfplan \
	&& rm terraform.tfplan

ami: ## build an ami with packer (run global-apply first to setup bucket)
	cd packer \
	&& AWS_PROFILE=$(CLIENT) $(PACKER_BIN) build -debug \
		-machine-readable \
		-only=amazon-ebs \
		ernestasapi-api.json | tee build.log \
	&& echo $$(egrep -m1 -oe 'ami-.{8}' build.log) \
		| aws s3 --profile $(CLIENT) cp - s3://ernestasapi-terraform/keyvalue/api_ami.txt

# PHONY (non-file) Targets
# ------------------------
.PHONY: help global-apply
# `make help` -  see http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
# ------------------------------------------------------------------------------------

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

env: ## List environments
	@grep -E '^[a-zA-Z_-]+:.*?### .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?### "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
