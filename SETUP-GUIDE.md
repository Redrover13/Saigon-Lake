# Step-by-Step Guide for Dulce de Saigon F&B Data Platform Setup

This guide provides detailed instructions for setting up and using the Dulce de Saigon F&B Data Platform development environment.

## Step 1: Clone the Repository

```bash
git clone https://github.com/Redrover13/Saigon-Lake.git
cd Saigon-Lake
```

## Step 2: Use VS Code Dev Container

The project includes a `.devcontainer/devcontainer.json` configuration that will automatically set up your development environment with all required tools.

1. Install VS Code if you don't have it already.
2. Install the "Remote - Containers" extension in VS Code.
3. Open the project folder in VS Code.
4. When prompted, click "Reopen in Container", or use the command palette (F1) and select "Remote-Containers: Reopen in Container".
5. Wait for the container to build and initialize.

## Step 3: Validate the Environment

Once the container is running, open a terminal in VS Code and run:

```bash
cd dulce-platform
./tools/scripts/setup-env.sh
```

This script will verify that all required dependencies are installed and properly configured.

## Step 4: Install Project Dependencies

If not already done by the setup script, install project dependencies:

```bash
cd dulce-platform
pnpm install
```

## Step 5: Start Development

You can now start development using the NX commands:

- Run a specific app:

  ```bash
  nx serve api
  ```

- Build all projects:

  ```bash
  nx run-many --target=build --all
  ```

- Run tests:
  ```bash
  nx run-many --target=test --all
  ```

## Step 6: Deploy to Google Cloud (Optional)

When you're ready to deploy to Google Cloud:

1. Authenticate with Google Cloud:

   ```bash
   gcloud auth login
   ```

2. Set your Google Cloud project:

   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

3. Run the deployment script:
   ```bash
   cd dulce-platform
   ./tools/scripts/deploy.sh development
   ```

## Step 7: Migrate to a Google VM (Optional)

To move your development environment to a Google Cloud VM:

```bash
cd dulce-platform
./tools/scripts/migrate-to-vm.sh dulce-dev-vm YOUR_PROJECT_ID asia-southeast1-a
```

Follow the prompts and instructions provided by the script.

## Project Structure

```
dulce-platform/
├── apps/                  # Frontend and backend applications
├── libs/                  # Shared libraries
├── agents/                # Multi-agent system components
├── tools/                 # Development and deployment tools
└── docs/                  # Documentation
```

## Additional Resources

- [NX Documentation](https://nx.dev/react)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Google ADK Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/agent-builder/overview)
