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
		gdquest/gdscript-docs-maker:master /project \
		-o /output \
		-d addons/popochiu/engine/

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
