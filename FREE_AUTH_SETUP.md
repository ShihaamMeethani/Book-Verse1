# BookVerse - Free Google Sign-In + Password Reset

This project uses Firebase Authentication only for sign-in and password reset. No paid email provider, SMTP service, Gmail API, or Cloud Function is required.

## Google Sign-In

### Android

The Android app needs its signing certificate SHA-1 registered in Firebase. This is a Firebase Console setting and cannot be embedded into the ZIP.

On Windows, run:

```bat
android\get_google_sha1.bat
```

Then:

1. Firebase Console -> Project settings -> General.
2. Select the Android app with package name `com.example.bookverse`.
3. Add the printed SHA-1 under **SHA certificate fingerprints**.
4. Download the new `google-services.json`.
5. Replace `android/app/google-services.json`.
6. Run `flutter clean`, `flutter pub get`, and `flutter run`.

Also enable **Authentication -> Sign-in method -> Google**.

### Chrome/Web

Enable **Google** under Firebase Authentication. The app uses Firebase's built-in Google popup on web.

## Forgot Password

Enable **Authentication -> Sign-in method -> Email/Password**.

The app uses Firebase's built-in `sendPasswordResetEmail()`. No Gmail SMTP, Gmail API, paid email service, or paid backend is used.

If a message is not visible in Gmail, check Spam/Junk and Promotions and verify the email template in Firebase Authentication -> Templates.
