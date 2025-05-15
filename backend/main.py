from fastapi import FastAPI, Request, HTTPException, WebSocket, WebSocketDisconnect, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response as FastAPIResponse
import asyncio
from jose import JWTError, jwt
from datetime import datetime, timedelta

SECRET_KEY = "super-secret-key"  # Replace with a secure environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
ALLOWED_ORIGINS = ["http://localhost:5500"]


app = FastAPI()

# CORS setup (frontend on different port)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,  # Frontend origin
    allow_credentials=True,  # This is crucial for cookies
    allow_methods=["GET", "POST", "OPTIONS"],  # Explicitly list allowed methods
    allow_headers=["*"],
    expose_headers=["*"],  # Expose all headers to the browser
    max_age=3600  # Cache preflight requests for 1 hour
)


def create_access_token(data: dict):
    '''
    Create a JWT token for the user
    data: dict - the data to encode in the token
    Returns: str - the JWT token
    '''
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)



@app.get("/api/me")
def get_user(request: Request):
    '''
    Get the user's data
    request: Request - the request object
    Returns: JSONResponse - the user's data
    '''
    print("Cookies received:", request.cookies)
    # Check for the session token in cookies
    session_token = request.cookies.get("sessionToken")
    print("Session token:", session_token)
    if not session_token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(session_token, SECRET_KEY, algorithms=[ALGORITHM])
        user_email = payload.get("sub")
        if not user_email:
            raise HTTPException(status_code=401, detail="Invalid session token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid session token")
    
    return {"name": user_email}


@app.get("/api/login")
def login():
    '''
    Login the user
    Returns: FastAPIResponse - the response object
    '''
    access_token = create_access_token({"sub": "user@example.com"})
    response = FastAPIResponse(
        content='{"status":"logged in"}',
        media_type="application/json"
    )
    response.set_cookie(
        key="sessionToken",
        value=access_token,
        httponly=True,
        secure=True,
        samesite="strict",
        path="/",
        max_age=3600
    )
    return response


@app.get("/api/logout")
def logout(response: Response):
    '''
    Logout endpoint - clears session cookie
    '''
    response = FastAPIResponse(content='{"status":"logged out"}', media_type="application/json")
    response.delete_cookie(key="sessionToken", path="/")
    return response


connected_clients = set()

@app.websocket("/ws/notifications")
async def websocket_endpoint(websocket: WebSocket):
    '''
    Handle the websocket connection
    websocket: WebSocket - the websocket object
    '''
    await websocket.accept()
    connected_clients.add(websocket)
    try:
        while True:
            await websocket.receive_text()  # ignoring incoming messages for now
    except WebSocketDisconnect:
        connected_clients.remove(websocket)


async def broadcast_notifications():
    '''
    Broadcast notifications to all connected clients
    '''
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
    '''
    Start the broadcast notifications task
    '''
    asyncio.create_task(broadcast_notifications())
