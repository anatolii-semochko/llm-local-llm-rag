#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Ollama container is running
check_ollama() {
    if ! docker compose ps ollama | grep -q "Up"; then
        print_error "Ollama container is not running. Please start it with: docker compose up -d"
        exit 1
    fi
}

# Function to download a model
download_model() {
    local model=$1
    local description=$2
    local size=$3

    print_status "Downloading $model ($description) - $size"
    print_status "This may take several minutes..."

    if docker exec ollama-service ollama pull "$model"; then
        print_success "Successfully downloaded $model"
    else
        print_error "Failed to download $model"
        return 1
    fi
}

# Function to show model info
show_model_info() {
    echo ""
    echo "📋 Available models for download:"
    echo ""
    echo "1. qwen3:14b (9GB) - Main universal model"
    echo "   Purpose: chat, RAG, agents, document analysis, programming"
    echo ""
    echo "2. qwen2.5-coder:14b (9GB) - Specialized coding model"
    echo "   Purpose: NodeJS, TypeScript, React, PHP, SQL"
    echo ""
    echo "3. gemma3:12b (8GB) - Google model"
    echo "   Purpose: alternative, sometimes better results than Qwen"
    echo ""
    echo "4. nomic-embed-text (300MB) - Embeddings model"
    echo "   Purpose: text vectorization for RAG system"
    echo ""
    echo "5. phi4:14b (8GB) - Microsoft model"
    echo "   Purpose: excellent logic, math reasoning"
    echo ""
    echo "Total disk usage: ~34-36 GB"
    echo "Available limit: 50 GB ✓"
    echo ""
}

# Check if Ollama is running
check_ollama

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_model_info
    exit 0
fi

if [ "$1" = "--all" ]; then
    print_status "Downloading all recommended models..."

    download_model "qwen3:14b" "Universal model" "9GB"
    download_model "qwen2.5-coder:14b" "Coding model" "9GB"
    download_model "gemma3:12b" "Google model" "8GB"
    download_model "nomic-embed-text" "Embeddings model" "300MB"
    download_model "phi4:14b" "Microsoft model" "8GB"

    print_success "All models downloaded successfully! 🎉"
    exit 0
fi

if [ "$1" = "--essential" ]; then
    print_status "Downloading essential models only..."

    download_model "qwen3:14b" "Universal model" "9GB"
    download_model "nomic-embed-text" "Embeddings model" "300MB"

    print_success "Essential models downloaded! 🎉"
    exit 0
fi

if [ $# -eq 0 ]; then
    show_model_info
    echo "Usage:"
    echo "  ./scripts/download-models.sh --all        # Download all recommended models"
    echo "  ./scripts/download-models.sh --essential  # Download only essential models"
    echo "  ./scripts/download-models.sh <model-name> # Download specific model"
    echo "  ./scripts/download-models.sh --help       # Show this help"
    echo ""
    echo "Examples:"
    echo "  ./scripts/download-models.sh qwen3:14b"
    echo "  ./scripts/download-models.sh nomic-embed-text"
    exit 0
fi

# Download specific model
if [ $# -eq 1 ]; then
    case $1 in
        "qwen3:14b")
            download_model "$1" "Universal model" "9GB"
            ;;
        "qwen2.5-coder:14b")
            download_model "$1" "Coding model" "9GB"
            ;;
        "gemma3:12b")
            download_model "$1" "Google model" "8GB"
            ;;
        "nomic-embed-text")
            download_model "$1" "Embeddings model" "300MB"
            ;;
        "phi4:14b")
            download_model "$1" "Microsoft model" "8GB"
            ;;
        *)
            print_status "Downloading custom model: $1"
            download_model "$1" "Custom model" "Unknown size"
            ;;
    esac
fi

print_success "Model download completed!"
print_status "You can check available models with:"
echo "  docker exec ollama-service ollama list"