#!/bin/bash

# Debug-Skript für Netzwerk + Build-Arg Kontrolle

BACKEND_IMAGE="my-backend-api:network-proxy"
FRONTEND_IMAGE="my-frontend-app:debug"
BACKEND_CONTAINER="backend-service"
FRONTEND_CONTAINER="frontend-app"
NETWORK_NAME="my-app-network"
BACKEND_VOLUME="my-backend-data"
BUILD_API_URL="http://localhost:8081/api"

echo "🧼 Bereinige alten Build-Cache..."
docker builder prune --force >/dev/null

# Netzwerk
if ! docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
  echo "🔧 Erstelle Docker-Netzwerk: $NETWORK_NAME"
  docker network create $NETWORK_NAME
fi

# Alte Container stoppen
for container in $BACKEND_CONTAINER $FRONTEND_CONTAINER; do
  if docker ps -a --format '{{.Names}}' | grep -q $container; then
    echo "🛑 Stoppe & entferne $container"
    docker stop $container
    docker rm $container
  fi
done

# === Backend ===
echo "🔧 Baue Backend..."
cd backend
docker build -t $BACKEND_IMAGE .
cd ..

echo "🚀 Starte Backend..."
docker run -d \
  --name $BACKEND_CONTAINER \
  --network $NETWORK_NAME \
  -p 8081:3000 \
  -v $BACKEND_VOLUME:/app/data \
  $BACKEND_IMAGE

# === Frontend ===
echo "🔧 Baue Frontend (DEBUG)..."
cd frontend

# TEMP: Zeige Build-Arg im Log
echo "👉 Übergabewert VITE_API_URL: $BUILD_API_URL"

# Füge temporär Debug-Log in Dockerfile ein
cp Dockerfile Dockerfile.debug
echo -e "\nRUN echo '📦 VITE_API_URL ist: \$VITE_API_URL'" >> Dockerfile.debug

docker build --no-cache --build-arg VITE_API_URL=$BUILD_API_URL -t $FRONTEND_IMAGE .

rm Dockerfile.debug
cd ..

echo "🚀 Starte Frontend..."
docker run -d \
  --name $FRONTEND_CONTAINER \
  --network $NETWORK_NAME \
  -p 8080:80 \
  $FRONTEND_IMAGE

echo ""
echo "✅ Teste im Browser: http://localhost:8080"
echo "👉 Öffne DevTools > Console: Sollte '🌐 API URL aus import.meta.env:' anzeigen"
