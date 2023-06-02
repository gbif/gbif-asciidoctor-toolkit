DOCKER_IMAGE_NAME ?= asciidoctor-toolkit
DOCKER_HOST ?= docker.gbif.org
DOCKER_IMAGE_TAG ?= 1.49.0b
GBIF_ASCIIDOCTOR_TOOLKIT_VERSION ?= $(DOCKER_IMAGE_TAG)
DOCKER_IMAGE_NAME_TO_TEST ?= $(DOCKER_HOST)/$(DOCKER_IMAGE_NAME):latest

export DOCKER_IMAGE_NAME_TO_TEST

all: build deploy

build:
	docker build \
		--build-arg GBIF_ASCIIDOCTOR_TOOLKIT_VERSION=$(GBIF_ASCIIDOCTOR_TOOLKIT_VERSION) \
		-t $(DOCKER_IMAGE_NAME_TO_TEST) \
		-f Dockerfile \
		$(CURDIR)/

deploy:
	git tag $(DOCKER_IMAGE_TAG)
	# latest
	docker push $(DOCKER_IMAGE_NAME_TO_TEST)

	# with version number
	docker tag $(DOCKER_IMAGE_NAME_TO_TEST) $(DOCKER_HOST)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
	docker push $(DOCKER_HOST)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

.PHONY: all build test deploy
