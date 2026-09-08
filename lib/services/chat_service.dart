import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';

/// Talks to the BookVerse Assistant backend (see /server in the repo root).
///
/// The dev default below picks the right localhost address per platform:
/// - Flutter Web (Chrome): the browser runs on your machine, so
///   `localhost` reaches a server on that same machine directly.
/// - Android emulator: the emulator is its own virtual machine, so it must
///   use the special alias `10.0.2.2` to reach your host machine's
///   localhost -- plain `localhost` from inside the emulator means the
///   emulator itself, which has nothing listening on port 8000.
/// - iOS simulator / desktop: also share your machine's localhost directly.
///
/// A physical phone/tablet is on none of these -- it needs your machine's
/// LAN IP (e.g. http://192.168.x.x:8000), or a deployed HTTPS URL.
String _defaultBaseUrl() {
  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
  return 'http://localhost:8000';
}

class ChatService {
  final String baseUrl;
  ChatService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  Future<String> sendMessage({
    required String sessionId,
    required String message,
    required List<CartItem> cart,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to use the assistant.');
    }
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'message': message,
        'cart': cart
            .map((c) => {
                  'bookId': c.bookId,
                  'title': c.title,
                  'price': c.price,
                  'quantity': c.quantity,
                })
            .toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Assistant error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['reply'] as String? ?? "Sorry, I didn't catch that.";
  }
}
