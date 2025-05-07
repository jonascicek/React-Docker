# Notiz-App mit Docker, Nginx und Reverse Proxy

Diese Anwendung besteht aus einem React-Frontend und einem Node.js-Backend mit Dateibasiertem Speicher für Todos. Beide Container laufen in einem gemeinsamen Docker-Netzwerk und kommunizieren über einen Reverse Proxy (Nginx), der in den Frontend-Container integriert ist.

## Funktionen

- React-Frontend (mit TailwindCSS)
- Express-Backend mit persistenter Speicherung in todos.json
- Kommunikation über Docker-Netzwerk und Reverse Proxy
- Keine direkte Portfreigabe zwischen Frontend und Backend nötig

## Start der Anwendung

Die Anwendung wird mit dem Skript `start-proxy-containers.sh` gestartet. Dabei wird automatisch:

- das Docker-Netzwerk `my-app-network` erstellt (falls nicht vorhanden)
- das Backend gebaut und mit persistenter Volume-Verknüpfung gestartet
- das Frontend gebaut, inklusive Nginx-Konfiguration für den Proxy

Die App ist anschließend erreichbar unter:

http://localhost:8080


## Stoppen der Anwendung

Mit dem Skript `stop-proxy-containers.sh` werden beide Container gestoppt und gelöscht. Optional kann auch das Volume entfernt werden.

## Reverse Proxy

Der Nginx-Webserver im Frontend-Container leitet alle Anfragen an `/api/` automatisch an das Backend im selben Docker-Netzwerk weiter. Der Containername `backend-service` wird intern über DNS aufgelöst.

## Build-Argument

Beim Bauen des Frontends wird der Pfad `/api` als Umgebungsvariable übergeben:

--build-arg VITE_API_URL=/api

So kann das React-Frontend relative API-Aufrufe verwenden.