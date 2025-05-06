# Full-Stack Todo App mit Docker & Datenpersistenz

## 🚀 Beschreibung

Diese Anwendung besteht aus einem React-Frontend und einem Node.js/Express-Backend. Sie kommunizieren über eine REST-API und laufen jeweils in separaten Docker-Containern. Die Todos werden persistent gespeichert – nicht im Arbeitsspeicher, sondern in einer Datei im Backend-Container.

## 📁 Projektstruktur

- `frontend/`: React-App
- `backend/`: Express-API mit Dateibasiertem Speicher (`todos.json`)
- `.gitignore`, `.dockerignore`: saubere Build- und Repo-Struktur
- `start-containers.sh`: automatisiertes Skript zum Bauen und Starten der Container

## 🐳 Containerisierte Anwendung starten

### Voraussetzungen:
- Docker Desktop (läuft)
- Git Bash / Terminal mit Zugriff auf Docker CLI

### Anwendung starten:
```bash
- ./start-containers.sh