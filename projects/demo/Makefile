.PHONY: up down logs ps

up: ## Start this project's stack
	docker compose up -d

down: ## Stop this project's stack
	docker compose down

logs: ## Tail this project's logs
	docker compose logs -f

ps: ## Show this project's running containers
	docker compose ps
