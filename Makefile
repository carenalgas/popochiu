all: up

up:
	docker compose pull
	docker compose up -d

down:
	docker compose down

cli:
	docker compose run --rm documentation bash

logs:
	docker compose logs -f
