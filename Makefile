# Local LLM Service Makefile
# Comprehensive automation for development, deployment, and maintenance

.PHONY: help setup install clean build start stop restart status logs health models test lint check dev prod docker-up docker-down docker-restart docker-logs docker-clean

# Default target
.DEFAULT_GOAL := help

# Variables
DOCKER_COMPOSE := $(shell which docker-compose 2>/dev/null || echo "docker compose")
API_URL := http://localhost:3007
APP_CONTAINER := llm-api-service
OLLAMA_CONTAINER := ollama-service
POSTGRES_CONTAINER := postgres-rag

# Load API_KEY from .env file if not set in environment
ifeq ($(API_KEY),)
API_KEY := $(shell grep -E '^API_KEY=' .env 2>/dev/null | cut -d'=' -f2)
endif

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

##@ Help
help: ## Display this help message
	@echo "Local LLM Service - Makefile Commands"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup and Installation
setup: ## Complete project setup (docker, environment)
	@echo "$(BLUE)[INFO]$(NC) Starting complete project setup..."
	@$(MAKE) check-requirements
	@$(MAKE) init
	@$(MAKE) docker-up
	@$(MAKE) wait-services
	@echo "$(GREEN)[SUCCESS]$(NC) Setup completed! Run 'make models-essential' to download models"

check-requirements: ## Check system requirements
	@echo "$(BLUE)[INFO]$(NC) Checking system requirements..."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)[ERROR]$(NC) Docker is not installed. Please install Docker first"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "$(RED)[ERROR]$(NC) Docker daemon is not running. Please start Docker"; \
		exit 1; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) System requirements OK"

init: ## Initialize project (create directories, copy .env)
	@echo "$(BLUE)[INFO]$(NC) Initializing project structure..."
	@mkdir -p logs docker/ollama docker/postgres
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)[SUCCESS]$(NC) Created .env file from template"; \
		echo "$(YELLOW)[WARNING]$(NC) Please edit .env file and set your API_KEY"; \
	else \
		echo "$(BLUE)[INFO]$(NC) .env file already exists"; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) Project initialized"

##@ Development
dev: ## Start development environment (all containers)
	@echo "$(BLUE)[INFO]$(NC) Starting development environment..."
	@$(DOCKER_COMPOSE) up --build

dev-detached: ## Start development environment in background
	@echo "$(BLUE)[INFO]$(NC) Starting development environment in background..."
	@$(DOCKER_COMPOSE) up -d --build
	@echo "$(GREEN)[SUCCESS]$(NC) Development environment started"

build: ## Build all Docker containers
	@echo "$(BLUE)[INFO]$(NC) Building Docker containers..."
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)[SUCCESS]$(NC) Build completed"

start: ## Start all services in production mode
	@echo "$(BLUE)[INFO]$(NC) Starting production services..."
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)[SUCCESS]$(NC) All services started"

stop: ## Stop all containers
	@echo "$(BLUE)[INFO]$(NC) Stopping all containers..."
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)[SUCCESS]$(NC) All containers stopped"

restart: ## Restart all containers
	@echo "$(BLUE)[INFO]$(NC) Restarting all containers..."
	@$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)[SUCCESS]$(NC) All containers restarted"

hard-restart: ## Hard restart with rebuild
	@echo "$(BLUE)[INFO]$(NC) Hard restart with rebuild..."
	@$(DOCKER_COMPOSE) down
	@$(DOCKER_COMPOSE) up -d --build
	@echo "$(GREEN)[SUCCESS]$(NC) Hard restart completed"

##@ Docker Services
docker-up: ## Start all Docker services
	@echo "$(BLUE)[INFO]$(NC) Starting all Docker services..."
	@$(DOCKER_COMPOSE) up -d --build
	@echo "$(GREEN)[SUCCESS]$(NC) All Docker services started"

docker-down: ## Stop all Docker services
	@echo "$(BLUE)[INFO]$(NC) Stopping all Docker services..."
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)[SUCCESS]$(NC) All Docker services stopped"

docker-restart: ## Restart all Docker services
	@echo "$(BLUE)[INFO]$(NC) Restarting all Docker services..."
	@$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)[SUCCESS]$(NC) All Docker services restarted"

docker-logs: ## Show Docker services logs
	@$(DOCKER_COMPOSE) logs -f

docker-status: ## Show all Docker services status
	@$(DOCKER_COMPOSE) ps

docker-clean: ## Clean Docker volumes and containers
	@echo "$(YELLOW)[WARNING]$(NC) This will remove all Docker data..."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(DOCKER_COMPOSE) down -v
	@docker system prune -f
	@echo "$(GREEN)[SUCCESS]$(NC) Docker cleanup completed"

