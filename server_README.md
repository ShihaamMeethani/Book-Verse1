# BookVerse Assistant (Python backend)

A self-hosted chatbot backend for BookVerse: FastAPI + Groq (Llama-family
models via an OpenAI-compatible tool-calling API) + Firestore. It answers
questions about books, orders, and the user's cart by calling tools against
your real Firestore data — it never invents prices, stock, or order details.

## Setup

### 1. Install a compatible Python version
Python 3.14 works, but if you're on it, `pydantic` **must** be `>=2.12.0`
(see `requirements.txt`) — earlier pydantic versions have no prebuilt wheel
for 3.14 and pip will try to compile `pydantic-core` from source, which
needs a Rust toolchain + MSVC linker you probably don't have. If you ever
see a `pydantic-core` build error mentioning `maturin`/`cargo`/`link.exe`,
this is why — fix it by loosening the pin, not by installing Rust.

### 2. Install dependencies
```bash
python -m pip install -r requirements.txt
```
Run this with the *same* `python` you'll use to run the server — on
Windows, prefer `python -m pip install ...` over a bare `pip install ...`
to guarantee that.

### 3. Create your `.env`
```bash
cp .env.example .env
```
Edit **`.env`** (not `.env.example` — only `.env` is auto-loaded) and fill in:

- `GROQ_API_KEY` — from console.groq.com → API Keys. Must start with `gsk_`
  exactly once. Treat this like a password: never commit it, and if a key
  is ever pasted somewhere it could leak (a chat log, a public repo, a
  screenshot), revoke it and generate a new one rather than reusing it.
- `FIREBASE_SERVICE_ACCOUNT_PATH` — see next step.
- `FIREBASE_PROJECT_ID` — `mybookstore-7126b`.

### 4. Get a Firebase service account key
Firebase Console → Project settings (gear icon) → Service accounts tab →
**Generate new private key**. This downloads a `.json` file — move it into
this `server/` folder, rename it to `firebase-service-account.json` (or
update `.env` to match whatever you named it), and make sure `.env` points
at it with a path relative to this folder, e.g. `./firebase-service-account.json`.

This file is a real credential with admin access to your Firestore
database. Never commit it, never share it, and add it to `.gitignore`.

### 5. Deploy Firestore composite indexes
The chatbot's `search_books` tool combines filters (genre) with sorts
(rating/price/newest/title), which Firestore requires composite indexes
for. These are already defined in `firestore.indexes.json` at the project
root. Deploy them once:
```bash
npm install -g firebase-tools   # if you don't already have it
firebase login
firebase use mybookstore-7126b
firebase deploy --only firestore:indexes
```
Check Firebase Console → Firestore Database → Indexes afterward — each
should read **Enabled**, not **Building**, before you rely on them. If the
chatbot ever throws `FailedPrecondition: The query requires an index`,
Firestore's error includes a direct link to create that specific missing
one — click it, or add the equivalent entry to `firestore.indexes.json` and
redeploy.

## Run

From **this folder** (`server/` — `python -m uvicorn app.main:app` will
fail with `ModuleNotFoundError: No module named 'app'` from anywhere else):
```bash
python -m uvicorn app.main:app --reload --port 8000
```
You should see `Uvicorn running on http://127.0.0.1:8000`. Confirm it's
actually up by opening `http://localhost:8000/health` in a browser — it
should return `{"status": "ok"}`.

Test the chat endpoint directly:
```bash
curl -X POST http://localhost:8000/chat \
  -H "Authorization: Bearer <a-real-firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "abc123", "message": "any good fantasy books under $10?", "cart": []}'
```

## Calling it from Flutter

Already wired up: `lib/services/chat_service.dart` calls this backend's
`/chat` endpoint with the user's Firebase ID token and current cart, and
`lib/screens/chat/chat_screen.dart` is the chat UI, opened from the chat
bubble on the main navigation screen (`main_navigation_screen.dart`).

`ChatService`'s default URL is platform-aware, not one fixed address:
- **Flutter Web (Chrome)**: `http://localhost:8000` — the browser runs on
  your own machine, so `localhost` reaches a server on that same machine.
- **Android emulator**: `http://10.0.2.2:8000` — the emulator is its own
  virtual machine; `10.0.2.2` is the special alias Android uses to mean
  "the host machine's localhost." Plain `localhost` from inside the
  emulator means the emulator itself, which has nothing on port 8000.
- **iOS simulator / desktop**: `http://localhost:8000`.
- **A physical phone/tablet** is on none of the above — override
  `ChatService(baseUrl: 'http://<your-LAN-IP>:8000')`, or point it at a
  real deployed HTTPS URL.

On Android specifically, `android/app/src/main/res/xml/network_security_config.xml`
allows plain HTTP only to `10.0.2.2`/`localhost`/`127.0.0.1`, since Android
9+ blocks all cleartext traffic by default. Remove this once you deploy the
backend behind real HTTPS.

## The Groq model

`app/groq_client.py` currently targets `openai/gpt-oss-120b`, a Groq
production model with public pricing and documented tool-calling support.
Groq's model lineup changes: `llama-3.3-70b-versatile` (an earlier choice
here) was moved to Groq's Enterprise tier and now returns
`404 model_not_found` on standard developer accounts. If you ever hit that
error again after a Groq lineup change, check console.groq.com/docs/models
for the current recommended tool-calling model and update `MODEL` there.

## What's simplified here (fine for a first version, revisit before scale)

- **Sessions are in-memory** (`_sessions` dict in `main.py`) and reset on
  restart; won't work across more than one server process/instance. Swap
  for Redis or a Firestore `chat_sessions` collection once you deploy
  behind more than one worker.
- **Conversation history stored is plain text only** — the intermediate
  tool-call/tool-result exchange within a turn isn't persisted across
  turns, only the final user message and final reply.
- **`search_books`'s `query` param is a prefix match on title only**
  (Firestore has no native full-text search). Swap in Algolia or
  Typesense later if users search loosely ("that dragon book").
- **CORS is wide open** (`allow_origins=["*"]` in `main.py`) to make local
  development painless across web/Android/iOS. Restrict this to your real
  app's origin(s) before shipping to production.

## Deploying

Any place that runs a long-lived Python process works: Render, Fly.io,
Cloud Run, a small VPS behind nginx, etc. Point `ChatService`'s `baseUrl`
at wherever you deploy this, and make sure outbound HTTPS to
`api.groq.com` and Firestore is allowed from that host.
