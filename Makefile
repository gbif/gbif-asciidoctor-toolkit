DOCKER_IMAGE_NAME ?= asciidoctor-toolkit
DOCKERHUB_USERNAME ?= gbif
#DOCKER_IMAGE_TEST_TAG ?= $(shell git rev-parse --short HEAD)
DOCKER_IMAGE_TAG ?= latest
DOCKER_IMAGE_NAME_TO_TEST ?= $(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

export DOCKER_IMAGE_NAME_TO_TEST

all: build deploy
# build test deploy

build:
	docker build \
		-t $(DOCKER_IMAGE_NAME_TO_TEST) \
		-f Dockerfile \
		$(CURDIR)/

test:
	bats $(CURDIR)/tests/*.bats

deploy:
	docker push $(DOCKER_IMAGE_NAME_TO_TEST)

.PHONY: all build test deploy