wait-services: ## Wait for Docker services to be ready
	@echo "$(BLUE)[INFO]$(NC) Waiting for services to be ready..."
	@timeout 60 bash -c 'until curl -f http://localhost:11434/api/tags >/dev/null 2>&1; do sleep 2; done' || \
		echo "$(YELLOW)[WARNING]$(NC) Ollama might not be ready yet"
	@timeout 60 bash -c 'until $(DOCKER_COMPOSE) exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do sleep 2; done' || \
		echo "$(YELLOW)[WARNING]$(NC) PostgreSQL might not be ready yet"
	@echo "$(GREEN)[SUCCESS]$(NC) Services are ready"

##@ Model Management
models: ## Show available models for download
	@echo ""
	@echo "📋 Available models for download:"
	@echo ""
	@echo "1. qwen3:14b (9GB) - Main universal model"
	@echo "   Purpose: chat, RAG, agents, document analysis"
	@echo ""
	@echo "2. qwen2.5-coder:14b (9GB) - Programming specialized"
	@echo "   Purpose: NodeJS, TypeScript, React, PHP, SQL"
	@echo ""
	@echo "3. gemma3:12b (8GB) - Google model"
	@echo "   Purpose: alternative, sometimes better results"
	@echo ""
	@echo "4. nomic-embed-text (300MB) - Embeddings model"
	@echo "   Purpose: text vectorization for RAG"
	@echo ""
	@echo "5. phi4:14b (8GB) - Microsoft model"
	@echo "   Purpose: excellent logic, math reasoning"
	@echo ""
	@echo "Commands:"
	@echo "  make models-essential  # Download essential models"
	@echo "  make models-all       # Download all recommended models"
	@echo "  make models-list      # List downloaded models"

models-essential: ## Download essential models (qwen3:14b + nomic-embed-text)
	@echo "$(BLUE)[INFO]$(NC) Downloading essential models..."
	@./scripts/download-models.sh --essential

models-all: ## Download all recommended models
	@echo "$(BLUE)[INFO]$(NC) Downloading all recommended models..."
	@./scripts/download-models.sh --all

models-list: ## List downloaded models
	@echo "$(BLUE)[INFO]$(NC) Listing downloaded models..."
	@docker exec $(OLLAMA_CONTAINER) ollama list

models-pull: ## Download specific model (usage: make models-pull MODEL=qwen3:14b)
	@if [ -z "$(MODEL)" ]; then \
		echo "$(RED)[ERROR]$(NC) Please specify MODEL. Usage: make models-pull MODEL=qwen3:14b"; \
		exit 1; \
	fi
	@echo "$(BLUE)[INFO]$(NC) Downloading model: $(MODEL)"
	@docker exec $(OLLAMA_CONTAINER) ollama pull $(MODEL)

models-remove: ## Remove specific model (usage: make models-remove MODEL=qwen3:14b)
	@if [ -z "$(MODEL)" ]; then \
		echo "$(RED)[ERROR]$(NC) Please specify MODEL. Usage: make models-remove MODEL=qwen3:14b"; \
		exit 1; \
	fi
	@echo "$(BLUE)[INFO]$(NC) Removing model: $(MODEL)"
	@docker exec $(OLLAMA_CONTAINER) ollama rm $(MODEL)

##@ Health and Monitoring
status: ## Show overall system status
	@echo "$(BLUE)[INFO]$(NC) System Status Check..."
	@echo ""
	@echo "📊 Docker Services:"
	@$(MAKE) docker-status
	@echo ""
	@echo "🏥 Health Checks:"
	@$(MAKE) health
	@echo ""
	@echo "📦 Downloaded Models:"
	@$(MAKE) models-list 2>/dev/null || echo "  No models downloaded yet"

health: ## Check service health
	@echo "API Service: $$(curl -s -o /dev/null -w "%{http_code}" $(API_URL)/health 2>/dev/null | \
		awk '{if($$1=="200") print "✅ Healthy"; else print "❌ Unhealthy (HTTP " $$1 ")"}')"
	@echo "Ollama: $$(curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/tags 2>/dev/null | \
		awk '{if($$1=="200") print "✅ Running"; else print "❌ Not responding"}')"
	@echo "PostgreSQL: $$($(DOCKER_COMPOSE) exec -T postgres pg_isready -U postgres >/dev/null 2>&1 && echo "✅ Ready" || echo "❌ Not ready")"

logs: ## Show application logs
	@if [ -f logs/app.log ]; then \
		tail -f logs/app.log; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) No log file found. Start the application first."; \
	fi

logs-docker: docker-logs ## Alias for docker-logs

##@ Testing and Quality
test: ## Run tests
	@echo "$(BLUE)[INFO]$(NC) Running tests..."
	@npm test

