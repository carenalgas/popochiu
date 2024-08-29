CURRENT_UID := $(shell id -u):$(shell id -g)

all: docs-up

docs-up:
	docker compose pull
	docker compose up -d --remove-orphans

docs-down:
	docker compose down

docs-restart: docs-down docs-up

docs-rebuild:
	docker compose build --no-cache

docs-deploy: docs-extract
	rm -rf ./dist && git restore dist
	docker compose run \
		--rm \
		--user ${CURRENT_UID} \
		documentation \
		mkdocs build --verbose
	GIT_DEPLOY_USERNAME="$(shell git config user.name)" GIT_DEPLOY_MAIL="$(shell git config user.email)" scripts/deploy_to_ghpages

docs-extract:
	docker compose run \
		--rm \
		--user $(CURRENT_UID) \
		docs-extractor /project \
		-o /output \
		-d addons/popochiu/engine/

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
