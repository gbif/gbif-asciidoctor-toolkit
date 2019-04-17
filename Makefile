
DOCKER_IMAGE_NAME ?= docker-asciidoctor
DOCKERHUB_USERNAME ?= asciidoctor
DOCKER_IMAGE_TEST_TAG ?= $(shell git rev-parse --short HEAD)
#DOCKER_IMAGE_NAME_TO_TEST ?= $(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TEST_TAG)
DOCKER_IMAGE_NAME_TO_TEST ?= mb.gbif.org:5000/gbif-asciidoctor-toolkit
ASCIIDOCTOR_VERSION ?= 2.0.6
ASCIIDOCTOR_CONFLUENCE_VERSION ?= 0.0.2
ASCIIDOCTOR_PDF_VERSION ?= 1.5.0.alpha.16
ASCIIDOCTOR_DIAGRAM_VERSION ?= 1.5.16
ASCIIDOCTOR_EPUB3_VERSION ?= 1.5.0.alpha.9
ASCIIDOCTOR_MATHEMATICAL_VERSION ?= 0.3.0
ASCIIDOCTOR_REVEALJS_VERSION ?= 2.0.0
CURRENT_GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

export DOCKER_IMAGE_NAME_TO_TEST \
  ASCIIDOCTOR_VERSION \
  ASCIIDOCTOR_CONFLUENCE_VERSION \
  ASCIIDOCTOR_PDF_VERSION \
  ASCIIDOCTOR_DIAGRAM_VERSION \
  ASCIIDOCTOR_EPUB3_VERSION \
  ASCIIDOCTOR_MATHEMATICAL_VERSION \
  ASCIIDOCTOR_REVEALJS_VERSION

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
#	curl -H "Content-Type: application/json" \
#		--data '{"source_type": "Branch", "source_name": "$(CURRENT_GIT_BRANCH)"}' \
#		-X POST https://registry.hub.docker.com/u/$(DOCKERHUB_USERNAME)/$(DOCKER_IMAGE_NAME)/trigger/$(DOCKER_HUB_TOKEN)/

.PHONY: all build test deploy
