"""Firestore-backed tool implementations.

Collection and field names below are copied directly from the BookVerse
Flutter project (lib/utils/constants.dart and lib/models/*.dart) so they
match what's actually in the database.
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore

_SERVICE_ACCOUNT_PATH = os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"]

if not firebase_admin._apps:
    cred = credentials.Certificate(_SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

BOOKS = "books"
ORDERS = "orders"


def search_books(query: str = "", genre: str = "", max_price: float | None = None,
                  free_only: bool = False, sort_by: str = "", limit: int = 5) -> list[dict]:
    """Search the books collection. Firestore doesn't do full-text search
    natively, so `query` is matched as a case-sensitive prefix on title;
    for real free-text search, swap this for Algolia/Typesense later."""
    ref = db.collection(BOOKS)

    if genre:
        ref = ref.where("genres", "array_contains", genre)
    if max_price is not None:
        ref = ref.where("price", "<=", max_price)
    if free_only:
        ref = ref.where("price", "==", 0)

    if query:
        ref = ref.order_by("title").start_at([query]).end_at([query + "\uf8ff"])
    elif sort_by == "price_low":
        ref = ref.order_by("price")
    elif sort_by == "price_high":
        ref = ref.order_by("price", direction=firestore.Query.DESCENDING)
    elif sort_by == "rating":
        ref = ref.order_by("avgRating", direction=firestore.Query.DESCENDING)
    elif sort_by == "newest":
        ref = ref.order_by("releaseDate", direction=firestore.Query.DESCENDING)

    docs = ref.limit(limit).stream()
    return [_book_summary(d.id, d.to_dict()) for d in docs]


def get_book_details(book_id: str = "", title: str = "") -> dict:
    if book_id:
        doc = db.collection(BOOKS).document(book_id).get()
        if not doc.exists:
            return {"error": "not_found"}
        return _book_summary(doc.id, doc.to_dict())

    if title:
        docs = list(db.collection(BOOKS).where("title", "==", title).limit(1).stream())
        if not docs:
            return {"error": "not_found"}
        return _book_summary(docs[0].id, docs[0].to_dict())

    return {"error": "missing_book_id_or_title"}


def get_user_orders(user_id: str, order_id: str = "") -> list[dict]:
    """`user_id` MUST be the server-verified uid, never a value taken from
    user-typed text -- see auth.py. This is what actually enforces
    'never show another user's orders'."""
    ref = db.collection(ORDERS).where("userId", "==", user_id)
    if order_id:
        ref = ref.where("__name__", "==", order_id)

    docs = ref.order_by("createdAt", direction=firestore.Query.DESCENDING).limit(10).stream()
    return [_order_summary(d.id, d.to_dict()) for d in docs]


_FAQ = {
    "track_order": "Profile -> Order History -> select order -> live tracking timeline "
                   "(Placed -> Confirmed -> Packed -> Shipped -> Out for Delivery -> Delivered).",
    "cancel_order": "Cancel is available on Order Details while status is 'Placed' or 'Confirmed'.",
    "add_address": "Profile -> Shipping Addresses (or Edit Profile). Multiple addresses supported.",
    "google_signin": "Google Sign-In is available on both the Login and Register screens.",
    "forgot_password": "Tap 'Forgot Password?' on the Sign In screen, enter your registered "
                        "email, and a reset link is sent.",
    "payment_methods": "Saved credit/debit cards, digital wallets, and cash on delivery (COD).",
    "loyalty_points": "10 points per $1 spent. Tiers: Silver, Gold, Platinum.",
    "reviews": "Leave a 1-5 star rating and written feedback from a book's details page; "
               "reviews can be edited or deleted later.",
    "wishlist": "Tap the heart icon on any book card or details page to save it for later.",
    "checkout_flow": "Open a book -> Add to Cart -> open Cart -> review -> Checkout -> confirm.",
}


def get_app_faq(topic: str) -> str:
    return _FAQ.get(topic, "No FAQ entry for that topic.")


def _book_summary(book_id: str, d: dict) -> dict:
    return {
        "id": book_id,
        "title": d.get("title"),
        "author": d.get("author"),
        "genres": d.get("genres", []),
        "price": d.get("price"),
        "discountPrice": d.get("discountPrice"),
        "avgRating": d.get("avgRating"),
        "stock": d.get("stock", 0),
        "inStock": d.get("stock", 0) > 0,
    }


def _order_summary(order_id: str, d: dict) -> dict:
    return {
        "id": order_id,
        "status": d.get("status"),
        "total": d.get("total"),
        "trackingNumber": d.get("trackingNumber"),
        "itemCount": len(d.get("items", [])),
        "createdAt": str(d.get("createdAt")),
    }
