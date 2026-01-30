SHELL := /bin/bash

.PHONY: up
build:
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

.PHONY: compile-local
compile-local:
    docker compose exec spring ./mvnw -Pdev install clean compile