# Dulce de Saigon F&B Data Platform

This repository contains the code and configuration for the Dulce de Saigon Food & Beverage Data Platform, which aims to revolutionize restaurant operations through data-driven insights and automation.

## Architecture

The platform is built as an NX monorepo with a multi-agent system leveraging Google's Agent Development Kit (ADK).

```mermaid
graph TD
    subgraph Data Sources
        POS[Point of Sale Systems]
        Inventory[Inventory Management]
        Reservation[Reservation Systems]
        Staff[Staff Management]
    end

    subgraph Data Ingestion & Processing
        DataIngest[Data Ingestion (Pub/Sub, Cloud Functions)]
        POS --> DataIngest
        Inventory --> DataIngest
        Reservation --> DataIngest
        Staff --> DataIngest

        DataIngest --> DataProcAgent(Data Processor Agent)
        DataProcAgent --> BigQuery[Data Warehouse (BigQuery)]
        DataProcAgent --> OperationalDB[Operational DB (Cloud SQL for PostgreSQL)]
    end

    subgraph Multi-Agent System
        Orchestrator(Orchestrator Agent)
        DataProcAgent --> Orchestrator
        RecEngine(Recommendation Engine)
        ReportAgent(Reporting Agent)
        Orchestrator --> RecEngine
        Orchestrator --> ReportAgent
    end

    subgraph Consumption & Analytics
        BackendAPI[Backend API Service]
        AdminPortal[Admin Portal]
        DashboardsF(Analytics Dashboard Frontend)
        OperationalDB --> BackendAPI
        BackendAPI --> AdminPortal
        BackendAPI --> DashboardsF
    end
```

## Repository Structure

```
dulce-platform/
├── apps/                  # Frontend and backend applications
│   ├── api/               # Backend API service
│   ├── admin-portal/      # Admin portal web app
│   ├── pos-integration/   # POS integration service
│   └── analytics-dashboard/# Analytics dashboard web app
├── libs/                  # Shared libraries
│   ├── core/              # Core utilities and shared logic
│   ├── data-access/       # Data access and integration with Google services
│   ├── ui-components/     # Shared UI components
│   └── agent-framework/   # Framework for agent development
├── agents/                # Multi-agent system components
│   ├── orchestrator/      # Orchestrator agent
│   ├── data-processor/    # Data processor agent
│   ├── recommendation-engine/ # Recommendation engine agent
│   └── reporting-agent/   # Reporting agent
├── tools/                 # Development and deployment tools
└── docs/                  # Documentation
```

## Getting Started

### Prerequisites

- Node.js 16+
- pnpm
- NX CLI
- JDK 11+
- Google Cloud SDK
- Docker & Docker Compose
- Terraform

### Development Environment Setup

The easiest way to get started is to use VS Code with the Dev Container extension:

1. Clone this repository
2. Open in VS Code with Dev Containers extension
3. VS Code will automatically build and start the development container
4. Run `pnpm install` in the workspace to install dependencies

### Manual Setup

1. Install dependencies:
   ```bash
   # Node.js via nvm
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
   source ~/.bashrc
   nvm install 16
   nvm use 16

   # pnpm
   npm install -g pnpm

   # NX CLI
   pnpm add -g nx
   ```

2. Install JDK 11+:
   ```bash
   sudo apt install openjdk-11-jdk -y
   ```

3. Install Google Cloud SDK:
   ```bash
   # Follow instructions at https://cloud.google.com/sdk/docs/install
   ```

4. Clone and setup:
   ```bash
   git clone https://github.com/dulce-de-saigon/platform.git
   cd platform
   pnpm install
   ```

## Building and Testing

```bash
# Build all projects
nx run-many --target=build --all

# Run tests
nx run-many --target=test --all
```

## Deployment

The platform is designed to deploy to Google Cloud. See the deployment documentation in `/docs` for details.

## Vietnamese Localization & Compliance

The platform includes Vietnamese localization and complies with Vietnamese data privacy regulations. All data handling adheres to the Vietnamese Law on Cybersecurity and relevant data protection standards.
