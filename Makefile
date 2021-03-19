DOCKER_IMAGE_NAME ?= asciidoctor-toolkit
DOCKERHUB_USERNAME ?= gbif
DOCKER_IMAGE_TAG ?= 1.3.0c
DOCKER_IMAGE_NAME_TO_TEST ?= $(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME):latest

export DOCKER_IMAGE_NAME_TO_TEST

all: build deploy

build:
	docker build \
		-t $(DOCKER_IMAGE_NAME_TO_TEST) \
		-f Dockerfile \
		$(CURDIR)/

deploy:
	git tag $(DOCKER_IMAGE_TAG)
	# latest
	docker push $(DOCKER_IMAGE_NAME_TO_TEST)

	# with version number
	docker tag $(DOCKER_IMAGE_NAME_TO_TEST) $(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
	docker push $(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

	# latest
	docker tag $(DOCKER_IMAGE_NAME_TO_TEST) docker.gbif.org/$(DOCKER_IMAGE_NAME):latest
	docker push docker.gbif.org/$(DOCKER_IMAGE_NAME):latest

	# with version number
	docker tag $(DOCKER_IMAGE_NAME_TO_TEST) docker.gbif.org/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
	docker push docker.gbif.org/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

.PHONY: all build test deploy
