#!/bin/bash
set -e

# Script for deploying the Dulce de Saigon F&B Data Platform to Google Cloud
# Usage: ./deploy.sh <environment> [project_id]

# Default values
ENV=${1:-development}
PROJECT_ID=${2:-$(gcloud config get-value project)}
REGION="asia-southeast1"

echo "Deploying to environment: $ENV"
echo "Google Cloud project: $PROJECT_ID"
echo "Region: $REGION"

# Verify Google Cloud authentication
gcloud auth list
if [ $? -ne 0 ]; then
  echo "Error: Not authenticated to Google Cloud. Run 'gcloud auth login' first."
  exit 1
fi

# Build all projects
echo "Building projects..."
nx run-many --target=build --all --prod
if [ $? -ne 0 ]; then
  echo "Error: Build failed. Please fix build issues and try again."
  exit 1
fi

# Apply Terraform configuration
echo "Applying Terraform configuration..."
cd "$(dirname "$0")/../terraform"
terraform init
terraform apply -auto-approve -var="project_id=$PROJECT_ID" -var="environment=$ENV"
if [ $? -ne 0 ]; then
  echo "Error: Terraform apply failed."
  exit 1
fi

# Deploy to Cloud Run
echo "Deploying apps to Cloud Run..."
for app in api admin-portal analytics-dashboard pos-integration; do
  echo "Deploying $app..."
  
  # Build and push Docker image
  docker build -t "gcr.io/$PROJECT_ID/$app:latest" -f "../../apps/$app/Dockerfile" ../../
  docker push "gcr.io/$PROJECT_ID/$app:latest"
  
  # Deploy to Cloud Run
  gcloud run deploy "$app" \
    --image="gcr.io/$PROJECT_ID/$app:latest" \
    --platform=managed \
    --region="$REGION" \
    --allow-unauthenticated
done

# Deploy agents (as needed)
if [ "$ENV" == "production" ] || [ "$ENV" == "staging" ]; then
  echo "Deploying agents..."
  for agent in orchestrator data-processor recommendation-engine reporting-agent; do
    echo "Deploying $agent agent..."
    
    # Build and push Docker image
    docker build -t "gcr.io/$PROJECT_ID/$agent:latest" -f "../../agents/$agent/Dockerfile" ../../
    docker push "gcr.io/$PROJECT_ID/$agent:latest"
    
    # Deploy to Cloud Run
    gcloud run deploy "$agent" \
      --image="gcr.io/$PROJECT_ID/$agent:latest" \
      --platform=managed \
      --region="$REGION" \
      --service-account="dulce-agents-$ENV@$PROJECT_ID.iam.gserviceaccount.com" \
      --no-allow-unauthenticated
  done
fi

echo "Deployment complete!"
echo "Services are available at the following URLs:"

for app in api admin-portal analytics-dashboard pos-integration; do
  URL=$(gcloud run services describe "$app" --platform=managed --region="$REGION" --format='value(status.url)')
  echo "- $app: $URL"
done
