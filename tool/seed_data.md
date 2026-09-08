# Seeding Sample Data

For a quick demo without building an admin-upload flow first, you can
bulk-import sample books straight into Firestore.

## Option A — Firebase Console
Go to Firestore → Start collection → `books`, and add documents matching
the `Book` model shape in `lib/models/book_model.dart`:

```json
{
  "title": "The Silent Library",
  "author": "Elena Marsh",
  "description": "A haunting mystery set in a forgotten archive...",
  "coverUrl": "https://images.unsplash.com/photo-...",
  "genres": ["Mystery", "Fiction"],
  "price": 18.99,
  "discountPrice": 14.99,
  "avgRating": 0,
  "ratingCount": 0,
  "stock": 40,
  "isBestseller": true,
  "isNewArrival": false,
  "isFeatured": true,
  "releaseDate": "<Firestore Timestamp>",
  "pages": 312,
  "language": "English",
  "isbn": "978-0-000000-0-0",
  "soldCount": 0
}
```

## Option B — Node.js seed script (recommended)
Create a small Node script using `firebase-admin`, authenticate with a
service account key, and loop-write ~20 sample books using free stock
cover art (e.g. from Unsplash) so Home, Search, Bestsellers, and New
Arrivals all have content to display immediately after first run.

## Coupons
Add a `coupons/{CODE}` document, e.g. `coupons/WELCOME10`:
```json
{ "discountPercent": 10, "expiresAt": "<Timestamp, optional>" }
```

## Making yourself an admin
After registering your own account in the app, open Firestore →
`users/{your-uid}` and set `isAdmin: true`. You'll then see the Admin
Dashboard option under Profile.
