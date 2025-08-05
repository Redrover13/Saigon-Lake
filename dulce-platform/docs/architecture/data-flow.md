# Data Flow Architecture

This document outlines the data flow architecture for the Dulce de Saigon F&B Data Platform.

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
        DataAnalysis[Data Analysis (Vertex AI / Custom ML)]
        BigQuery --> DataAnalysis
        OperationalDB --> DataAnalysis

        RecEngine(Recommendation Engine)
        DataAnalysis --> RecEngine
        RecEngine -- Recommendations --> OperationalDB

        ReportAgent(Reporting Agent)
        BigQuery --> ReportAgent
        ReportAgent -- Reports/Alerts --> Stakeholder[Stakeholders]

        subgraph Core Orchestration
            Orchestrator(Orchestrator Agent)
            Orchestrator -- Manages --> DataProcAgent
            Orchestrator -- Manages --> RecEngine
            Orchestrator -- Manages --> ReportAgent
            Orchestrator -- State/Coordination --> MessageBus[Message Bus (NATS / Redis Streams)]
            DataProcAgent -- Comm. --> MessageBus
            RecEngine -- Comm. --> MessageBus
            ReportAgent -- Comm. --> MessageBus
        end
    end

    subgraph Consumption & Analytics
        Looker[BI Dashboard (Looker)]
        BigQuery --> Looker
        AdminPortal[Admin Portal]
        OperationalDB --> AdminPortal
        DashboardsF(Analytics Dashboard Frontend)
        ReportAgent --> DashboardsF
        AdminPortal -- Manages --> OperationalDB
        BackendAPI[Backend API Service]
        AdminPortal -- API --> BackendAPI
        DashboardsF -- API --> BackendAPI
    end
```

## Vietnamese Data Privacy Compliance

All data processing and storage adheres to Vietnamese data privacy regulations, including:

- Law on Cybersecurity
- Personal data protection regulations
- Data residency requirements
