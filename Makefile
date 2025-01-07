APPLY_CONFIGS ?= false
CLEAN_AFTER_BUILD ?= false
ENV_FILES ?= "x86_64.json"
EXIT_AFTER_BUILD ?= false
NO_BUILD ?= false
VERBOSE ?= false
TARGET ?= retroroot_x86_64_KMS

.PHONY: help
help:
	@printf "Environment variables:\n"
	@printf '\tAPPLY_CONFIGS: Reapply all config files. Default: false\n'
	@printf "\tCLEAN_AFTER_BUILD: run 'make clean' after a build is finished. Default: false\n"
	@printf "\tENV_FILES: Specify a space-deliminated list of environment files in the docker directory to apply. Default: x86_64.json\n"
	@printf "\tEXIT_AFTER_BUILD: Exit the container after a build. Default: false\n"
	@printf "\tNO_BUILD: Do not build any config. Default: false\n"
	@printf "\tVERBOSE: Run make instead of brmake. Default: false\n"
	@printf "\tTARGET: Specify the target of which to run menuconfig. Default: retroroot_x86_64_KMS\n"
	@printf "\n"
	@printf "Targets:\n"
	@printf "\tbuild: build the docker container.\n"
	@printf "\tdown: Stop the dodcker container.\n"
	@printf "\tkill: kill the docker container forcefully.\n"
	@printf "\tmenuconfig: run menuconfig on a given target. Default: retroroot_x86_64_KMS\n"
	@printf "\tshell: Run the docker container, do not build anyhting, and open a shell in the docker container.\n"
	@printf "\tup: Run docker compose up with the above environment variables.\n"
	@printf "\tupd: Run docker compose up -d with the above environment variables.\n"
	@printf "\n"
	@printf "Other:\n"
	@printf "x64-run: Run the x64 virtual image. Requires virbr0 and /dev/kvm to exist."
	@printf "\n\n"

.PHONY: build
build:
	@docker compose build

.PHONY: down
down:
	@docker compose down

.PHONY: menuconfig
menuconfig:
	@/bin/bash -c 'make kill && make APPLY_CONFIGS=${APPLY_CONFIGS} NO_BUILD=true upd; if [[ ${APPLY_CONFIGS} == "true" ]]; then sleep 5; fi'
	@docker exec -it buildroot-retroarch /bin/bash -c 'cd ~/buildroot/retroarch/output/${TARGET} && make menuconfig'

.PHONY: kill
kill:
	docker compose kill

.PHONY: shell
shell:
	@/bin/bash -c 'if [ -z $(docker container ps -aqf "name=buildroot-retroarch") ]; then make APPLY_CONFIGS=${APPLY_CONFIGS} NO_BUILD=true EXIT_AFTER_BUILD=false upd; fi;'
	@/bin/bash -c 'if [[ ${APPLY_CONFIGS} == "true" ]]; then sleep 5; fi'
	@docker exec -it buildroot-retroarch /bin/bash

.PHONY: up
up:
	APPLY_CONFIGS=${APPLY_CONFIGS} \
	VERBOSE=${VERBOSE} \
	ENV_FILES=${ENV_FILES} \
	EXIT_AFTER_BUILD=${EXIT_AFTER_BUILD} \
	NO_BUILD=${NO_BUILD} \
	CLEAN_AFTER_BUILD=${CLEAN_AFTER_BUILD} \
	docker compose up --abort-on-container-exit

.PHONY: upd
upd:
	APPLY_CONFIGS=${APPLY_CONFIGS} \
	VERBOSE=${VERBOSE} \
	ENV_FILES=${ENV_FILES} \
	EXIT_AFTER_BUILD=${EXIT_AFTER_BUILD} \
	NO_BUILD=${NO_BUILD} \
	CLEAN_AFTER_BUILD=${CLEAN_AFTER_BUILD} \
	docker compose up -d

.PHONY: x64-run
x64-run:
	@/bin/bash retroarch/board/x86_64/kms/qemu-run.sh
