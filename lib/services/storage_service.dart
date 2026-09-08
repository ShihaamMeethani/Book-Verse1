import 'dart:typed_data';
import 'cloudinary_service.dart';

/// Backwards-compatible name for older BookVerse screens.
/// It no longer uses Firebase Storage; all image uploads go to Cloudinary.
class StorageService {
  final CloudinaryService _cloudinary = CloudinaryService();

  Future<String> uploadBookCoverBytes(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) => _cloudinary.uploadBookCoverBytes(bytes, mimeType: mimeType);

  Future<String> uploadProfileImageBytes(
    Uint8List bytes,
    String uid, {
    String mimeType = 'image/jpeg',
  }) => _cloudinary.uploadProfileImageBytes(bytes, uid, mimeType: mimeType);

  /// Cloudinary deletion requires a signed server-side API call.
  /// Leaving the old image in Cloudinary is non-fatal for the app.
  Future<void> deleteByUrl(String url) async {}
}
