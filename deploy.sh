#!/bin/bash

# Configuration
STACK_NAME="myapp"
MANAGER_IP=$(multipass info manager | grep IPv4 | awk '{print $2}')

# Initialize Swarm on manager (if not already initialized)
echo "🚀 Checking Swarm status..."
if ! multipass exec manager -- docker info | grep -q "Swarm: active"; then
    echo "Initializing new Swarm..."
    multipass exec manager -- docker swarm init --advertise-addr $MANAGER_IP
    
    # Get join token for workers
    JOIN_TOKEN=$(multipass exec manager -- docker swarm join-token worker -q)
    
    # Join workers
    echo "👥 Adding workers..."
    multipass exec worker1 -- docker swarm leave --force 2>/dev/null || true
    multipass exec worker2 -- docker swarm leave --force 2>/dev/null || true
    multipass exec worker1 -- docker swarm join --token $JOIN_TOKEN ${MANAGER_IP}:2377
    multipass exec worker2 -- docker swarm join --token $JOIN_TOKEN ${MANAGER_IP}:2377
else
    echo "Swarm already initialized"
fi

# Deploy stack
echo "📦 Deploying stack..."
multipass transfer docker-stack.yml manager:docker-stack.yml
multipass exec manager -- docker stack deploy -c docker-stack.yml $STACK_NAME

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 5

# Show status
echo "✨ Deployment complete"
multipass exec manager -- docker service ls