import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSwlNgX3ebPoXD_HzmNF65USAQ4gvfavM',
    appId: '1:1070670970946:web:4b8bc08bb8490a7585eddb',
    messagingSenderId: '1070670970946',
    projectId: 'mybookstore-7126b',
    authDomain: 'mybookstore-7126b.firebaseapp.com',
    storageBucket: 'mybookstore-7126b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSwlNgX3ebPoXD_HzmNF65USAQ4gvfavM',
    appId: '1:1070670970946:android:4b8bc08bb8490a7585eddb',
    messagingSenderId: '1070670970946',
    projectId: 'mybookstore-7126b',
    storageBucket: 'mybookstore-7126b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSwlNgX3ebPoXD_HzmNF65USAQ4gvfavM',
    appId: '1:1070670970946:ios:4b8bc08bb8490a7585eddb',
    messagingSenderId: '1070670970946',
    projectId: 'mybookstore-7126b',
    storageBucket: 'mybookstore-7126b.firebasestorage.app',
    iosBundleId: 'com.example.bookverse',
  );
}

