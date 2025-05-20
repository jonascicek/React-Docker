#!/bin/bash
set -e

STACK_NAME="myapp"
MANAGER_IP=$(multipass info manager | grep IPv4 | awk '{print $2}')

echo "🚀 Swarm-Status prüfen..."
if ! multipass exec manager -- docker info | grep -q "Swarm: active"; then
    echo "📌 Swarm initialisieren..."
    multipass exec manager -- docker swarm init --advertise-addr $MANAGER_IP

    JOIN_TOKEN=$(multipass exec manager -- docker swarm join-token worker -q)

    echo "👥 Worker hinzufügen..."
    for worker in worker1 worker2 worker3; do
        multipass exec $worker -- docker swarm leave --force || true
        multipass exec $worker -- docker swarm join --token $JOIN_TOKEN ${MANAGER_IP}:2377
    done
else
    echo "✅ Swarm ist bereits aktiv."
fi

echo "🧹 Entferne alten Stack (falls vorhanden)..."
multipass exec manager -- docker stack rm $STACK_NAME || true
echo "⏳ Warte 10 Sekunden, bis Swarm aufräumt..."
sleep 10

echo "📦 Stack wird frisch deployed..."
multipass transfer docker-stack.yml manager:docker-stack.yml
multipass exec manager -- docker stack deploy -c docker-stack.yml $STACK_NAME

echo "⏳ Warte 30 Sekunden auf Services..."
sleep 30

echo "🔍 Aktueller Service-Status:"
multipass exec manager -- docker service ls
