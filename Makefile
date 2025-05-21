## Assumes that the project is already initialized with a virtual environment
## python -m venv venv
## source venv/bin/activate

wscat-install:
	sudo apt install wscat

wscat-test-backend-host:
	wscat -c wss://localhost:8443/ws/notifications --no-check 

wscat-test-backend-container:
	wscat -c wss://localhost:8433/ws/notifications --no-check 

init:
	cd backend && python -m venv venv && source venv/bin/activate

install:
	cd backend && pip install -r requirements.txt

freeze:
	cd backend && pip freeze > requirements.txt

uninstall:
	cd backend && pip uninstall -r requirements.txt

run-backend:
	uvicorn backend.main:app --reload --port=8000

run-frontend:
	cd frontend && python proxy_server.py

caddy-install:
	sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
	sudo apt update
	sudo apt install caddy
	sudo mkdir -p /var/log/caddy

caddy-run:
	# sudo mkdir -p /var/log/caddy
	# sudo chown -R ${USER}:${USER} /var/log/caddy
	caddy run --config Caddyfile
	echo "Caddy is running on https://localhost:8443/"
	echo "You can access the backend at http://localhost:8000"
	echo "You can access the frontend at http://localhost:5500"
	echo "Make sure that your firewall allows the ports 8443 for https access"

caddy-format:
	caddy fmt --overwrite Caddyfile


caddy-listening:
	# sudo lsof -i :8443 -sTCP:LISTEN
	sudo lsof -i -P -n | grep LISTEN

caddy-cat-caddyfile:
	docker exec caddy-proxy cat /etc/caddy/Caddyfile

debug-what-certificates-are-being-sent:
	  openssl s_client -connect localhost:8443 -CAfile ~/.local/share/caddy/pki/authorities/local/root.crt -showcerts




