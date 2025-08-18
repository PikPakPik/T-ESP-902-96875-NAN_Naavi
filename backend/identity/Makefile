SHELL := /bin/bash

.PHONY: build
build:
	sed -i 's/\r$$//' .docker/java/watch.sh || true
	@docker network ls | grep -q naavi-network || docker network create naavi-network
	@docker volume inspect naavi_shared_data >/dev/null 2>&1 || docker volume create naavi_shared_data
	docker compose up --build -d

.PHONY: down
down:
	docker compose down --remove-orphans -v --rmi all

.PHONY: re-build
re-build:
	$(MAKE) down
	$(MAKE) build

.PHONY: quality
quality:
	docker compose exec spring ./mvnw checkstyle:check || true
	docker compose exec spring ./mvnw pmd:check || true
	docker compose exec spring ./mvnw spotbugs:spotbugs || true

.PHONY: bash
bash:
	docker compose exec -it spring /bin/sh
