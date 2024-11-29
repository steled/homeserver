########## K1 Helper for easy management
# renovate: datasource=github-releases depName=kubeone packageName=kubermatic/kubeone
KUBEONE_VERSION=v1.8.3 check version here: https://github.com/kubermatic/kubeone/releases
ROOT_DIR=$(realpath .)

K1_CONFIG="."
ENVIRONMENT?=test
# TF_CONFIG="${ROOT_DIR}/tf-infra"    #relative from K1_CONFIG
# from K1_CONFIG location
# K1_SSH_KEY="${ROOT_DIR}/../secrets/kone-key-ecdsa"
# K1_CRED_FILE="./secrets/credentials.kubermatic.yml"
# K1_CRED_FLAG=-c ${K1_CRED_FILE}
K1_KUBECONFIG="${ROOT_DIR}/kubeone-${ENVIRONMENT}-kubeconfig"
K1_EXTRA_ARG?=""
#K1_EXTRA_ARG?="--force-upgrade"
# TODO: check version here: https://docs.kubermatic.com/kubeone/main/architecture/compatibility/supported-versions/
# KUBEONE_BINARY="kubeone"
KUBEONE_BINARY="${ROOT_DIR}/kubeone"
GREEN=41;42m
RED=41;101m


# KKP_SECRETS_KUBECONFIG="${ROOT_DIR}/../03-kubermatic/secrets/kubeone-root-kubeconfig"

# CREDENTIALS_FILE=${ROOT_DIR}/../secrets/credentials.sh
# include ${CREDENTIALS_FILE}
#### sometimes needed if "special characters in password or username is used
## CREDENTIALS_FILE_OVERWRITE=./secrets/credentials.makefile.overwrite.env
## include ${CREDENTIALS_FILE_OVERWRITE}
export

######### KubeOne
k1-apply-test:
	$(eval COLOR=${GREEN})
	$(eval ENVIRONMENT="kubeone-test")
	make k1-apply

k1-apply-prod:
	$(eval COLOR=${RED})
	$(eval ENVIRONMENT="homeserver")
	make k1-apply

k1-reset-test:
	$(eval COLOR=${GREEN})
	$(eval ENVIRONMENT="kubeone-test")
	make k1-reset

k1-reset-prod:
	$(eval COLOR=${RED})
	$(eval ENVIRONMENT="homeserver")
	make k1-reset

warning:
	@echo "Your are currently running on \033[$(COLOR)$(ENVIRONMENT)\033[0m environment"

# k1-load-env:
# 	@test -d ${K1_CONFIG} && echo "OK: kubeone config folder found" || (echo "ERROR: kubeone config folder not found" && exit 1)
# 	@cd ${K1_CONFIG} && test -f ${K1_SSH_KEY} && chmod 600 ${K1_SSH_KEY} && ssh-add ${K1_SSH_KEY} && echo "OK: applied ssh key permission" || (echo "ERROR: ssh key permission" && exit 2)
# 	@### store kubeone version
# 	@$(KUBEONE_BINARY) version > ${K1_CONFIG}/kubeone.version.json

# k1-tf-init:
# 	@cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
# 		terraform init

# k1-tf-apply: k1-load-env k1-tf-init warning
# 	@cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
# 		terraform apply $(arg)

# k1-tf-destroy: k1-load-env warning
# 	@cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
# 		terraform destroy $(arg)

# k1-tf-refresh: k1-load-env
# 	@cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
# 		terraform refresh

# k1-tf-output: k1-load-env
# 	@cd ${K1_CONFIG} && cd ${TF_CONFIG} && \
# 		terraform output -json > output.json

k1-apply: warning
	@cd ${K1_CONFIG} && \
		$(KUBEONE_BINARY) ${K1_CRED_FLAG} apply $(arg) -m $(ENVIRONMENT).yaml --verbose ${K1_EXTRA_ARG}
	make k1-kubeconfig
	# make k1-apply-md

k1-reset: warning
	@cd ${K1_CONFIG} && \
		$(KUBEONE_BINARY) ${K1_CRED_FLAG} reset $(arg) -m $(ENVIRONMENT).yaml  --verbose ${K1_EXTRA_ARG}

k1-kubeconfig:
	@cd ${K1_CONFIG} && \
		$(KUBEONE_BINARY) ${K1_CRED_FLAG} kubeconfig -m $(ENVIRONMENT).yaml > ${K1_KUBECONFIG} && \
		chmod 0600 ${K1_KUBECONFIG}

# e.g. darwin, windows
export BIN_OS ?=linux
# e.g. arm64
export BIN_ARCH ?=amd64
download-kubeone-release:
	@$(eval KUBEONE_OLD=$(shell $(KUBEONE_BINARY) version | jq -r .kubeone.gitVersion))
	@test ${KUBEONE_OLD} = $(shell $(KUBEONE_BINARY) version | jq -r .kubeone.gitVersion) && echo "OK: kubeone version still up to date" || echo "\033[41;101mERROR:\033[0m kubeone binary not up to date, downloading new version"
	@test -f $(KUBEONE_BINARY) && cp $(KUBEONE_BINARY) $(KUBEONE_BINARY)_${KUBEONE_OLD} || (echo "\033[41;101mERROR:\033[0m kubeone binary not found, downloading now")
	# @cp $(KUBEONE_BINARY) $(KUBEONE_BINARY)_${KUBEONE_OLD} || exit 0
	@wget https://github.com/kubermatic/kubeone/releases/download/v${KUBEONE_VERSION}/kubeone_$(KUBEONE_VERSION)_${BIN_OS}_${BIN_ARCH}.zip -O kubeone_$(KUBEONE_VERSION)_${BIN_OS}_${BIN_ARCH}.zip
	@unzip -o kubeone_$(KUBEONE_VERSION)_${BIN_OS}_${BIN_ARCH}.zip 'kubeone' -d ${ROOT_DIR}/
	# @unzip -oj kubeone_$(KUBEONE_VERSION)_${BIN_OS}_${BIN_ARCH}.zip 'addons/default-storage-class/*' -d addons/default-storage-class_v$(KUBEONE_VERSION)
	# @unzip -oj kubeone_$(KUBEONE_VERSION)_${BIN_OS}_${BIN_ARCH}.zip 'addons/unattended-upgrades/*' -d addons/unattended-upgrades_v$(KUBEONE_VERSION)
	@rm kubeone_$(KUBEONE_VERSION)_${BIN_OS}_${BIN_ARCH}.zip