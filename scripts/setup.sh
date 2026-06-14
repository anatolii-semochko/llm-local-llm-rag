#!/bin/bash

set -e

echo "🚀 Setting up Local LLM Service..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt "18" ]; then
    print_error "Node.js version 18+ is required. Current version: $(node --version)"
    exit 1
fi

print_status "Node.js version: $(node --version) ✓"

# Create logs directory
mkdir -p logs
print_success "Created logs directory"

# Create docker directories
mkdir -p docker/ollama docker/postgres
print_success "Created docker directories"

# Copy environment file if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    print_success "Created .env file from template"
    print_warning "Please edit .env file and set your API_KEY"
else
    print_status ".env file already exists"
fi

# Install dependencies
print_status "Installing Node.js dependencies..."
npm install
print_success "Dependencies installed"

# Start Docker services
print_status "Starting Docker services..."
docker compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check if Ollama is running
print_status "Checking Ollama status..."
if curl -f http://localhost:11434/api/tags &> /dev/null; then
    print_success "Ollama is running"
else
    print_warning "Ollama might not be ready yet. You can check with: docker compose ps"
fi

# Check if PostgreSQL is running
print_status "Checking PostgreSQL status..."
if docker compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    print_success "PostgreSQL is running"
else
    print_warning "PostgreSQL might not be ready yet. You can check with: docker compose ps"
fi

echo ""
print_success "Setup completed! 🎉"
echo ""
echo "Next steps:"
echo "1. Edit .env file and set your API_KEY"
echo "2. Download models with: ./scripts/download-models.sh"
echo "3. Start the service with: npm run dev"
echo ""
echo "Useful commands:"
echo "- Check service status: docker compose ps"
echo "- View logs: docker compose logs"
echo "- Stop services: docker compose down"
echo "- Health check: curl http://localhost:3000/health"