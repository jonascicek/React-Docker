#!/bin/bash

# Namen der Images
FRONTEND_IMAGE="jigglyy/frontend:latest"
BACKEND_IMAGE="jiggly/backend:latest"

echo "🧹 Entferne lokale Images..."

docker image rm -f $FRONTEND_IMAGE
docker image rm -f $BACKEND_IMAGE

echo "✅ Lokale Images gelöscht."

echo ""
echo "⚠️ Hinweis: Um die Images auf Docker Hub zu löschen, öffne diese Links:"
echo "👉 https://hub.docker.com/repository/docker/jigglyy/frontend"
echo "👉 https://hub.docker.com/repository/docker/jiggly/backend"
echo ""
echo "Dort kannst du manuell alte Tags löschen, bevor du neue pushst."
