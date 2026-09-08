/// Public Cloudinary configuration used by the unsigned image-upload API.
///
/// These values are safe to include in a Flutter client. Never put a
/// Cloudinary API secret in the app. The upload preset must be Unsigned.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'kcucuyol';
  static const String uploadPreset = 'bookverse_upload';
  static const String folder = 'bookverse/books';

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}
