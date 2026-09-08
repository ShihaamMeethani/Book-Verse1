from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

from .auth import verify_user
from .groq_client import chat

app = FastAPI(title="BookVerse Assistant")

# Relaxed for development so Flutter web / other origins can call this
# directly. Tighten to your real app origins before shipping to production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Naive in-memory session store. Swap for Redis/Firestore in production --
# this dict resets whenever the process restarts.
_sessions: dict[str, list[dict]] = {}


class CartItem(BaseModel):
    bookId: str
    title: str
    price: float
    quantity: int


class ChatRequest(BaseModel):
    session_id: str
    message: str
    cart: list[CartItem] = []


class ChatResponse(BaseModel):
    reply: str


@app.post("/chat", response_model=ChatResponse)
def chat_endpoint(req: ChatRequest, uid: str = Depends(verify_user)):
    history = _sessions.get(req.session_id, [])

    reply = chat(
        user_message=req.message,
        verified_uid=uid,
        current_cart=[c.model_dump() for c in req.cart],
        history=history,
    )

    history.append({"role": "user", "content": req.message})
    history.append({"role": "assistant", "content": reply})
    _sessions[req.session_id] = history[-20:]  # keep last 20 messages

    return ChatResponse(reply=reply)


@app.get("/health")
def health():
    return {"status": "ok"}
