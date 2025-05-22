#!/bin/bash

# Container-, Image-, Volume- & Netzwerk-Stop-Skript für Proxy-Projekt

# Container- und Image-Namen
FRONTEND_CONTAINER="frontend-app"
BACKEND_CONTAINER="backend-service"
DATABASE_CONTAINER="postgres-db"
FRONTEND_IMAGE="my-frontend-app:network-proxy"
BACKEND_IMAGE="my-backend-api:network-proxy"
BACKEND_VOLUME="backend-data"
POSTGRES_VOLUME="postgres-data"
NETWORK_NAME="todo-app-network"

echo "🛑 Stoppe und entferne Container..."
docker rm -f $FRONTEND_CONTAINER 2>/dev/null && echo "✔ $FRONTEND_CONTAINER entfernt"
docker rm -f $BACKEND_CONTAINER 2>/dev/null && echo "✔ $BACKEND_CONTAINER entfernt"
docker rm -f $DATABASE_CONTAINER 2>/dev/null && echo "✔ $DATABASE_CONTAINER entfernt"

echo "🧼 Entferne Images..."
docker rmi $FRONTEND_IMAGE 2>/dev/null && echo "🗑 $FRONTEND_IMAGE entfernt"
docker rmi $BACKEND_IMAGE 2>/dev/null && echo "🗑 $BACKEND_IMAGE entfernt"
docker rmi postgres:17-alpine 2>/dev/null && echo "🗑 postgres:17-alpine entfernt"

read -p "❓ Daten-Volumes ($BACKEND_VOLUME, $POSTGRES_VOLUME) auch löschen? (y/N): " delete_volume
if [[ $delete_volume == "y" || $delete_volume == "Y" ]]; then
  docker volume rm $BACKEND_VOLUME >/dev/null 2>&1 && echo "🗑 Volume '$BACKEND_VOLUME' gelöscht"
  docker volume rm $POSTGRES_VOLUME >/dev/null 2>&1 && echo "🗑 Volume '$POSTGRES_VOLUME' gelöscht"
else
  echo "💾 Volumes bleiben erhalten."
fi

docker network rm $NETWORK_NAME >/dev/null 2>&1 && echo "🔌 Netzwerk '$NETWORK_NAME' gelöscht"

echo "📦 Aktuelle Container:"
docker ps -a
echo "📦 Aktuelle Images:"
docker images