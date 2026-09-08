import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Handles Firebase Authentication and the user's Firestore profile.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Native Google Sign-In is used on Android/iOS.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.updateDisplayName(name);

    final appUser = AppUser(
      uid: cred.user!.uid,
      name: name,
      email: email,
      isAdmin: AppConstants.isAdminEmail(email),
      createdAt: DateTime.now(),
    );

    // Creating the Firebase account is the important part. If Firestore is
    // temporarily unavailable, the account itself is still valid.
    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(cred.user!.uid)
          .set(appUser.toMap(), SetOptions(merge: true));
    } catch (_) {}

    return appUser;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with Google.
  ///
  /// Web uses Firebase's Google popup, while Android/iOS use the native
  /// Google account picker. The native flow requires the Android/iOS app to
  /// be configured correctly in Firebase Console.
  Future<UserCredential?> signInWithGoogle() async {
    late UserCredential userCred;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');

      userCred = await _auth.signInWithPopup(provider);
    } else {
      // Opening signIn() again while another Google sign-in is active can
      // cause confusing errors, so make sure any old session is cleared.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();

      // The user closed the account picker.
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      // Firebase needs Google's OAuth tokens to create its credential.
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'google-token-missing',
          message: 'Google Sign-In did not return an authentication token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCred = await _auth.signInWithCredential(credential);
    }

    // Create the BookVerse profile the first time this Google account signs in.
    final user = userCred.user!;
    final docRef = _db.collection(AppConstants.usersCollection).doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final email = user.email ?? '';
      final appUser = AppUser(
        uid: user.uid,
        name: user.displayName ?? 'Reader',
        email: email,
        photoUrl: user.photoURL,
        isAdmin: AppConstants.isAdminEmail(email),
        createdAt: DateTime.now(),
      );

      try {
        await docRef.set(appUser.toMap(), SetOptions(merge: true));
      } catch (_) {
        // Firebase Authentication already succeeded, so don't turn a
        // temporary Firestore problem into a failed Google login.
      }
    }

    return userCred;
  }

  /// Sends Firebase's built-in password reset email.
  /// No paid email service is required.
  Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter your email address.',
      );
    }

    // Let Firebase validate the address and send its standard
    // password-reset email. The reset page is handled by Firebase.
    try {
      await _auth.setLanguageCode('en');
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } on FirebaseAuthException {
      // Keep the original Firebase error so AuthProvider can show
      // the correct message instead of replacing it with a generic one.
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    await _auth.signOut();
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, uid);
  }

  Stream<AppUser?> profileStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.data()!, uid) : null);
  }

  Future<void> setProfile(String uid, Map<String, dynamic> data) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  // Admin access is controlled by the configured admin email list and
  // Firestore rules. A normal user cannot promote themselves from the app.
  Future<void> grantAdminAccess(String uid, bool isAdmin) async {
    if (uid.isEmpty) return;
  }
}
