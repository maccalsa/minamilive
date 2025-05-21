#!/usr/bin/env bash

set -e

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

prompt_text() {
  read -rp "$1: " input
  echo "$input"
}

create_caddyfile() {
  local env_type=$1

  if [ "$env_type" == "Development" ]; then
    cat <<EOF > ./Caddyfile
:${HTTP_PORT} {
  reverse_proxy ${FRONTEND_HOST}:${FRONTEND_PORT}
}

localhost:${HTTPS_PORT} {
  tls internal

  reverse_proxy /api/* ${BACKEND_HOST}:${BACKEND_PORT}

  reverse_proxy /ws/* ${BACKEND_HOST}:${BACKEND_PORT} {
    header_up Connection {http.request.header.Connection}
    header_up Upgrade {http.request.header.Upgrade}
  }

  reverse_proxy ${FRONTEND_HOST}:${FRONTEND_PORT}
}
EOF
  else
    cat <<EOF > ./Caddyfile
${DOMAIN} {
  encode gzip

  log {
    output file /var/log/caddy/access.log {
      roll_size 100mb
      roll_keep 7
      roll_keep_for 168h
    }
    format json
  }

  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    X-Content-Type-Options "nosniff"
    X-Frame-Options "DENY"
    X-XSS-Protection "1; mode=block"
    Referrer-Policy "strict-origin-when-cross-origin"
    Content-Security-Policy "default-src 'self'"
  }

  rate_limit {
    zone api_limit {
      key {remote_host}
      window 1m
      events 100
    }
  }

  handle /api/* {
    rate_limit api_limit
    reverse_proxy ${BACKEND_HOST}:${BACKEND_PORT}
  }

  handle /ws/* {
    reverse_proxy ${BACKEND_HOST}:${BACKEND_PORT} {
      header_up Connection {http.request.header.Connection}
      header_up Upgrade {http.request.header.Upgrade}
    }
  }

  handle {
    reverse_proxy ${FRONTEND_HOST}:${FRONTEND_PORT}
  }

  handle_errors {
    respond "{http.error.status_code} {http.error.status_text}"
  }

  metrics /metrics
}
EOF
  fi
}

build_custom_caddy() {
  cat <<EOF > ./Dockerfile
FROM caddy:2-builder AS builder
RUN xcaddy build --with github.com/mholt/caddy-ratelimit

FROM caddy:2
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
EOF

  docker build -t custom-caddy:latest .
}

run_caddy() {
  docker rm -f caddy-proxy >/dev/null 2>&1 || true

  docker run -d \
    --name caddy-proxy \
    --network "$NETWORK" \
    -v "$(pwd)/Caddyfile:/etc/caddy/Caddyfile:ro" \
    -v caddy_data:/data \
    -v caddy_config:/config \
    -v "$(pwd)/logs:/var/log/caddy" \
    -p "${HTTP_PORT}:${HTTP_PORT}" \
    -p "${HTTPS_PORT}:${HTTPS_PORT}" \
    $([ "$ENV_TYPE" == "Production" ] && echo "custom-caddy:latest" || echo "caddy:latest")
}

# Begin Wizard
echo "🚀 Caddy Docker Proxy Setup Wizard"

SETUP_TYPE=$(prompt_choice "Select setup type" \
  "Local Services" \
  "Docker Services")

ENV_TYPE=$(prompt_choice "Select environment type" "Development" "Production")

if [ "$ENV_TYPE" == "Production" ]; then
  DOMAIN=$(prompt_text "Enter your domain (e.g., example.com)")
  FRONTEND_HOST=$(prompt_text "Enter frontend host (IP or hostname)")
  BACKEND_HOST=$(prompt_text "Enter backend host (IP or hostname)")
else
  FRONTEND_HOST=$([ "$SETUP_TYPE" == "Local Services" ] && echo "localhost" || echo "frontend")
  BACKEND_HOST=$([ "$SETUP_TYPE" == "Local Services" ] && echo "localhost" || echo "backend")
fi

NETWORK=$([ "$SETUP_TYPE" == "Local Services" ] && echo "host" || echo "caddy-net")

HTTP_PORT=$(prompt_port "HTTP port" "80")
HTTPS_PORT=$(prompt_port "HTTPS port" "443")
FRONTEND_PORT=$(prompt_port "Frontend service port" "5500")
BACKEND_PORT=$(prompt_port "Backend service port" "8000")

# Confirm configuration
echo "\n🔧 Configuration:"
echo "Environment: $ENV_TYPE"
[ "$ENV_TYPE" == "Production" ] && echo "Domain: $DOMAIN"
echo "HTTP Port: $HTTP_PORT"
echo "HTTPS Port: $HTTPS_PORT"
echo "Frontend: $FRONTEND_HOST:$FRONTEND_PORT"
echo "Backend: $BACKEND_HOST:$BACKEND_PORT"

echo ""
read -rp "Proceed with this configuration? [Y/n]: " confirm
confirm=${confirm:-Y}
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Setup cancelled."
  exit 1
fi

# Docker network setup if needed
if [ "$SETUP_TYPE" == "Docker Services" ]; then
  docker network create caddy-net || true
  docker rm -f backend frontend >/dev/null 2>&1 || true
  docker run -d --name backend --network caddy-net -p "${BACKEND_PORT}:${BACKEND_PORT}" your-backend-image
  docker run -d --name frontend --network caddy-net -p "${FRONTEND_PORT}:${FRONTEND_PORT}" your-frontend-image
fi

# Generate, build, and run Caddy
[ "$ENV_TYPE" == "Production" ] && build_custom_caddy
create_caddyfile "$ENV_TYPE"
run_caddy

# Output final message
echo "✅ Setup complete! Access your app at https://${DOMAIN:-localhost}"
