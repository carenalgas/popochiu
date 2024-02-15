CURRENT_UID := $(shell id -u):$(shell id -g)

all: up

up:
	docker compose pull
	docker compose up -d

down:
	docker compose down

api-docs:
	docker run --rm \
		-v .:/project \
		-v ./docs/content/the-engine-handbook/scripting-reference:/output \
		-u $(CURRENT_UID) \
		popochiu-docs-maker:gdm-1.7.0 /project \
		-o /output \
		-d addons/popochiu/engine/

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
