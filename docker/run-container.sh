#!/bin/bash

IMAGE_NAME="my-react-app"
CONTAINER_NAME="my-react-container"

echo "Docker-Image wird gebaut..."
docker build -t $IMAGE_NAME .

echo "Bestehender Container (falls vorhanden) wird entfernt..."
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
fi

echo "Container wird gestartet..."
docker run -d -p 8080:80 --name $CONTAINER_NAME $IMAGE_NAME

echo "Warte auf Healthcheck..."
sleep 5

echo "Containerstatus:"
docker ps
docker inspect --format='Gesundheitsstatus: {{.State.Health.Status}}' $CONTAINER_NAME

echo "Anwendung sollte erreichbar sein unter http://localhost:8080"
