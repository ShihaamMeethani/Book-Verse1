# BookVerse — Cloudinary image setup (free Firebase Spark plan)

BookVerse uses Cloudinary for book-cover images instead of Firebase Storage.
Firebase Authentication and Firestore remain in use.

## Cloudinary values configured in this project

- Cloud name: `kcucuyol`
- Upload preset: `bookverse_upload`
- Preset type: **Unsigned**

These two client-side values are not secrets. Never put a Cloudinary API secret in Flutter.

## If you ever recreate the preset

Cloudinary Dashboard → Settings → Upload presets → Add upload preset.
Create `bookverse_upload` and set **Signing Mode = Unsigned**.

## Firebase rules

This project does not use Firebase Storage. Do not deploy Storage rules.
From the project folder run:

```powershell
firebase login
firebase deploy --only firestore:rules
```

Or double-click `deploy_firestore_rules.bat`.

## Run the app

```powershell
flutter clean
flutter pub get
flutter run
```
