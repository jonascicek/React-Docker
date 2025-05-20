#!/bin/bash
set -e

echo "🔄 Erstelle VMs mit Docker über cloud-init..."
for vm in manager worker1 worker2 worker3; do
    multipass launch --name $vm --cpus 1 --memory 1G --disk 5G --cloud-init cloud-init.yml || echo "$vm existiert bereits"
done

echo "⏳ Warte 10 Sekunden, bis Docker auf den VMs gestartet ist..."
sleep 10

echo "🚀 Initialisiere Swarm auf dem Manager..."
MANAGER_IP=$(multipass exec manager -- hostname -I | awk '{print $1}')

multipass exec manager -- docker swarm init --advertise-addr $MANAGER_IP || echo "Swarm bereits initialisiert"

echo "🔑 Hole Worker-Join-Token vom Manager..."
JOIN_TOKEN=$(multipass exec manager -- docker swarm join-token worker -q)

echo "🤝 Worker-Nodes dem Swarm beitreten lassen..."
for worker in worker1 worker2 worker3; do
    multipass exec $worker -- docker swarm leave --force || true
    multipass exec $worker -- docker swarm join --token $JOIN_TOKEN $MANAGER_IP:2377
done

# Optional: Labels setzen (nur 1x nötig)
echo "🏷️ Setze Node Labels (einmalig erforderlich)..."
multipass exec manager -- docker node update --label-add role=frontend $(multipass exec manager -- docker node ls --format '{{.ID}} {{.Hostname}}' | grep worker1 | cut -d' ' -f1)
multipass exec manager -- docker node update --label-add role=backend $(multipass exec manager -- docker node ls --format '{{.ID}} {{.Hostname}}' | grep worker2 | cut -d' ' -f1)
multipass exec manager -- docker node update --label-add role=database $(multipass exec manager -- docker node ls --format '{{.ID}} {{.Hostname}}' | grep worker3 | cut -d' ' -f1)


echo "✅ Swarm-Setup abgeschlossen!"
multipass exec manager -- docker node ls
