FROM node:lts-alpine

WORKDIR /app

# Install curl and other debug tools
RUN apk add --no-cache curl postgresql-client

# Copy package files first
COPY package*.json ./

# Install dependencies including pg
RUN npm ci

COPY . .

CMD ["node", "server.js"]