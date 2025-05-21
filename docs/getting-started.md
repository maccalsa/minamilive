# 🚀 **Getting Started**

Follow these steps to quickly run and explore the toolkit locally:

## 📌 **1. Clone the Project**

```bash
git clone <your-repo-url>
cd <your-project>
```

## 📌 **2. Setup Backend (Python/FastAPI)**

Navigate into your backend folder:

```bash
cd backend
pip install fastapi uvicorn websockets python-multipart python-jose[cryptography]
```

Run the backend server locally:

```bash
uvicorn main:app --reload --port=8000
```

Your backend API will run at `http://localhost:8000`.

---

## 📌 **3. Setup Frontend (HTML/HTMX/Alpine)**

Ensure a static HTTP server is serving the frontend assets from your `frontend` folder:

```bash
cd frontend
python proxy_server.py
```

Your frontend will run at `http://localhost:5500`.

---

## 📌 **4a. Setup HTTPS/WSS (Caddy)**

**Install Caddy** (e.g., via Homebrew on macOS):

```bash
brew install caddy
```

**Run Caddy** to securely route traffic:

```bash
caddy run
```

Access your secure local app at:

```
https://localhost:8443
```

Accept the local SSL certificate warning (normal for development environments).

---

## 📌 **4a. Setup HTTPS/WSS (Caddy container)**
run the following script

```bash 
cd docker/caddy
./setup-caddy.sh
```

follow the scripts instructions, you will end up with a caddy container which is either directing traffic to containers, or the frontend and backend applications running on the host.

---

## 📌 **5. Verify Everything is Working**

Open `https://localhost:8443` and confirm:

* You see "Welcome, Guest" initially.
* Clicking "log in" authenticates you, displaying a username.
* Preferences (theme toggle) persist via IndexedDB.
* WebSocket messages appear every few seconds.

---

# ✅ **Next Steps**

Congratulations—your minimal real-time application stack is now fully operational!

You're now ready to:

* [ ] Explore detailed **architecture** documentation.
* [ ] Understand the **API Reference** clearly.
* [ ] Customize your application (authentication, state, and UI).
* [ ] Deploy to production environments.

