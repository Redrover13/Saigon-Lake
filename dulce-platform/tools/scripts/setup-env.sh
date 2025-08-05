#!/bin/bash
set -e

# This script sets up the development environment for the Dulce de Saigon F&B Data Platform
# It validates all required dependencies and initializes the NX workspace if needed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "===========================================" 
echo "Dulce de Saigon F&B Data Platform Setup"
echo "===========================================" 

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check version meets minimum requirement
version_greater_equal() {
  printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Check Node.js
echo -e "${YELLOW}Checking Node.js...${NC}"
if command_exists node; then
  NODE_VERSION=$(node -v | cut -d 'v' -f 2)
  echo "Node.js version: $NODE_VERSION"
  if version_greater_equal "$NODE_VERSION" "16.0.0"; then
    echo -e "${GREEN}✓ Node.js version is sufficient${NC}"
  else
    echo -e "${RED}✗ Node.js version is too old. Please install Node.js 16.x or newer.${NC}"
    echo "We recommend using nvm (Node Version Manager) to install and manage Node.js versions."
    exit 1
  fi
else
  echo -e "${RED}✗ Node.js not found${NC}"
  echo "Please install Node.js 16.x or newer."
  exit 1
fi

# Check pnpm
echo -e "${YELLOW}Checking pnpm...${NC}"
if command_exists pnpm; then
  PNPM_VERSION=$(pnpm -v)
  echo "pnpm version: $PNPM_VERSION"
  echo -e "${GREEN}✓ pnpm is installed${NC}"
else
  echo -e "${RED}✗ pnpm not found${NC}"
  echo "Installing pnpm..."
  npm install -g pnpm
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install pnpm${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ pnpm installed successfully${NC}"
fi

# Check NX CLI
echo -e "${YELLOW}Checking NX CLI...${NC}"
if command_exists nx; then
  NX_VERSION=$(nx --version)
  echo "NX version: $NX_VERSION"
  echo -e "${GREEN}✓ NX CLI is installed${NC}"
else
  echo -e "${RED}✗ NX CLI not found${NC}"
  echo "Installing NX CLI..."
  pnpm add -g nx
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install NX CLI${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ NX CLI installed successfully${NC}"
fi

# Check Java (JDK)
echo -e "${YELLOW}Checking Java JDK...${NC}"
if command_exists java; then
  JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
  echo "Java version: $JAVA_VERSION"
  
  # Extract major version number
  JAVA_MAJOR=$(echo $JAVA_VERSION | cut -d'.' -f1)
  if [[ "$JAVA_VERSION" == 1.* ]]; then
    # For older Java versions (1.8 = Java 8)
    JAVA_MAJOR=$(echo $JAVA_VERSION | cut -d'.' -f2)
  fi
  
  if [ "$JAVA_MAJOR" -ge 11 ]; then
    echo -e "${GREEN}✓ Java version is sufficient${NC}"
  else
    echo -e "${RED}✗ Java version is too old. Please install JDK 11 or newer.${NC}"
    exit 1
  fi
else
  echo -e "${RED}✗ Java not found${NC}"
  echo "Please install JDK 11 or newer."
  exit 1
fi

# Check Terraform
echo -e "${YELLOW}Checking Terraform...${NC}"
if command_exists terraform; then
  TERRAFORM_VERSION=$(terraform version | head -n 1 | cut -d 'v' -f 2)
  echo "Terraform version: $TERRAFORM_VERSION"
  echo -e "${GREEN}✓ Terraform is installed${NC}"
else
  echo -e "${RED}✗ Terraform not found${NC}"
  echo "Please install Terraform."
  exit 1
fi

# Check Google Cloud SDK
echo -e "${YELLOW}Checking Google Cloud SDK...${NC}"
if command_exists gcloud; then
  GCLOUD_VERSION=$(gcloud --version | head -n 1 | awk '{print $4}')
  echo "Google Cloud SDK version: $GCLOUD_VERSION"
  echo -e "${GREEN}✓ Google Cloud SDK is installed${NC}"
else
  echo -e "${RED}✗ Google Cloud SDK not found${NC}"
  echo "Please install the Google Cloud SDK."
  exit 1
fi

# Check Docker
echo -e "${YELLOW}Checking Docker...${NC}"
if command_exists docker; then
  DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
  echo "Docker version: $DOCKER_VERSION"
  echo -e "${GREEN}✓ Docker is installed${NC}"
  
  # Check if user can run Docker without sudo
  docker info > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️ You may need to run Docker commands with sudo or add your user to the docker group.${NC}"
    echo "To add your user to the docker group, run: sudo usermod -aG docker \$USER"
    echo "Then log out and log back in, or run: newgrp docker"
  fi
else
  echo -e "${RED}✗ Docker not found${NC}"
  echo "Please install Docker."
  exit 1
fi

# Check Docker Compose
echo -e "${YELLOW}Checking Docker Compose...${NC}"
if command_exists docker-compose; then
  COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | tr -d ',')
  echo "Docker Compose version: $COMPOSE_VERSION"
  echo -e "${GREEN}✓ Docker Compose is installed${NC}"
elif command_exists "docker" && docker compose version > /dev/null 2>&1; then
  COMPOSE_VERSION=$(docker compose version --short)
  echo "Docker Compose (plugin) version: $COMPOSE_VERSION"
  echo -e "${GREEN}✓ Docker Compose (plugin) is installed${NC}"
else
  echo -e "${YELLOW}⚠️ Docker Compose not found, but this is not critical.${NC}"
  echo "You may want to install Docker Compose for local development."
fi

# Check for dependencies and install if necessary
echo -e "${YELLOW}Checking project dependencies...${NC}"
if [ -f "package.json" ]; then
  echo "Installing dependencies..."
  pnpm install
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install dependencies${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
else
  echo -e "${RED}✗ package.json not found${NC}"
  echo "Please ensure you are in the correct directory."
  exit 1
fi

# Summary
echo -e "\n${GREEN}=====================================================================================${NC}"
echo -e "${GREEN}✓ Environment setup complete! The Dulce de Saigon F&B Data Platform is ready for development.${NC}"
echo -e "${GREEN}=====================================================================================${NC}"
echo -e "\nNext steps:"
echo "1. To start development, run: nx serve [app-name]"
echo "2. To build all apps, run: nx run-many --target=build --all"
echo "3. To run tests, run: nx run-many --target=test --all"
echo "4. For deployment, use the scripts in the 'tools/scripts' directory"
echo -e "\nFor more information, see the README.md file."
