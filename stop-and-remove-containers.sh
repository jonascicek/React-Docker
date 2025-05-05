#!/bin/bash

# Automatisiertes Skript zum Stoppen und Entfernen der Docker-Container und -Images

# Variablen
BACKEND_CONTAINER="my-backend"
FRONTEND_CONTAINER="my-frontend"
BACKEND_IMAGE="my-backend-api"
FRONTEND_IMAGE="my-frontend-app"

# Backend-Container stoppen und entfernen
if docker ps -a | grep -q $BACKEND_CONTAINER; then
  echo "Stoppe und entferne Backend-Container: $BACKEND_CONTAINER"
  docker stop $BACKEND_CONTAINER
  docker rm $BACKEND_CONTAINER
else
  echo "Backend-Container $BACKEND_CONTAINER existiert nicht."
fi

# Frontend-Container stoppen und entfernen
if docker ps -a | grep -q $FRONTEND_CONTAINER; then
  echo "Stoppe und entferne Frontend-Container: $FRONTEND_CONTAINER"
  docker stop $FRONTEND_CONTAINER
  docker rm $FRONTEND_CONTAINER
else
  echo "Frontend-Container $FRONTEND_CONTAINER existiert nicht."
fi

# Backend-Image entfernen
if docker images | grep -q $BACKEND_IMAGE; then
  echo "Entferne Backend-Image: $BACKEND_IMAGE"
  docker rmi $BACKEND_IMAGE
else
  echo "Backend-Image $BACKEND_IMAGE existiert nicht."
fi

# Frontend-Image entfernen
if docker images | grep -q $FRONTEND_IMAGE; then
  echo "Entferne Frontend-Image: $FRONTEND_IMAGE"
  docker rmi $FRONTEND_IMAGE
else
  echo "Frontend-Image $FRONTEND_IMAGE existiert nicht."
fi

# Status anzeigen
echo "Aktuelle Docker-Container:"
docker ps -a
echo "Aktuelle Docker-Images:"
docker images