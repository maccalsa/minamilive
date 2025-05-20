#!/usr/bin/env bash

set -e

# Helper functions
prompt_choice() {
  PS3="$1: "
  shift
  select choice; do
    [ -n "$choice" ] && echo "$choice" && break
  done
}

prompt_port() {
  read -rp "$1 [$2]: " input
  echo "${input:-$2}"
}

create_caddyfile_local() {
  cat << EOF > ./Caddyfile
:${HTTP_PORT} {
  reverse_proxy localhost:${FRONTEND_PORT}
}

:${HTTPS_PORT} {
  reverse_proxy /api/* localhost:${BACKEND_PORT}
  reverse_proxy /ws/* localhost:${BACKEND_PORT} {
    header_up Connection {>Connection}
    header_up Upgrade {>Upgrade}
    header_up Sec-WebSocket-Key {>Sec-WebSocket-Key}
    header_up Sec-WebSocket-Version {>Sec-WebSocket-Version}
    header_up Sec-WebSocket-Extensions {>Sec-WebSocket-Extensions}
    header_up Sec-WebSocket-Protocol {>Sec-WebSocket-Protocol}
  }
  reverse_proxy localhost:${FRONTEND_PORT}
}
EOF
}

create_caddyfile_docker() {
  cat << EOF > ./Caddyfile
:${HTTP_PORT} {
  reverse_proxy frontend:${FRONTEND_PORT}
}

:${HTTPS_PORT} {
  reverse_proxy /api/* backend:${BACKEND_PORT}
  reverse_proxy /ws/* backend:${BACKEND_PORT} {
    header_up Connection {>Connection}
    header_up Upgrade {>Upgrade}
    header_up Sec-WebSocket-Key {>Sec-WebSocket-Key}
    header_up Sec-WebSocket-Version {>Sec-WebSocket-Version}
    header_up Sec-WebSocket-Extensions {>Sec-WebSocket-Extensions}
    header_up Sec-WebSocket-Protocol {>Sec-WebSocket-Protocol}
  }
  reverse_proxy frontend:${FRONTEND_PORT}
}
EOF
}

run_caddy_local() {
  docker run -d \
    --name caddy-proxy \
    --network host \
    -v "$(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro" \
    -p "${HTTP_PORT}:${HTTP_PORT}" \
    -p "${HTTPS_PORT}:${HTTPS_PORT}" \
    caddy:latest
}

run_caddy_docker() {
  docker network create caddy-net || true

  docker run -d --name backend --network caddy-net -p "${BACKEND_PORT}:${BACKEND_PORT}" your-backend-image
  docker run -d --name frontend --network caddy-net -p "${FRONTEND_PORT}:${FRONTEND_PORT}" your-frontend-image

  docker run -d \
    --name caddy-proxy \
    --network caddy-net \
    -v "$(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro" \
    -p "${HTTP_PORT}:${HTTP_PORT}" \
    -p "${HTTPS_PORT}:${HTTPS_PORT}" \
    caddy:latest
}

# Begin Wizard
echo "🚀 Caddy Docker Proxy Setup Wizard"

SETUP_TYPE=$(prompt_choice "Select setup type" \
  "Local Services (services running on your host machine)" \
  "Docker Services (services running as Docker containers)")

echo "🛠 Setup: $SETUP_TYPE"

# Prompt for ports
HTTP_PORT=$(prompt_port "HTTP port" "8080")
HTTPS_PORT=$(prompt_port "HTTPS port" "8443")
FRONTEND_PORT=$(prompt_port "Frontend service port" "5500")
BACKEND_PORT=$(prompt_port "Backend service port" "8000")

# Confirm ports
echo ""
echo "🔧 Configuration:"
echo "HTTP Port: $HTTP_PORT"
echo "HTTPS Port: $HTTPS_PORT"
echo "Frontend Port: $FRONTEND_PORT"
echo "Backend Port: $BACKEND_PORT"
echo ""

# Confirm and proceed
read -rp "Proceed with this configuration? [Y/n]: " confirm
confirm=${confirm:-Y}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Setup cancelled."
  exit 1
fi

# Remove existing container if any
docker rm -f caddy-proxy frontend backend >/dev/null 2>&1 || true

# Generate Caddyfile and run containers based on choice
if [[ $SETUP_TYPE == "Local Services (services running on your host machine)" ]]; then
  echo "Creating Caddyfile for local host services..."
  create_caddyfile_local
  echo "Running Caddy container for local services..."
  run_caddy_local
else
  echo "Creating Caddyfile for Docker-based services..."
  create_caddyfile_docker
  echo "Running service and Caddy containers..."
  run_caddy_docker
fi

echo "✅ Setup complete! Access your app:"
echo "👉 HTTP: http://localhost:${HTTP_PORT}"
echo "👉 HTTPS: https://localhost:${HTTPS_PORT}"
