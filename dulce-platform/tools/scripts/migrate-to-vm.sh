#!/bin/bash
set -e

# Script to migrate the Dulce de Saigon F&B Data Platform development environment to a Google VM
# Usage: ./migrate-to-vm.sh <vm_name> <project_id> <zone>

# Default values
VM_NAME=${1:-dulce-dev-vm}
PROJECT_ID=${2:-$(gcloud config get-value project)}
ZONE=${3:-asia-southeast1-a}

echo "========================================================"
echo "Migrating Development Environment to Google Cloud VM"
echo "========================================================"
echo "VM Name: $VM_NAME"
echo "Project ID: $PROJECT_ID"
echo "Zone: $ZONE"
echo "========================================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "Error: gcloud CLI is not installed. Please install it first."
  exit 1
fi

# Verify Google Cloud authentication
gcloud auth list > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Not authenticated to Google Cloud. Run 'gcloud auth login' first."
  exit 1
fi

# Check if VM already exists
echo "Checking if VM exists..."
VM_EXISTS=$(gcloud compute instances list --filter="name=$VM_NAME" --format="value(name)" 2>/dev/null)
if [ -n "$VM_EXISTS" ]; then
  echo "VM '$VM_NAME' already exists."
  read -p "Do you want to proceed with migration to the existing VM? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    exit 0
  fi
else
  echo "VM does not exist. Creating new VM..."
  
  # Create VM with recommended specs
  gcloud compute instances create $VM_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-standard-4 \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --tags=http-server,https-server \
    --scopes=https://www.googleapis.com/auth/cloud-platform
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create VM. Please check your GCP quota and permissions."
    exit 1
  fi
  
  echo "VM created successfully. Waiting for VM to start..."
  sleep 30 # Wait for VM to fully initialize
fi

# Get the VM's external IP
VM_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "VM external IP: $VM_IP"

# Create a temporary directory for the archive
TEMP_DIR=$(mktemp -d)
ARCHIVE_NAME="dulce-platform.tar.gz"

echo "Archiving the project..."
tar --exclude="node_modules" --exclude=".git" -czf $TEMP_DIR/$ARCHIVE_NAME -C "$(dirname "$(pwd)")" "dulce-platform"

# Copy the archive to the VM
echo "Copying project to VM..."
gcloud compute scp $TEMP_DIR/$ARCHIVE_NAME $VM_NAME:~/ --zone=$ZONE

# SSH to the VM and setup the environment
echo "Setting up the environment on the VM..."
gcloud compute ssh $VM_NAME --zone=$ZONE -- "
  echo 'Extracting the project...' && \
  mkdir -p ~/projects && \
  tar -xzf ~/$ARCHIVE_NAME -C ~/projects && \
  cd ~/projects/dulce-platform && \
  echo 'Installing dependencies...' && \
  sudo apt update && \
  sudo apt install -y curl git build-essential apt-transport-https ca-certificates gnupg && \
  
  echo 'Installing Node.js via nvm...' && \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
  export NVM_DIR=\$HOME/.nvm && \
  [ -s \$NVM_DIR/nvm.sh ] && \. \$NVM_DIR/nvm.sh && \
  nvm install 16 && \
  nvm use 16 && \
  nvm alias default 16 && \
  
  echo 'Installing pnpm...' && \
  npm install -g pnpm && \
  
  echo 'Installing NX CLI...' && \
  pnpm add -g nx && \
  
  echo 'Installing JDK 11...' && \
  sudo apt install -y openjdk-11-jdk && \
  
  echo 'Installing Google Cloud SDK...' && \
  sudo apt-get install apt-transport-https ca-certificates gnupg -y && \
  echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
  sudo apt-get update && sudo apt-get install google-cloud-cli -y && \
  
  echo 'Installing Docker and Docker Compose...' && \
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
  sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io && \
  sudo usermod -aG docker \$USER && \
  
  echo 'Installing Terraform...' && \
  sudo apt-get install -y gnupg software-properties-common && \
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
  echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
  sudo apt update && sudo apt-get install -y terraform && \
  
  echo 'Installing project dependencies...' && \
  cd ~/projects/dulce-platform && \
  pnpm install && \
  
  echo 'Making scripts executable...' && \
  chmod +x ~/projects/dulce-platform/tools/scripts/*.sh && \
  
  echo 'Setup complete!' && \
  echo 'Please reconnect to the VM to ensure all group permissions are applied correctly.'
"

# Clean up
rm -rf $TEMP_DIR

echo "========================================================"
echo "Migration complete!"
echo "========================================================"
echo "Your development environment has been set up on the Google VM."
echo "VM Name: $VM_NAME"
echo "VM IP: $VM_IP"
echo "Project Path: ~/projects/dulce-platform"
echo
echo "To connect to the VM, run:"
echo "gcloud compute ssh $VM_NAME --zone=$ZONE"
echo
echo "After connecting, run the following command to validate the environment:"
echo "cd ~/projects/dulce-platform && ./tools/scripts/setup-env.sh"
echo "========================================================"
