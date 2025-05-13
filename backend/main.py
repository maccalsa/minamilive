from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import asyncio
from fastapi import WebSocketDisconnect, WebSocket

app = FastAPI()

# CORS setup (frontend on different port)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5500"],  # Adjust port if needed
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/me")
def get_user():
    return {"name": "John Doe"}

@app.get("/api/login")
def login(response: Response):
    response.set_cookie(key="sessionToken", value="secure-session-token", httponly=True, secure=False)
    return JSONResponse(content={"status": "logged in"})

connected_clients = set()


@app.websocket("/ws/notifications")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.add(websocket)
    try:
        while True:
            await websocket.receive_text()  # ignoring incoming messages for now
    except WebSocketDisconnect:
        connected_clients.remove(websocket)

async def broadcast_notifications():
    counter = 1
    while True:
        message = f"<div hx-swap-oob='true' id='notifications'>Server broadcast #{counter}</div>"
        disconnected = set()
        for client in connected_clients:
            try:
                await client.send_text(message)
            except WebSocketDisconnect:
                disconnected.add(client)
        for client in disconnected:
            connected_clients.remove(client)
        counter += 1
        await asyncio.sleep(5)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(broadcast_notifications())
