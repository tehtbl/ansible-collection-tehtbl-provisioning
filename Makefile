################################################################################
# Variables
################################################################################

# shell to use
SHELL := /bin/bash

# Config Dirs
MY_DIR := $(shell echo $(shell cd "$(shell dirname "${BASH_SOURCE[0]}" )" && pwd ))

VENV_DIR := $(MY_DIR)/.venv3

# Required execs
REQUIRED_EXECUTABLES := python3

################################################################################
# Macros / Methods
################################################################################

ifdef CI_API_V4_URL
	REQUIRED_EXECUTABLES := python3
endif

# check for executables in $PATH
K := $(foreach exec,$(REQUIRED_EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "Program $(exec) not in PATH")))

# based on: https://stackoverflow.com/questions/10858261/abort-makefile-if-variable-not-set
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

ifneq ($(wildcard $(VENV_DIR)),)
	read_yaml_key = $(shell $(VENV_DIR)/bin/python3 -c "import yaml; print(yaml.load(open('$(1)'), Loader=yaml.BaseLoader)['$(2)'])")

	CLTN_NAME := $(call read_yaml_key,"$(MY_DIR)/galaxy.yml","name")
	CLTN_NAMESPACE := $(call read_yaml_key,"$(MY_DIR)/galaxy.yml","namespace")
	CLTN_VERSION := $(call read_yaml_key,"$(MY_DIR)/galaxy.yml","version")
	CLTN_FILE := $(CLTN_NAMESPACE)-$(CLTN_NAME)-$(CLTN_VERSION).tar.gz
	CLTN_DIR := build
	# NOTE: Keep lists of modules and roles in sync with README.md
	CLTN_MODULES :=
	CLTN_ROLES := $(shell cd roles && ls -1)
endif


################################################################################
# Makefile TARGETS
################################################################################

.DEFAULT_GOAL := help

#
# Help
#
# based to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help list
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

list: ## list all Makefile targets
	@make -qp | grep -E '^[[:alnum:]_]+' | grep -Ev ' :?= ' | grep -E ':' | cut -d ':' -f 1 | sort | uniq

#
# clean up tasks
#
.PHONY: clean clean_all
clean: ## removes build dir and others

clean_all: clean venv_remove

#
# virtual env tasks
#
.PHONY: venv venv_mkdir venv_remove
venv: venv_mkdir ## install python dependencies
	@test -d $(VENV_DIR) && \
		$(VENV_DIR)/bin/pip install --upgrade pip && \
		$(VENV_DIR)/bin/pip install -r $(MY_DIR)/pip-requirements.txt

venv_mkdir: venv_remove
	@test -d $(VENV_DIR) || python3 -m venv $(VENV_DIR)

venv_remove: ## remove venv dir
	@-test -d $(VENV_DIR) && rm -rf $(VENV_DIR)

#
#
#
$(CLTN_DIR)/$(CLTN_FILE):
	@echo "$(CLTN_DIR)/$(CLTN_FILE)"; \
	build_dir=$$(readlink $(CLTN_DIR) ); \
	[ ! -d .cache/build/ ] || rm -rf .cache/build/ && \
	mkdir -p .cache/build && \
	git archive master | tar -x -C .cache/build/ && \
	cd .cache/build/ && \
	$(VENV_DIR)/bin/ansible-galaxy collection build --output-path "$$build_dir"
# Build in a clean subdir without any ignored files and directories is required because Ansible Galaxy prior to 2.10
# does not support the 'build_ignore' flag in the collection metadata file 'galaxy.yml'.
# Ref.: https://docs.ansible.com/ansible/latest/dev_guide/collections_galaxy_meta.html

.PHONY: build-collection
build-collection: $(CLTN_DIR)/$(CLTN_FILE)

#
#
#
.PHONY: help-modules
help-modules:
ifneq ($(CLTN_MODULES),)
	cd $(MY_DIR) && \
		$(VENV_DIR)/bin/ansible-doc --type module $(addprefix "$(CLTN_NAMESPACE).$(CLTN_NAME).",$(CLTN_MODULES))
endif

#
#
#
.PHONY: install-required-collections install-required-roles install-requirements
install-required-collections:
	cd $(MY_DIR) && \
		$(VENV_DIR)/bin/ansible-galaxy collection install --requirements-file requirements.yml

install-required-roles:
	cd $(MY_DIR) && \
		$(VENV_DIR)/bin/ansible-galaxy role install --role-file requirements.yml

install-requirements: install-required-collections install-required-roles

#
#
#
.PHONY: lint lint-ansible-lint lint-flake8 lint-yamllint
lint: lint-ansible-lint lint-flake8 lint-yamllint

# NOTE: Keep linting targets and its options in sync with official Ansible Galaxy linters at
#       https://github.com/ansible/galaxy/blob/master/galaxy/importer/linters/__init__.py

lint-ansible-lint: # lint roles
ifneq ($(CLTN_ROLES),)
	cd $(MY_DIR) && \
		$(VENV_DIR)/bin/ansible-lint --offline \
		-p \
		$(addprefix "roles/",$(CLTN_ROLES)) \
		|| { [ "$?" = 2 ] && true; }
# ansible-lint exit code 1 is app exception, 0 is no linter err, 2 is linter err
endif

lint-yamllint: # lint apbs und roles
ifneq ($(CLTN_ROLES),)
	cd $(MY_DIR) && \
		$(VENV_DIR)/bin/yamllint \
		-f parsable \
		-c '$(MY_DIR)/.yamllint.yml' \
		-- \
		$(addprefix "roles/",$(CLTN_ROLES))
endif

#
#
#
.PHONY: publish-collection
publish-collection:
	cd $(MY_DIR) && \
		$(VENV_DIR)/bin/ansible-galaxy collection publish $(CLTN_DIR)/$(CLTN_FILE)
