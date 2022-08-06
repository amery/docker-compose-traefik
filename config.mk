STEP_CMD ?= $(DOCKER) run -v $(PWD)/step:/home/step smallstep/step-ca step
PWGEN_CMD ?= $(DOCKER) run ghcr.io/komed-health/pwgen
TRAEFIK_BRIDGE ?= traefiknet
TRAEFIK_PORT ?= 127.0.0.1:8080
NAME ?= traefik
HOSTNAME ?= $(NAME).docker.localhost
ACME_EMAIL ?= acme-master@example.org
STEP_CA_NAME ?= Example Org
STEP_CA_HOSTNAME ?= ca.docker.localhost
STEP_CA_DNS ?= $(STEP_CA_HOSTNAME),127.0.0.1,$(hostname -f)
STEP_CA_PORT ?= 443
STEP_CA_INIT_ARGS ?= --ssh --deployment-type=standalone --name="$(STEP_CA_NAME)" --dns=$(STEP_CA_DNS) --address=:$(STEP_CA_PORT) --provisioner=$(ACME_EMAIL)
