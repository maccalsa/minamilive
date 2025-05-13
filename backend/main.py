from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

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

connected_clients = []

@app.websocket("/ws/notifications")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            response_html = f"<div hx-swap-oob='true' id='notifications'>Server says: {data}</div>"
            await websocket.send_text(response_html)
    except WebSocketDisconnect:
        connected_clients.remove(websocket)
