import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? profile;
  String? errorMessage;
  bool isLoading = false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  /// Admin access is controlled by the configured administrator email list.
  /// A normal user cannot enable admin access from their profile or by changing
  /// their Firestore profile document.
  bool get isAdmin {
    final email = (_authService.currentUser?.email ?? profile?.email ?? '').trim().toLowerCase();
    return AppConstants.isAdminEmail(email);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      status = AuthStatus.unauthenticated;
      profile = null;
    } else {
      try {
        final fetched = await _authService.fetchProfile(user.uid);
        if (fetched != null) {
          profile = fetched;
        } else {
          final bool isAdminUser = AppConstants.isAdminEmail(user.email);
          final appUser = AppUser(
            uid: user.uid,
            name: user.displayName ?? (user.email?.split('@').first ?? 'Reader'),
            email: user.email ?? '',
            photoUrl: user.photoURL,
            isAdmin: isAdminUser,
            createdAt: DateTime.now(),
          );
          await _authService.setProfile(user.uid, appUser.toMap()).catchError((_) {});
          profile = appUser;
        }
      } catch (_) {
        profile = AppUser(
          uid: user.uid,
          name: user.displayName ?? (user.email?.split('@').first ?? 'Reader'),
          email: user.email ?? '',
          photoUrl: user.photoURL,
          isAdmin: AppConstants.isAdminEmail(user.email),
          createdAt: DateTime.now(),
        );
      }
      status = AuthStatus.authenticated;
      _syncFcmToken(user.uid);
    }
    notifyListeners();
  }

  Future<void> _syncFcmToken(String uid) async {
    try {
      final token = await _notificationService.getToken();
      if (token != null) {
        await _authService.updateProfile(uid, {'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<bool> grantAdminAccess([bool admin = true]) async {
    // Admin access must never be granted by a client-side button.
    // Keep this method only for compatibility with older admin screens.
    final uid = profile?.uid ?? _authService.currentUser?.uid;
    if (uid == null) return false;

    // Only an account already recognised as an admin can pass this check.
    return isAdmin;
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _authService.registerWithEmail(name: name, email: email, password: password);
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyError(e);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = _friendlyError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final cred = await _authService.signInWithEmail(email: email, password: password);
      final uid = cred.user?.uid;
      if (uid != null) {
        try {
          var fetched = await _authService.fetchProfile(uid);
          if (fetched == null) {
            final name = cred.user?.displayName ?? email.split('@').first;
            final bool isAdminUser = AppConstants.isAdminEmail(email);
            fetched = AppUser(
              uid: uid,
              name: name,
              email: email,
              photoUrl: cred.user?.photoURL,
              isAdmin: isAdminUser,
              createdAt: DateTime.now(),
            );
            await _authService.setProfile(uid, fetched.toMap()).catchError((_) async {});
          }
          profile = fetched;
        } catch (_) {
          profile = AppUser(
            uid: uid,
            name: cred.user?.displayName ?? email.split('@').first,
            email: email,
            photoUrl: cred.user?.photoURL,
            isAdmin: AppConstants.isAdminEmail(email),
            createdAt: DateTime.now(),
          );
        }
        status = AuthStatus.authenticated;
      }
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyError(e);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = _friendlyError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final cred = await _authService.signInWithGoogle();
      final uid = cred?.user?.uid;
      if (uid != null) {
        try {
          final fetched = await _authService.fetchProfile(uid);
          if (fetched != null) {
            profile = fetched;
          } else {
            profile = AppUser(
              uid: uid,
              name: cred?.user?.displayName ?? 'Reader',
              email: cred?.user?.email ?? '',
              photoUrl: cred?.user?.photoURL,
              isAdmin: AppConstants.isAdminEmail(cred?.user?.email),
              createdAt: DateTime.now(),
            );
            await _authService.setProfile(uid, profile!.toMap()).catchError((_) async {});
          }
        } catch (_) {
          profile = AppUser(
            uid: uid,
            name: cred?.user?.displayName ?? 'Reader',
            email: cred?.user?.email ?? '',
            photoUrl: cred?.user?.photoURL,
            isAdmin: AppConstants.isAdminEmail(cred?.user?.email),
            createdAt: DateTime.now(),
          );
        }
        status = AuthStatus.authenticated;
      }
      isLoading = false;
      notifyListeners();
      return cred != null;
    } catch (e) {
      errorMessage = _friendlyError(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (_authService.currentUser == null) return;
    try {
      final p = await _authService.fetchProfile(_authService.currentUser!.uid);
      if (p != null) profile = p;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await _authService.signOut();
    // Don't wait for the authStateChanges stream to come back around —
    // clear local state immediately so the UI (e.g. a "Log Out" button
    // that was showing a spinner) updates right away rather than
    // appearing stuck.
    profile = null;
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      final code = error.code.toLowerCase();
      if (code.contains('user-not-found')) return 'No account found with that email.';
      if (code.contains('wrong-password') || code.contains('invalid-credential')) return 'Incorrect email or password.';
      if (code.contains('email-already-in-use')) return 'An account already exists with that email.';
      if (code.contains('weak-password')) return 'Password should be at least 6 characters.';
      if (code.contains('invalid-email')) return 'Please enter a valid email address.';
      if (code.contains('google-token-missing')) return 'Google Sign-In could not get an authentication token. Check your Firebase Google setup.';
      if (code.contains('sign_in_failed')) return 'Google Sign-In failed. Check the Android SHA-1 and Google provider settings in Firebase.';
      if (code.contains('too-many-requests')) return 'Too many attempts. Please wait a moment.';
      if (code.contains('network-request-failed')) return 'Network error. Check your internet connection.';
      if (code.contains('operation-not-allowed')) return 'This sign-in method is not enabled in Firebase Console.';
      if (code.contains('account-exists-with-different-credential')) return 'This email is already registered with another sign-in method.';
      if (code.contains('popup-closed-by-user')) return 'Google sign-in was cancelled.';
      if (code.contains('network-request-failed')) return 'Network error. Check your internet connection and try again.';
      if (code.contains('user-disabled')) return 'This user account has been disabled.';
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    final str = error.toString();
    final lower = str.toLowerCase();
    if (lower.contains('permission-denied') || lower.contains('permission_denied')) {
      return 'Permission denied: Please check Firebase Firestore security rules.';
    }
    if (lower.contains('network-request-failed') || lower.contains('unavailable')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lower.contains('user-not-found')) return 'No account found with that email.';
    if (lower.contains('wrong-password') || lower.contains('invalid-credential')) return 'Incorrect email or password.';
    if (lower.contains('email-already-in-use')) return 'An account already exists with that email.';
    if (lower.contains('weak-password')) return 'Password should be at least 6 characters.';
    if (lower.contains('invalid-email')) return 'Please enter a valid email address.';
    if (lower.contains('too-many-requests')) return 'Too many attempts. Please wait a moment.';
    if (lower.contains('operation-not-allowed')) return 'This sign-in method is not enabled in Firebase Console.';
    if (lower.contains('developer_error') || lower.contains('developer error') || lower.contains('status code: 10') || lower.contains('code: 10')) {
      return 'Google Sign-In is not configured for this Android app. Add the app SHA-1 in Firebase and download a new google-services.json.';
    }
    if (lower.contains('12501') || lower.contains('canceled')) return 'Google Sign-In was cancelled.';
    if (lower.contains('account-exists-with-different-credential')) return 'This email is already registered with another sign-in method.';
    if (lower.contains('popup-closed-by-user')) return 'Google sign-in was cancelled.';
    if (lower.contains('user-not-found')) return 'No account was found with that email.';

    // Clean up Exception prefixes if present
    final cleaned = str.replaceAll(RegExp(r'^[A-Za-z_]+Exception:\s*'), '').replaceAll(RegExp(r'^Exception:\s*'), '');
    return cleaned.isNotEmpty ? cleaned : 'Something went wrong. Please try again.';
  }
}
