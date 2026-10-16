import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryMediaAsset {
  const CloudinaryMediaAsset({required this.secureUrl, required this.publicId});

  final String secureUrl;
  final String publicId;
}

/// Téléverse les images publiques des statuts et des profils vers Cloudinary.
///
/// Seul un preset unsigned et limité doit être utilisé dans l'application.
/// L'API Secret Cloudinary ne doit jamais être compilé dans le client mobile.
class CloudinaryMediaService {
  CloudinaryMediaService({String? cloudName, String? uploadPreset})
    : cloudName =
          cloudName ?? const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
      uploadPreset =
          uploadPreset ??
          const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static const maxImageBytes = 10 * 1024 * 1024;

  final String cloudName;
  final String uploadPreset;

  bool get isConfigured =>
      cloudName.trim().isNotEmpty && uploadPreset.trim().isNotEmpty;

  Future<CloudinaryMediaAsset> uploadImage(XFile image) async {
    if (!isConfigured) {
      throw StateError(
        'Cloudinary n’est pas configuré. Ajoutez le cloud name et le preset de téléversement.',
      );
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) throw StateError('Le fichier image est vide.');
    if (bytes.length > maxImageBytes) {
      throw StateError('La photo dépasse la limite locale de 10 Mo.');
    }

    final mimeType = image.mimeType?.toLowerCase();
    if (mimeType != null && !mimeType.startsWith('image/')) {
      throw StateError('Seuls les fichiers image peuvent être téléversés.');
    }

    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${cloudName.trim()}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset.trim()
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: _safeFilename(image.name),
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw StateError('Cloudinary a renvoyé une réponse illisible.');
    } on TypeError {
      throw StateError('Cloudinary a renvoyé une réponse inattendue.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final message = error is Map ? error['message'] as String? : null;
      throw StateError(message ?? 'Le téléversement Cloudinary a échoué.');
    }

    final secureUrl = payload['secure_url'] as String?;
    final publicId = payload['public_id'] as String?;
    final parsedUrl = secureUrl == null ? null : Uri.tryParse(secureUrl);
    if (secureUrl == null ||
        parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        parsedUrl.host != 'res.cloudinary.com' ||
        publicId == null ||
        publicId.isEmpty) {
      throw StateError(
        'Cloudinary a renvoyé des informations d’image invalides.',
      );
    }
    return CloudinaryMediaAsset(secureUrl: secureUrl, publicId: publicId);
  }

  String _safeFilename(String source) {
    final safeName = source.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (safeName.isNotEmpty) return safeName;
    return 'ongea-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
