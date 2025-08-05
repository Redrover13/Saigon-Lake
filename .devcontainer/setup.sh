#!/bin/bash
set -e

# Install NX CLI globally
pnpm add -g nx

# Validate installations
node -v
pnpm -v
nx --version
terraform -v
java -version
gcloud --version
docker --version

echo "All tools installed and validated. Ready to scaffold NX monorepo."
