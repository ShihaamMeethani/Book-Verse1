"""Verifies the Firebase ID token sent by the Flutter app.

This is what makes 'never leak another user's data' an actual guarantee
instead of a prompt instruction: the AI never sees a user_id typed by the
user, only the one recovered here from a signed token.
"""

from fastapi import HTTPException, Header
from firebase_admin import auth as firebase_auth


def verify_user(authorization: str = Header(...)) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception:
        raise HTTPException(401, "Invalid or expired token")

    return decoded["uid"]
