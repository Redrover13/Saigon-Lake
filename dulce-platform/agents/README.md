# Multi-Agent System

This directory contains the agents that make up the Dulce de Saigon F&B Data Platform's multi-agent system.

## Architecture

The multi-agent system follows a hierarchical structure:

1. **Orchestrator**: Manages and coordinates all agents, handles system state.
2. **Data Processor**: Processes incoming data from various sources.
3. **Recommendation Engine**: Generates insights and recommendations.
4. **Reporting Agent**: Creates reports and alerts for stakeholders.

Communication is handled via a message bus (NATS/Redis Streams).

## Google ADK Integration

All agents leverage Google's Agent Development Kit (ADK) for intelligent processing and coordination.
