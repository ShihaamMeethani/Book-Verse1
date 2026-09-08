# BookVerse Google Sign-In setup (free)

The Flutter code already supports:
- Google Sign-In on Android/iOS through `google_sign_in` + Firebase Authentication.
- Google Sign-In on Chrome/Web through Firebase's Google provider popup.
- Firebase's built-in password reset email.

No paid email provider, SMTP service, Gmail API, Cloud Function, or paid backend is required.

## Android: one Firebase step is still required

The Android app's SHA-1 is tied to the signing key. Firebase must know that SHA-1 before Google's Android OAuth flow can work.

### Easiest Windows method

1. Open the BookVerse project in Android Studio.
2. Open `android/get_google_sha1.bat` by double-clicking it, or run it from CMD.
3. Copy the SHA-1 printed by the script.
4. Open Firebase Console.
5. Open your BookVerse project.
6. Go to **Project settings -> General**.
7. Under **Your apps**, select the Android app whose package name is `com.example.bookverse`.
8. Under **SHA certificate fingerprints**, click **Add fingerprint**.
9. Paste the SHA-1 and save.
10. Download the new `google-services.json` from the same Android app section.
11. Replace the project's `android/app/google-services.json` with the newly downloaded file.

Then run:

```bat
flutter clean
flutter pub get
flutter run
```

### Alternative

From the project root:

```bat
cd android
gradlew signingReport
```

Copy the SHA-1 from the `debug` variant.

## Password reset

The app calls Firebase Authentication's built-in:

```dart
FirebaseAuth.instance.sendPasswordResetEmail(email: email)
```

In Firebase Console, make sure:

**Authentication -> Sign-in method -> Email/Password -> Enabled**

The email is sent by Firebase. You do not need to configure Gmail SMTP or pay for an email service.

If the reset message is not in Gmail, check Spam/Junk and Promotions, then check the Firebase Authentication email template.

## Important

The project cannot register the SHA-1 inside your Firebase project from the ZIP itself. That is a Firebase Console setting tied to your Google account. The included script makes the local SHA-1 step easy, and the app will show a clearer error when Android Google Sign-In is not configured.
