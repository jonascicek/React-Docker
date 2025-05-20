#!/bin/bash
set -e

echo "🧹 Alte Images bereinigen (optional)..."
docker rmi -f jigglyy/frontend:latest || true
docker rmi -f jigglyy/backend:latest || true

echo "🔐 Einloggen bei Docker Hub..."
docker login

echo "🏗️ Baue Frontend..."
docker build --no-cache -t jigglyy/frontend ./frontend
docker push jigglyy/frontend

echo "🏗️ Baue Backend..."
docker build --no-cache -t jigglyy/backend ./backend
docker push jigglyy/backend

echo "✅ Build und Push abgeschlossen."
