.PHONY: help infra-up infra-down infra-logs new-project project-up project-down logs deploy

help: ## Show this help
	@echo "Available targets:"
	@echo "  help                  Show this help"
	@echo "  infra-up              Start shared infrastructure (Traefik, Portainer, ...)"
	@echo "  infra-down            Stop shared infrastructure"
	@echo "  infra-logs            Tail shared infrastructure logs"
	@echo "  new-project name=X    Scaffold a new project from projects/_template"
	@echo "  project-up name=X     Start a project's stack"
	@echo "  project-down name=X   Stop a project's stack"
	@echo "  logs name=X           Tail a project's logs"
	@echo "  deploy                Deploy (wired in CP4)"

infra-up: ## Start shared infrastructure
	docker compose -f infrastructure/docker-compose.yml up -d

infra-down: ## Stop shared infrastructure
	docker compose -f infrastructure/docker-compose.yml down

infra-logs: ## Tail shared infrastructure logs
	docker compose -f infrastructure/docker-compose.yml logs -f

new-project: ## Scaffold a new project from the template (name=X required)
ifndef name
	$(error name is required, e.g. make new-project name=demo)
endif
	cp -r projects/_template projects/$(name)
	@echo "Created projects/$(name)"

project-up: ## Start a project's stack (name=X required)
ifndef name
	$(error name is required, e.g. make project-up name=demo)
endif
	docker compose -f projects/$(name)/docker-compose.yml up -d

project-down: ## Stop a project's stack (name=X required)
ifndef name
	$(error name is required, e.g. make project-down name=demo)
endif
	docker compose -f projects/$(name)/docker-compose.yml down

logs: ## Tail a project's logs (name=X required)
ifndef name
	$(error name is required, e.g. make logs name=demo)
endif
	docker compose -f projects/$(name)/docker-compose.yml logs -f

deploy: ## Deploy
	@echo "wired in CP4"
