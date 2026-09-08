# 📚 BookVerse — Premium Online Bookstore App

A complete, production-styled Flutter + Firebase bookstore application,
built around the eProject "Book Store App" specification and extended
with features expected of a genuinely competitive, real-world product.

---

## ✨ What's in this build

### From the original specification
- Email/password **and** Google sign-in, secure logout, password reset
- Full book catalog with covers, genres, authors, descriptions, prices
- Bestsellers & New Arrivals sections
- Search by title/author/genre, with sort by price / popularity / release date
- User profiles with editable info, **multiple shipping addresses**, and **saved payment methods**
- Shopping cart with quantity controls and live totals
- Ratings & reviews, with **like** support on reviews
- Order history, order status, and **delivery tracking**
- Admin panel: manage books (add/edit/delete) and manage orders/users
- Wishlist

### Added on top (not in the original doc, but expected of a serious app)
| Feature | Why it matters |
|---|---|
| 🌓 Dark mode | Table-stakes UX, persisted across sessions |
| 🎉 Confetti + success animations at checkout | Delight moment that most student projects skip |
| 🔔 Push notifications (FCM) + local notifications | Order updates, "added to cart" confirmations |
| 🎯 Content-based recommendations ("You might also like") | Shows engineering depth beyond CRUD |
| 🏷️ Coupon / discount code system | Real e-commerce requirement |
| 📦 Animated order-tracking timeline | Visually communicates delivery progress |
| 🏆 Loyalty points on the profile | Retention mechanic |
| 📖 "Read a free sample" link per book | Realistic bookstore feature |
| 📤 Social share for a book | Organic growth mechanic |
| 📊 Admin analytics dashboard with revenue chart | Turns "admin panel" into a real back-office tool |
| 💀 Skeleton/shimmer loading states | Perceived performance |
| 🪄 Hero transitions, staggered list animations, animated wishlist heart | Polish |
| 🧾 Firestore security rules + Storage rules included | Shows you understand production security, not just a demo |
| 📱 Slidable "swipe to remove" cart items | Modern mobile interaction pattern |

---

## 🏗️ Architecture

```
lib/
├── main.dart                  # App entry, Firebase init, MultiProvider
├── firebase_options.dart      # Placeholder — regenerate with flutterfire configure
├── models/                    # Plain Dart data classes (Book, AppUser, BookOrder, Review, CartItem)
├── services/                  # Firebase-facing logic (Auth, Firestore, Storage, Notifications)
├── providers/                 # ChangeNotifier state (Auth, Cart, Wishlist, Books, Theme)
├── theme/                     # Centralized colors + ThemeData (light/dark)
├── utils/                     # Constants, enums
├── widgets/                   # Reusable UI: buttons, text fields, rating stars, shimmer, empty states
└── screens/
    ├── splash/ onboarding/ auth/       # First-run & auth flow
    ├── home/ search/ book_details/     # Discovery
    ├── cart/ checkout/                 # Purchase flow
    ├── orders/ wishlist/ profile/      # Post-purchase & account
    ├── admin/                          # Book & order management, analytics
    ├── chat/                           # BookVerse Assistant chat UI
    └── main_nav/                       # Bottom-tab shell

server/                          # BookVerse Assistant backend (FastAPI + Claude), see below
```

**Why this structure:** services never import UI code, providers never
talk to Firestore directly (they call services), and screens only read
from providers — a clean, testable separation that scales well as the
catalog and feature set grow.

---

## 🔧 Setup

> This project's code is complete and ready to run, but **you must
> connect it to your own Firebase project** before it will build —
> Flutter/Firebase credentials can't be pre-baked into a shared template.

