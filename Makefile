DOCKER ?= docker
DOCKER_COMPOSE ?= docker-compose

DOCKER_COMPOSE_UP_OPT =
SHELL = /bin/sh

TMPDIR ?= $(PWD)/.tmp

# generated outputs
#
FILES = docker-compose.yml traefik.yml

CONFIG_MK = config.mk
GEN_MK = gen.mk

# scripts
#
CONFIG_MK_SH = $(CURDIR)/scripts/config_mk.sh
GET_VARS_SH = $(CURDIR)/scripts/get_vars.sh
GEN_MK_SH = $(CURDIR)/scripts/gen_mk.sh

# colours
#
PYGMENTIZE ?= $(shell which pygmentize)

ifneq ($(PYGMENTIZE),)
COLOUR_YAML = $(PYGMENTIZE) -l yaml
COLOUR_JSON = $(PYGMENTIZE) -l json
else
COLOUR_YAML = cat
COLOUR_JSON = cat
endif

# variables
#
TEMPLATES = $(addsuffix .in, $(FILES))
DEPS = $(GET_VARS_SH) $(TEMPLATES) Makefile
GEN_MK_VARS = $(shell $(GET_VARS_SH) $(TEMPLATES))

.PHONY: all files clean files pull build
.PHONY: up start stop restart logs
.PHONY: config inspect
ifneq ($(SHELL),)
.PHONY: shell
endif

all: pull build

#
#
clean:
	rm -rf $(FILES) $(TMPDIR) *~

.gitignore: Makefile
	for x in $(FILES); do \
		grep -q "^/$$x$$" $@ || echo "/$$x" >> $@; \
	done
	touch $@

$(GEN_MK): $(GEN_MK_SH) $(DEPS)
	$< $(GEN_MK_VARS) > $@~
	mv $@~ $@

$(CONFIG_MK): $(CONFIG_MK_SH) $(DEPS)
	$< $@ $(GEN_MK_VARS)
	touch $@

files: $(FILES) $(CONFIG_MK) $(GEN_MK) .gitignore $(TMPDIR)/ca.fingerprint

pull: files
	$(DOCKER_COMPOSE) pull

build: files
	$(DOCKER_COMPOSE) build --pull

include $(GEN_MK)
include $(CONFIG_MK)

export COMPOSE_PROJECT_NAME=$(NAME)

up: files
	$(DOCKER_COMPOSE) up $(DOCKER_COMPOSE_UP_OPT)

start: files
	chmod 0600 acme.json
	$(DOCKER) network list | grep -q " $(TRAEFIK_BRIDGE) " || $(DOCKER) network create $(TRAEFIK_BRIDGE)
	env CA_FINGERPRINT=$(cat $(TMPDIR)/ca.fingerprint) \
		       $(DOCKER_COMPOSE) up -d $(DOCKER_COMPOSE_UP_OPT)

stop: files
	$(DOCKER_COMPOSE) down --remove-orphans
	$(DOCKER) network rm $(TRAEFIK_BRIDGE)

restart: files
	chmod 0600 acme.json
	$(DOCKER_COMPOSE) restart

logs: files
	$(DOCKER_COMPOSE) logs -f

ifneq ($(SHELL),)
shell: files
	$(DOCKER_COMPOSE) exec $(NAME) $(SHELL)
endif

config: files
	$(DOCKER_COMPOSE) config | $(COLOUR_YAML)
	$(COLOUR_YAML) traefik.yml
	$(COLOUR_JSON) acme.json

inspect:
	$(DOCKER_COMPOSE) ps
	$(DOCKER) network inspect -v $(TRAEFIK_BRIDGE) | $(COLOUR_YAML)

# CA
#
.PHONY: ca
ca: $(TMPDIR)/ca.fingerprint

step/secrets/password:
	mkdir -p $(@D)
	$(PWGEN_CMD) 20 > $@~
	mv $@~ $@

step/config/ca.json: step/secrets/password
	$(STEP_CMD) ca init $(STEP_CA_INIT_ARGS) \
		--provisioner-password-file=secrets/password \
		--password-file=secrets/password

$(TMPDIR)/ca.fingerprint: step/config/ca.json
	@mkdir -p $(@D)
	$(STEP_CMD) certificate fingerprint \
		certs/root_ca.crt > $@~
	mv $@~ $@
