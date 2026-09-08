import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../utils/cloudinary_config.dart';

/// Uploads images directly to Cloudinary using an unsigned upload preset.
/// Firebase Storage is intentionally not used.
class CloudinaryService {
  final _uuid = const Uuid();

  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String folder = CloudinaryConfig.folder,
    String mimeType = 'image/jpeg',
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary is not configured.');
    }
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint);
    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    if (folder.isNotEmpty) request.fields['folder'] = folder;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'bookverse_${_uuid.v4()}.jpg',
      ),
    );

    final response = await request.send().timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException(
        'Cloudinary upload timed out. Check your internet connection.',
      ),
    );
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var details = body;
      try {
        final decoded = jsonDecode(body);
        details = decoded['error']?['message']?.toString() ?? body;
      } catch (_) {}
      throw Exception('Cloudinary upload failed (${response.statusCode}): $details');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final url = decoded['secure_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }
    return url;
  }

  Future<String> uploadBookCoverBytes(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) {
    return uploadImageBytes(bytes, folder: CloudinaryConfig.folder, mimeType: mimeType);
  }

  Future<String> uploadProfileImageBytes(
    Uint8List bytes,
    String uid, {
    String mimeType = 'image/jpeg',
  }) {
    return uploadImageBytes(bytes, folder: 'bookverse/profiles/$uid', mimeType: mimeType);
  }
}
