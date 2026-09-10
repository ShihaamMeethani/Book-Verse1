// ============================================================
// BookVerse - Application Entry Point
// ============================================================
// This file is the starting point of the Flutter application.
// It initializes Firebase and notifications, registers the
// application's Providers, applies the selected theme, and then
// opens the SplashScreen.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/book_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

// main() is the first function executed when the Flutter application starts.
Future<void> main() async {
  // Required before using platform services from an asynchronous main().
  WidgetsFlutterBinding.ensureInitialized();

  // Connect the Flutter application to the Firebase project.
  // DefaultFirebaseOptions selects the correct configuration for the platform.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Send Flutter framework errors to Firebase Crashlytics.
  // This helps identify fatal errors that occur while the UI is running.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Handle errors that occur outside Flutter's normal framework error handler,
  // such as uncaught asynchronous/platform errors.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize the application's local/push notification service before
  // displaying the first screen.
  await NotificationService().init();

  // Start the Flutter widget tree.
  runApp(const BookVerseApp());
}

// Root widget of the BookVerse application.
class BookVerseApp extends StatelessWidget {
  const BookVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider makes shared application state available to all screens.
    // Each ChangeNotifierProvider creates one provider for a specific feature.
    return MultiProvider(
      providers: [
        // Manages login, registration, logout and the current user profile.
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Manages books currently added to the shopping cart.
        ChangeNotifierProvider(create: (_) => CartProvider()),

        // Manages the signed-in user's wishlist/favourite books.
        ChangeNotifierProvider(create: (_) => WishlistProvider()),

        // Loads and manages book/catalogue data used by the application.
        ChangeNotifierProvider(create: (_) => BookProvider()),

        // Stores and exposes the user's light/dark theme preference.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],

      // _AppRoot consumes the authentication and theme providers and then
      // creates the actual MaterialApp used by the application.
      child: const _AppRoot(),
    );
  }
}

/// Connects the authentication state with the wishlist state.
///
/// When the logged-in user's UID changes, the wishlist provider is told which
/// user it should synchronize with. This prevents one user's wishlist from
/// being displayed for another user after login/logout.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    // Consumer2 rebuilds this part of the widget tree whenever either
    // AuthProvider or ThemeProvider notifies its listeners.
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, themeProvider, _) {
        // Wait until the current build is complete before changing the
        // wishlist provider. This avoids modifying provider state while the
        // widget tree itself is being built.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<WishlistProvider>().attachUser(auth.profile?.uid);
        });

        // MaterialApp provides the main Flutter application configuration:
        // application title, themes, navigation and the first screen.
        return MaterialApp(
          title: 'BookVerse',
          debugShowCheckedModeBanner: false,

          // Define both themes. ThemeProvider decides which one is active.
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,

          // Notifications can use this navigator key to open or navigate to
          // a screen even when navigation is triggered outside the UI tree.
          navigatorKey: NotificationService().navigatorKey,

          // The splash screen is the first visible screen. It can then decide
          // where the user should go based on onboarding/authentication state.
          home: const SplashScreen(),
        );
      },
    );
  }
}
