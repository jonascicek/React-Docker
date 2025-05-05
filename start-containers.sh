#!/bin/bash

# Automatisiertes Skript zum Bauen und Starten der Docker-Container

# Variablen
BACKEND_IMAGE="my-backend-api"
FRONTEND_IMAGE="my-frontend-app"
BACKEND_CONTAINER="my-backend"
FRONTEND_CONTAINER="my-frontend"
BACKEND_PORT=8081
FRONTEND_PORT=8080
BACKEND_VOLUME="C:/Users/jonas/workspace/React-Docker/backend/todos.json:/app/todos.json"

# Backend-Container stoppen und entfernen, falls er existiert
if docker ps -a | grep -q $BACKEND_CONTAINER; then
  echo "Stoppe und entferne bestehenden Backend-Container: $BACKEND_CONTAINER"
  docker stop $BACKEND_CONTAINER
  docker rm $BACKEND_CONTAINER
fi

# Backend-Image bauen
echo "Baue Backend-Image: $BACKEND_IMAGE"
cd backend
docker build -t $BACKEND_IMAGE .
cd ..

# Backend-Container starten
echo "Starte Backend-Container: $BACKEND_CONTAINER"
docker run -d --name $BACKEND_CONTAINER -p $BACKEND_PORT:3000 -v $BACKEND_VOLUME $BACKEND_IMAGE

# Frontend-Container stoppen und entfernen, falls er existiert
if docker ps -a | grep -q $FRONTEND_CONTAINER; then
  echo "Stoppe und entferne bestehenden Frontend-Container: $FRONTEND_CONTAINER"
  docker stop $FRONTEND_CONTAINER
  docker rm $FRONTEND_CONTAINER
fi

# Frontend-Image bauen
echo "Baue Frontend-Image: $FRONTEND_IMAGE"
cd frontend
docker build --build-arg VITE_API_URL=http://localhost:$BACKEND_PORT -t $FRONTEND_IMAGE .
cd ..

# Frontend-Container starten
echo "Starte Frontend-Container: $FRONTEND_CONTAINER"
docker run -d --name $FRONTEND_CONTAINER -p $FRONTEND_PORT:80 $FRONTEND_IMAGE

# Status anzeigen
echo "Docker-Container laufen:"
docker ps