lint: ## Run ESLint
	@echo "$(BLUE)[INFO]$(NC) Running ESLint..."
	@npm run lint

lint-fix: ## Fix ESLint issues
	@echo "$(BLUE)[INFO]$(NC) Fixing ESLint issues..."
	@npm run lint:fix

check: lint test ## Run all checks (lint + tests)

##@ API Testing
api-test: ## Test API endpoints (containerized)
	@echo "$(BLUE)[INFO]$(NC) Testing API endpoints..."
	@echo ""
	@echo "🏥 Health Check:"
	@curl -s $(API_URL)/health | jq . 2>/dev/null || curl -s $(API_URL)/health
	@echo ""
	@echo ""
	@echo "📋 Models List:"
	@if [ -z "$(API_KEY)" ]; then \
		echo "$(YELLOW)[WARNING]$(NC) API_KEY not found in .env file. Please set it first."; \
	else \
		echo "$(BLUE)[INFO]$(NC) Using API_KEY: $(API_KEY)"; \
		curl -s -H "Authorization: Bearer $(API_KEY)" $(API_URL)/v1/models | jq . 2>/dev/null || \
		curl -s -H "Authorization: Bearer $(API_KEY)" $(API_URL)/v1/models; \
	fi

api-test-internal: ## Test API endpoints from inside Docker network
	@echo "$(BLUE)[INFO]$(NC) Testing API endpoints from Docker network..."
	@docker exec $(APP_CONTAINER) curl -s http://localhost:3007/health || echo "API container not running"

chat-test: ## Test chat completion (uses API_KEY from .env)
	@if [ -z "$(API_KEY)" ]; then \
		echo "$(RED)[ERROR]$(NC) API_KEY not found in .env file"; \
		echo "Please set API_KEY in .env file"; \
		exit 1; \
	fi
	@echo "$(BLUE)[INFO]$(NC) Testing chat completion with API_KEY: $(API_KEY)"
	@curl -s -X POST $(API_URL)/v1/chat/completions \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $(API_KEY)" \
		-d '{"model": "qwen3:14b", "messages": [{"role": "user", "content": "Hello! Just say hi back."}], "max_tokens": 50}' | \
		jq . 2>/dev/null || echo "Response received (install jq for formatted output)"

##@ Maintenance
clean: ## Clean build artifacts and logs
	@echo "$(BLUE)[INFO]$(NC) Cleaning up..."
	@rm -rf dist/
	@rm -rf node_modules/.cache/
	@rm -f logs/*.log
	@echo "$(GREEN)[SUCCESS]$(NC) Cleanup completed"

reset: docker-down clean install docker-up ## Reset entire project (clean + reinstall)

update: ## Update dependencies and rebuild
	@echo "$(BLUE)[INFO]$(NC) Updating dependencies..."
	@npm update
	@$(MAKE) build
	@echo "$(GREEN)[SUCCESS]$(NC) Update completed"

backup: ## Backup important data
	@echo "$(BLUE)[INFO]$(NC) Creating backup..."
	@mkdir -p backups
	@tar czf backups/backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		--exclude=node_modules \
		--exclude=dist \
		--exclude=docker/ollama \
		--exclude=docker/postgres \
		.
	@echo "$(GREEN)[SUCCESS]$(NC) Backup created in backups/ directory"

##@ Production
prod-build: ## Production build (containerized)
	@echo "$(BLUE)[INFO]$(NC) Building for production..."
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)[SUCCESS]$(NC) Production build completed"

prod-start: ## Start production services
	@echo "$(BLUE)[INFO]$(NC) Starting production services..."
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)[SUCCESS]$(NC) Production services started"

prod-stop: ## Stop production services
	@echo "$(BLUE)[INFO]$(NC) Stopping production services..."
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)[SUCCESS]$(NC) Production services stopped"

prod-restart: ## Restart production services
	@echo "$(BLUE)[INFO]$(NC) Restarting production services..."
	@$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)[SUCCESS]$(NC) Production services restarted"

##@ Quick Actions
quick-start: ## Quick start: all services + essential models
	@echo "$(BLUE)[INFO]$(NC) Quick start: building and starting all services..."
	@$(MAKE) docker-up
	@$(MAKE) wait-services
	@$(MAKE) models-essential
	@echo "$(GREEN)[SUCCESS]$(NC) Quick start completed!"

quick-restart: ## Quick rebuild, restart and test
	@$(MAKE) hard-restart
	@$(MAKE) wait-services
	@$(MAKE) api-test

quick-test: ## Quick test of the entire stack
	@$(MAKE) health
	@echo ""
	@if [ -n "$(API_KEY)" ]; then \
		$(MAKE) chat-test; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) API_KEY not found in .env file. Cannot test chat completion"; \
	fi