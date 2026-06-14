# Local LLM Service

Production-ready OpenAI-compatible API service for local LLM models using Ollama with comprehensive automation and monitoring.

## Features

- **OpenAI-compatible API** - Drop-in replacement for OpenAI API
- **Docker containerization** - Ollama + PostgreSQL with health checks
- **API key authentication** - Secure access with OpenAI-style error handling
- **Advanced logging** - Colored logs with request tracking and content preview
- **Single responsibility architecture** - Clean TypeScript codebase
- **Production ready** - Express.js with proper error handling and validation
- **Multiple model support** - qwen3:14b, qwen2.5-coder:14b, gemma3:12b, phi4:14b
- **Comprehensive monitoring** - Health checks, status monitoring, and metrics
- **Complete automation** - 40+ Makefile commands for all operations
- **Reasoning model support** - Handles qwen3:14b reasoning patterns correctly

## Quick Start

### 1. Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd llm+rag

# Install dependencies
npm install

# Copy configuration
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` file:

```env
API_KEY=your-secret-api-key-here
PORT=3007
DEFAULT_CHAT_MODEL=qwen3:14b
DEFAULT_EMBEDDING_MODEL=nomic-embed-text
```

### 3. Start Docker Services

```bash
# Start Ollama and PostgreSQL
docker compose up -d

# Check status
docker compose ps
```

### 4. Download Models

```bash
# Main universal model (9GB)
docker exec ollama-service ollama pull qwen3:14b

# Programming specialized model (9GB)
docker exec ollama-service ollama pull qwen2.5-coder:14b

# Second universal model (8GB)
docker exec ollama-service ollama pull gemma3:12b

# Embeddings model (300MB)
docker exec ollama-service ollama pull nomic-embed-text

# Additional: Microsoft model (8GB)
docker exec ollama-service ollama pull phi4:14b
```

### 5. Start Service

```bash
# Quick start (recommended)
make quick-start

# Or step by step
make docker-up
make models-essential
make start

# Development mode
make dev
```

## API Endpoints

### Chat Completions

```bash
curl -X POST http://localhost:3007/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer agent-007" \
  -d '{
    "model": "qwen3:14b",
    "messages": [
      {
        "role": "user",
        "content": "Explain what is RAG"
      }
    ],
    "max_tokens": 1000,
    "temperature": 0.7
  }'

# Or use the test command
make chat-test
```

### Embeddings

```bash
curl -X POST http://localhost:3007/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer agent-007" \
  -d '{
    "model": "nomic-embed-text",
    "input": "Node.js RAG architecture"
  }'
```

### Models

```bash
# List available models
make api-test

# Or manually
curl -X GET http://localhost:3007/v1/models \
  -H "Authorization: Bearer agent-007"

# Get specific model info
curl -X GET http://localhost:3007/v1/models/qwen3:14b \
  -H "Authorization: Bearer agent-007"
```

### Health Check

```bash
# Quick health check
make health

# Or manually
curl -X GET http://localhost:3007/health
```

## Project Structure

```
src/
├── config/           # Environment configuration
├── controllers/      # HTTP controllers
├── middleware/       # Express middleware
├── services/         # Business logic
├── types/           # TypeScript types
├── utils/           # Utilities and logging
└── index.ts         # Entry point
```

## Using with OpenAI SDK

### Node.js

```javascript
import OpenAI from "openai";

const client = new OpenAI({
  apiKey: "agent-007",
  baseURL: "http://localhost:3007/v1"
});

// Chat completion
const response = await client.chat.completions.create({
  model: "qwen3:14b",
  messages: [
    { role: "user", content: "Hello!" }
  ]
});

// Embeddings
const embedding = await client.embeddings.create({
  model: "nomic-embed-text",
  input: "Text to embed"
});
```

## Recommended Models

| Model | Size | Purpose |
|-------|------|---------|
| qwen3:14b | 9 GB | Universal: chat, RAG, agents |
| qwen2.5-coder:14b | 9 GB | Programming: NodeJS, TypeScript |
| gemma3:12b | 8 GB | Google model, alternative |
| nomic-embed-text | 300 MB | Embeddings for RAG |
| phi4:14b | 8 GB | Microsoft, strong logic |

**Total disk usage**: ~34-36 GB

## System Requirements

- **RAM**: 32 GB (recommended)
- **Disk**: 50 GB free space
- **CPU**: Intel i7-1165G7 or equivalent
- **Docker**: version 20.10+
- **Node.js**: version 18+

## Logging

Service uses structured logging with colors:

- 🔵 INFO - general information
- 🟡  WARN - warnings
- 🔴 ERROR - errors
- ⚪ DEBUG - debugging

Logs are stored in `logs/app.log` file and displayed in console.

## Automation Commands

### 🚀 Quick Start
```bash
make setup           # Complete project setup
make quick-start     # Docker + models + dev server
make quick-restart   # Rebuild, restart and test
```

### 🔧 Development
```bash
make dev            # Development server with hot reload
make build          # Build TypeScript project
make start          # Start production server
make stop           # Stop application
make restart        # Restart application
make hard-restart   # Force restart with rebuild
```

### 🐳 Docker Management
```bash
make docker-up      # Start Docker services
make docker-down    # Stop Docker services
make docker-status  # Show service status
make docker-logs    # Show Docker logs
make docker-restart # Restart Docker services
```

### 🤖 Model Management
```bash
make models         # Show available models
make models-essential # Download essential models
make models-all     # Download all models
make models-list    # List downloaded models
```

### 🧪 Testing & Monitoring
```bash
make health         # Check service health
make status         # Overall system status
make api-test       # Test API endpoints
make chat-test      # Test chat completion
make quick-test     # Quick stack test
```

### 🔧 Maintenance
```bash
make clean          # Clean build artifacts
make reset          # Reset entire project
make backup         # Create backup
```

## Future Features

- RAG system with pgvector
- Document management API
- Advanced search capabilities
- Metrics and analytics
- Web interface

## Common Issues

### Model not found
```bash
# Check available models
docker exec ollama-service ollama list

# Download required model
docker exec ollama-service ollama pull model-name
```

### Connection error to Ollama
```bash
# Check container status
docker compose ps

# Restart services
docker compose restart ollama
```

### Invalid API key
- Check `.env` file
- Make sure API_KEY is set
- Use correct Bearer token