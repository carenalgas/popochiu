CURRENT_UID := $(shell id -u):$(shell id -g)

all: docs-up

docs-up:
	docker compose pull
	docker compose up -d --remove-orphans

docs-down:
	docker compose down

docs-deploy:
	docker compose run \
		--rm \
		--user ${CURRENT_UID} \
		documentation \
		mkdocs build --verbose

docs-extract:
	docker compose run \
		--rm \
		--user $(CURRENT_UID) \
		docs-generator /project \
		-o /output \
		-d addons/popochiu/engine/

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