### 1. Prerequisites
- Flutter SDK ≥ 3.3 (`flutter --version`)
- A Firebase project ([console.firebase.google.com](https://console.firebase.google.com))
- The FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 2. Install dependencies
```bash
cd bookverse
flutter pub get
```

### 3. Connect Firebase
```bash
flutterfire configure
```
This walks you through selecting/creating a Firebase project and
platforms (Android/iOS/Web), and **overwrites `lib/firebase_options.dart`**
with your real project credentials.

### 4. Enable Firebase services (in the Firebase console)
- **Authentication** → Sign-in method → enable *Email/Password* and *Google*
- **Firestore Database** → Create database (start in production mode)
- **Storage** → Get started
- **Cloud Messaging** → already enabled by default with the project

### 5. Deploy security rules and indexes
```bash
firebase deploy --only firestore:rules,storage:rules,firestore:indexes
```
(Requires `firebase-tools`: `npm install -g firebase-tools`, then `firebase login` and `firebase use <your-project-id>`.) The composite indexes in `firestore.indexes.json` are required for the chatbot's book-search filters/sorts to work — check Firebase Console → Firestore → Indexes afterward and wait for each to show **Enabled**, not **Building**.

### 6. Seed sample data
See `tool/seed_data.md` for two options (manual console entry or a
Node.js admin-SDK script) to populate the `books` collection so Home,
Search, Bestsellers, and New Arrivals aren't empty on first run.

### 7. Make yourself an admin
Register a user in-app, then in Firestore set
`users/{your-uid}.isAdmin = true` to unlock the Admin Dashboard.

### 8. Run
```bash
flutter run
```

### 9. Run the chatbot backend (optional, for the assistant chat bubble)
The Flutter app runs fine without this — you'll just get a connection
error if you open the chat bubble. See `server/README.md` for full setup
(Python, Groq API key, Firebase service account key, running `uvicorn`).

---

## 🔐 Security model (summary)
- Book catalog: publicly readable, writable only by admins
- Orders: a user can create/read/update only their own (e.g. self-service
  cancel); admins can read/update/delete any order. *(Fixed: the rules file
  previously let any signed-in user read or update **any** order — the rule
  now checks `resource.data.userId` against the caller, matching what this
  README always said it did.)*
- Reviews: anyone signed in can post; only the author can edit their own
  review; the "like" button is allowed to touch just the `likedBy` field
- Wishlist & profile: private per-user subcollections/documents. *(Fixed: the
  app writes wishlist items to a subcollection named `wishlists`, but only a
  subcollection named `wishlist` was protected — real wishlist data was
  falling through to the public catch-all rule. Both names are now
  protected; rename `AppConstants.wishlistCollection` to `'wishlist'` when
  convenient to remove the duplication.)*
- Storage uploads are size- and content-type-restricted

Full rules are in `firestore.rules` and `storage.rules` at the project root.

## 🤖 BookVerse Assistant (chatbot)

A support chatbot lives in `server/` (Python/FastAPI, calls Groq's
OpenAI-compatible tool-calling API) and is wired into the app via
`lib/services/chat_service.dart` and `lib/screens/chat/chat_screen.dart`,
opened from the chat bubble on the main navigation screen. It answers
questions about books, orders, and the user's current cart using tool
calls against this same Firestore database — it never invents prices,
stock, or order details, and it can only ever see the current user's own
orders (enforced by verifying their Firebase ID token server-side, not by
trusting anything the client sends). See `server/README.md` for full
setup, deployment, and troubleshooting notes — it documents several
real gotchas hit while building this (Python 3.14 packaging, required
Firestore composite indexes, Android's cleartext-HTTP block, and Groq
model lineup changes) so you don't have to rediscover them.

---

## 🚀 Suggested next steps for production
- Swap client-side search for **Algolia** or a Firestore full-text
  extension once the catalog exceeds a few hundred titles
- Move payment handling to **Stripe** (via Cloud Functions) instead of
  the client-only saved payment methods in this build — real card data
  should always be tokenized by a PCI-compliant processor and never
  touch Firestore directly, even in metadata form
- Add Cloud Functions to send FCM pushes server-side on order-status
  change (the client currently only fires *local* notifications)
- Add Crashlytics + Analytics event tracking (dependencies are already
  included in `pubspec.yaml`, just need `.then()` calls added at key events)
- Add integration tests (`integration_test/`) for the checkout flow
- Add pagination to `streamAllBooks()` once the catalog is large
  (currently loads the full collection, fine for a catalog of hundreds)

---

## 📄 Documentation deliverables (per the eProject brief)
- **User documentation**: onboarding screens + empty-state guidance are
  built directly into the app; extend with a FAQ screen backed by a
  `faqs` Firestore collection if a formal user guide is required.
- **Developer documentation**: this README + inline doc-comments on
  every service/provider class explaining *why*, not just *what*.
- **Video walkthrough**: not included here (this is a code deliverable) —
  record a screen capture of the flows once you've connected your own
  Firebase project and seeded data.

---

## 📦 Full dependency list
See `pubspec.yaml`. Highlights: `firebase_core/auth/firestore/storage/messaging/analytics/crashlytics`,
`provider`, `animate_do`, `lottie`, `shimmer`, `confetti`, `fl_chart`,
`cached_network_image`, `hive`, `flutter_local_notifications`, `flutter_slidable`.

## Latest UI + Cloudinary update

BookVerse now uses the **Midnight Burgundy** visual system: black/espresso surfaces, deep burgundy brand accents and restrained antique gold. The customer home page has a premium editorial storefront layout with featured stories, curated shelves, refined cards and responsive book-cover rendering.

Book covers are uploaded directly to Cloudinary using the unsigned preset in `lib/utils/cloudinary_config.dart`. Firebase Storage is not required.

The customer-facing cover renderer uses `Image.network` with a visible fallback and diagnostics, which is more reliable for Cloudinary URLs across Flutter Web, Android and iOS than the previous cache-manager widget.
