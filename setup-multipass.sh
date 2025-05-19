#!/bin/bash

# Namen der Nodes
MANAGER="manager"
WORKERS=("worker1" "worker2" "worker3")

echo "🔄 Erstelle VMs mit Docker über cloud-init..."
multipass launch --name $MANAGER --cloud-init cloud-init.yml

for worker in "${WORKERS[@]}"; do
  multipass launch --name $worker --cloud-init cloud-init.yml
done

echo "⏳ Warte 10 Sekunden, bis Docker auf den VMs gestartet ist..."
sleep 10

echo "🚀 Initialisiere Swarm auf dem Manager..."
MANAGER_IP=$(multipass info $MANAGER | grep IPv4 | awk '{print $2}')
multipass exec $MANAGER -- docker swarm init --advertise-addr $MANAGER_IP

echo "🔑 Hole Worker-Join-Token vom Manager..."
JOIN_TOKEN=$(multipass exec $MANAGER -- docker swarm join-token -q worker)

echo "🤝 Worker-Nodes dem Swarm beitreten lassen..."
for worker in "${WORKERS[@]}"; do
  multipass exec $worker -- docker swarm join --token $JOIN_TOKEN $MANAGER_IP:2377
done

echo "🏷️ Setze Node-Labels auf dem Manager..."
multipass exec $MANAGER -- docker node update --label-add role=frontend worker1
multipass exec $MANAGER -- docker node update --label-add role=backend worker2
multipass exec $MANAGER -- docker node update --label-add role=database worker3

echo "✅ Swarm-Setup abgeschlossen!"
multipass exec $MANAGER -- docker node ls
