# Wander

A configurable mock application demonstrating a full-stack project management system. Built with React, Node.js, PostgreSQL, and Kubernetes.

## Setup

### Prerequisites

Assuming you have installed:
- **Node.js** (v20+) - [Download](https://nodejs.org/)
- **Docker Desktop** - [Download](https://www.docker.com/products/docker-desktop)
- **kubectl** - Kubernetes command-line tool
- **Minikube** - Local Kubernetes cluster

### Quick Start

**One command to set up and run everything:**

```bash
make dev
```

This single command handles everything: builds Docker images, starts databases, launches services, and sets up port forwarding.

### Access the Application

Once running, open your browser:
- **Frontend**: http://localhost:3000
- **API**: http://localhost:4000
- **Health Check**: http://localhost:4000/health

### Common Commands

```bash
make dev          # Start everything
make teardown     # Stop and clean up
make restart      # Restart everything
make logs         # View all service logs
make test         # Run integration tests
make status       # Check service status
```

### Troubleshooting

The setup script automatically handles common issues:
- **Port conflicts** - Automatically finds and uses available ports
- **Service failures** - Automatically shows diagnostics when services fail to start

**Need more help?**
```bash
make logs          # View all service logs
make status        # Check service status
make restart       # Restart everything
make help          # See all available commands
```

## What's Inside?

- **Frontend** - React app with TypeScript and Tailwind CSS
- **API** - Node.js REST API with Express
- **Database** - PostgreSQL with seed data
- **Cache** - Redis for performance
- **Orchestration** - Kubernetes manifests for deployment

All services run in Docker containers managed by Kubernetes.

---