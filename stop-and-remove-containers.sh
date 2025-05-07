#!/bin/bash

# Container-, Image-, Volume- & Netzwerk-Stop-Skript für Proxy-Projekt

# Container- und Image-Namen
FRONTEND_CONTAINER="frontend-app"
BACKEND_CONTAINER="backend-service"
FRONTEND_IMAGE="my-frontend-app:network-proxy"
BACKEND_IMAGE="my-backend-api:network-proxy"
VOLUME_NAME="my-backend-data"
NETWORK_NAME="my-app-network"

echo "🛑 Stoppe und entferne Container..."
docker rm -f $FRONTEND_CONTAINER 2>/dev/null && echo "✔ $FRONTEND_CONTAINER entfernt"
docker rm -f $BACKEND_CONTAINER 2>/dev/null && echo "✔ $BACKEND_CONTAINER entfernt"

echo "🧼 Entferne Images..."
docker rmi $FRONTEND_IMAGE 2>/dev/null && echo "🗑 $FRONTEND_IMAGE entfernt"
docker rmi $BACKEND_IMAGE 2>/dev/null && echo "🗑 $BACKEND_IMAGE entfernt"

read -p "❓ Backend-Daten-Volume '$VOLUME_NAME' auch löschen? (y/N): " delete_volume
if [[ $delete_volume == "y" || $delete_volume == "Y" ]]; then
  docker volume rm $VOLUME_NAME >/dev/null 2>&1 && echo "🗑 Volume '$VOLUME_NAME' gelöscht"
else
  echo "💾 Volume bleibt erhalten."
fi

docker network rm $NETWORK_NAME >/dev/null 2>&1 && echo "🔌 Netzwerk '$NETWORK_NAME' gelöscht"

echo "📦 Aktuelle Container:"
docker ps -a
echo "📦 Aktuelle Images:"
docker images
