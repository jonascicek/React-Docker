# STAGE 1: BUILD
FROM node:lts-alpine AS builder

WORKDIR /app

# Nur Abhängigkeitsdefinitionen (Caching optimal nutzen)
COPY package*.json ./

# Installiere Abhängigkeiten
RUN npm ci

# Restlicher Code
COPY . .

# Produktions-Build erzeugen
RUN npm run build

# STAGE 2: RUNTIME
FROM nginx:alpine

# Statische Dateien übernehmen
COPY --from=builder /app/dist /usr/share/nginx/html

# nginx-Konfiguration kopieren (falls vorhanden)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Port freigeben
EXPOSE 80

# Healthcheck definieren – prüft, ob die Startseite erreichbar ist
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
