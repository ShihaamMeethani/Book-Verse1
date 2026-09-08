# BookVerse Assistant (Python backend)

A self-hosted alternative to the n8n workflow — same system prompt, same
tools, same Firestore fields, just plain FastAPI + the Groq SDK (Llama 3.3 70B, OpenAI-compatible tool calling).

## Setup

```bash
pip install -r requirements.txt
cp .env.example .env   # fill in your real values
```

You need:
- A Groq API key (console.groq.com -> API Keys).
- A Firebase service account JSON (Firebase Console → Project settings →
  Service accounts → Generate new private key) — place it wherever
  `FIREBASE_SERVICE_ACCOUNT_PATH` points.

## Run

```bash
uvicorn app.main:app --reload --port 8000
```

Test it:

```bash
curl -X POST http://localhost:8000/chat \
  -H "Authorization: Bearer <firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "abc123", "message": "any good fantasy books under $10?", "cart": []}'
```

## Calling it from Flutter

Already wired up: `lib/services/chat_service.dart` calls this backend's
`/chat` endpoint with the user's Firebase ID token and current cart, and
`lib/screens/chat/chat_screen.dart` is the chat UI, opened from the chat
bubble on the main navigation screen. The only thing you need to change is
`ChatService`'s default `baseUrl` once you deploy this backend somewhere
other than `http://10.0.2.2:8000` (the Android-emulator alias for your
dev machine's localhost).

## What's simplified here (fine for a first version, revisit before scale)

- **Sessions are in-memory** (`_sessions` dict in `main.py`) and reset on
  restart, and won't work if you run more than one server process/instance.
  Swap for Redis or a Firestore `chat_sessions` collection once you deploy
  behind more than one worker.
- **Conversation history stored is plain text only** — the intermediate
  tool-call/tool-result exchange within a turn isn't persisted across
  turns, only the final user message and final reply. This keeps things
  simple and is enough for natural follow-ups, but means the model can't
  "recall" the raw tool output from three turns ago, only what it already
  summarized into text.
- **`search_books`'s `query` param is a prefix match on title only**
  (Firestore has no native full-text search). Good enough to start; swap
  in Algolia or Typesense later if users search loosely ("that dragon book").

## Deploying

Any place that runs a long-lived Python process works: Render, Fly.io,
Cloud Run, a small VPS behind nginx, etc. Point your Flutter app's
`baseUrl` at wherever you deploy this, and make sure outbound HTTPS to
`api.groq.com` and Firestore is allowed.
