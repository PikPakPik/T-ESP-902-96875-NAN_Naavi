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