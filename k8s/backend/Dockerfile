FROM node:lts-alpine

WORKDIR /usr/src/app

# Install curl and other debug tools
RUN apk add --no-cache curl 

# Copy package files first
COPY package*.json ./

# Install dependencies including pg
RUN npm ci --omit=dev

COPY . .

ARG PORT=3000
ENV PORT=$PORT
# Expose the port
EXPOSE $PORT

CMD ["node", "server.js"]