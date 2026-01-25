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
	rm -rf src/the-engine-handbook/scripting-reference/*.md && \
	git restore src/the-engine-handbook/scripting-reference/index.md
	docker compose run \
		--rm \
		--user $(CURRENT_UID) \
		documentation \
		python scripts/generate_reference.py \
		/project/addons/popochiu/engine \
		-o src/the-engine-handbook/scripting-reference

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
