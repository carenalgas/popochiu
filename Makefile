CURRENT_UID := $(shell id -u):$(shell id -g)

all: up

docs-up:
	docker compose pull
	docker compose up -d

docs-down:
	docker compose down

gdm-build:
	docker build \
		--no-cache \
		--build-arg="DOCKER_USER_UID=$(shell id -u)" \
		--build-arg="DOCKER_USER_GID=$(shell id -g)" \
		-t popochiu-docs-maker:latest \
		-f Dockerfile.DocsMaker .

gdm-generate:
	docker run --rm \
		-v .:/project \
		-v ./docs/content/the-engine-handbook/scripting-reference:/output \
		-u $(CURRENT_UID) \
		popochiu-docs-maker:latest /project \
		-o /output \
		-d addons/popochiu/engine/

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
