# Wander

A configurable mock application demonstrating a full-stack project management system. Built with React, Node.js, PostgreSQL, and Kubernetes. Use it as a starting point for learning or as a template for your own projects.

## Who is this for?

**Developers** learning modern web development with React, Node.js, and Kubernetes
**DevOps engineers** wanting a complete example of containerized microservices
**Students** studying full-stack development and cloud-native architecture
**Anyone** looking for a configurable mock application to customize and build upon

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

**First time setup:** Install prerequisites (see below), start Minikube (`minikube start --memory=4096 --cpus=2`), run `npm install`, then `make dev`.

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

**Port already in use?**
```bash
make teardown
make dev
```

**Services not starting?**
```bash
make logs          # Check what's happening
make status        # See pod status
```

**Need help?**
```bash
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