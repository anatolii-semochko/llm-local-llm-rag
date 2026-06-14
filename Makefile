# Local LLM Service Makefile
# Comprehensive automation for development, deployment, and maintenance

.PHONY: help setup install clean build start stop restart status logs health models test lint check dev prod docker-up docker-down docker-restart docker-logs docker-clean

# Default target
.DEFAULT_GOAL := help

# Variables
NODE_VERSION := $(shell node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
DOCKER_COMPOSE := $(shell which docker-compose 2>/dev/null || echo "docker compose")
API_URL := http://localhost:3007
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
setup: ## Complete project setup (dependencies, docker, environment)
	@echo "$(BLUE)[INFO]$(NC) Starting complete project setup..."
	@$(MAKE) check-requirements
	@$(MAKE) install
	@$(MAKE) docker-up
	@$(MAKE) wait-services
	@echo "$(GREEN)[SUCCESS]$(NC) Setup completed! Run 'make models-essential' to download models"

install: ## Install Node.js dependencies
	@echo "$(BLUE)[INFO]$(NC) Installing Node.js dependencies..."
	@npm install
	@echo "$(GREEN)[SUCCESS]$(NC) Dependencies installed"

check-requirements: ## Check system requirements
	@echo "$(BLUE)[INFO]$(NC) Checking system requirements..."
	@if ! command -v node >/dev/null 2>&1; then \
		echo "$(RED)[ERROR]$(NC) Node.js is not installed. Please install Node.js 18+"; \
		exit 1; \
	fi
	@if [ -n "$(NODE_VERSION)" ] && [ "$(NODE_VERSION)" -lt "18" ]; then \
		echo "$(RED)[ERROR]$(NC) Node.js version 18+ is required. Current: $(shell node --version)"; \
		exit 1; \
	fi
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)[ERROR]$(NC) Docker is not installed. Please install Docker first"; \
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
dev: ## Start development server with hot reload
	@echo "$(BLUE)[INFO]$(NC) Starting development server..."
	@npm run dev

build: ## Build TypeScript project
	@echo "$(BLUE)[INFO]$(NC) Building TypeScript project..."
	@npm run build
	@echo "$(GREEN)[SUCCESS]$(NC) Build completed"

start: ## Start production server
	@echo "$(BLUE)[INFO]$(NC) Starting production server..."
	@npm start

stop: ## Stop the application (kills npm processes)
	@echo "$(BLUE)[INFO]$(NC) Stopping application..."
	@pkill -f "npm run dev" 2>/dev/null || true
	@pkill -f "npm start" 2>/dev/null || true
	@pkill -f "ts-node" 2>/dev/null || true
	@pkill -f "node dist/index.js" 2>/dev/null || true
	@lsof -ti:3007 | xargs kill -9 2>/dev/null || true
	@sleep 1
	@echo "$(GREEN)[SUCCESS]$(NC) Application stopped"

force-stop: ## Force stop all related processes
	@echo "$(YELLOW)[WARNING]$(NC) Force stopping all processes..."
	@sudo pkill -f "npm start" 2>/dev/null || true
	@sudo pkill -f "node dist/index.js" 2>/dev/null || true
	@sudo lsof -ti:3007 | xargs sudo kill -9 2>/dev/null || true
	@sleep 2
	@echo "$(GREEN)[SUCCESS]$(NC) All processes force stopped"

restart: stop start ## Restart the application

hard-restart: force-stop build start ## Hard restart with force stop and rebuild

##@ Docker Services
docker-up: ## Start Docker services (Ollama + PostgreSQL)
	@echo "$(BLUE)[INFO]$(NC) Starting Docker services..."
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)[SUCCESS]$(NC) Docker services started"

docker-down: ## Stop Docker services
	@echo "$(BLUE)[INFO]$(NC) Stopping Docker services..."
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)[SUCCESS]$(NC) Docker services stopped"

docker-restart: docker-down docker-up ## Restart Docker services

docker-logs: ## Show Docker services logs
	@$(DOCKER_COMPOSE) logs -f

docker-status: ## Show Docker services status
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
api-test: ## Test API endpoints
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
prod-build: clean install build ## Production build
	@echo "$(BLUE)[INFO]$(NC) Building for production..."
	@NODE_ENV=production npm run build
	@echo "$(GREEN)[SUCCESS]$(NC) Production build completed"

prod-start: ## Start production server with PM2 (requires pm2)
	@if ! command -v pm2 >/dev/null 2>&1; then \
		echo "$(RED)[ERROR]$(NC) PM2 is not installed. Install with: npm install -g pm2"; \
		exit 1; \
	fi
	@echo "$(BLUE)[INFO]$(NC) Starting production server with PM2..."
	@pm2 start dist/index.js --name "llm-service"
	@echo "$(GREEN)[SUCCESS]$(NC) Production server started"

prod-stop: ## Stop production server (PM2)
	@pm2 stop llm-service 2>/dev/null || true
	@echo "$(GREEN)[SUCCESS]$(NC) Production server stopped"

prod-restart: prod-stop prod-start ## Restart production server

##@ Quick Actions
quick-start: docker-up models-essential dev ## Quick start: docker + models + dev server

quick-restart: hard-restart chat-test ## Quick rebuild, restart and test

quick-test: ## Quick test of the entire stack
	@$(MAKE) health
	@echo ""
	@if [ -n "$(API_KEY)" ]; then \
		$(MAKE) chat-test; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) API_KEY not found in .env file. Cannot test chat completion"; \
	fi